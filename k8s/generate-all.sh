#!/usr/bin/env bash
# Regenerates every Kubernetes manifest for the bookstore app from scratch.
#
# Usage, from an empty k8s/ folder:
#   bash generate-all.sh
#   kubectl apply -f kafka.yaml          # deploy Kafka first
#   kubectl apply -f .                   # then all services
#
# Prerequisites already done: 'bookstore' namespace exists, and the
# 'db-credentials' secret exists in it.
set -euo pipefail

REGISTRY="016257615899.dkr.ecr.us-west-2.amazonaws.com"
DB_HOST="bookstore-postgres.cdu60wwkywed.us-west-2.rds.amazonaws.com"
KAFKA="kafka.bookstore.svc.cluster.local:9092"
BOOK_URL="http://book-service:8083"
USER_URL="http://user-service:8082"
JWT="3b796f1d-02e9-4263-a411-ceb6e5532239"

# ---------------------------------------------------------------------------
# Kafka (single broker, KRaft mode)
# ---------------------------------------------------------------------------
cat > kafka.yaml <<'YAML'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
  namespace: bookstore
spec:
  serviceName: kafka
  replicas: 1
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
        - name: kafka
          image: apache/kafka:3.9.1
          ports:
            - containerPort: 9092
            - containerPort: 9093
          env:
            - name: KAFKA_NODE_ID
              value: "1"
            - name: KAFKA_PROCESS_ROLES
              value: "broker,controller"
            - name: KAFKA_CONTROLLER_QUORUM_VOTERS
              value: "1@localhost:9093"
            - name: KAFKA_LISTENERS
              value: "PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093"
            - name: KAFKA_ADVERTISED_LISTENERS
              value: "PLAINTEXT://kafka.bookstore.svc.cluster.local:9092"
            - name: KAFKA_CONTROLLER_LISTENER_NAMES
              value: "CONTROLLER"
            - name: KAFKA_LISTENER_SECURITY_PROTOCOL_MAP
              value: "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT"
            - name: KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR
              value: "1"
            - name: KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR
              value: "1"
            - name: KAFKA_TRANSACTION_STATE_LOG_MIN_ISR
              value: "1"
            - name: KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS
              value: "0"
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: kafka
  namespace: bookstore
spec:
  selector:
    app: kafka
  ports:
    - port: 9092
      targetPort: 9092
  clusterIP: None
YAML
echo "Generated kafka.yaml"

# ---------------------------------------------------------------------------
# Services
# ---------------------------------------------------------------------------
db_env() {
  local db="$1"
  cat <<EOF
            - name: DB_URL
              value: "jdbc:mysql://${DB_HOST}:3306/${db}?serverTimezone=UTC"
            - name: DB_HOST
              value: "${DB_HOST}"
            - name: SPRING_JPA_HIBERNATE_DDL_AUTO
              value: "update"
            - name: JWT_SECRET
              value: "${JWT}"
            - name: DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: DB_USERNAME
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: DB_PASSWORD
EOF
}
feign_env() {
  cat <<EOF
            - name: SPRING_APPLICATION_JSON
              value: '{"services":{"book-service":{"url":"${BOOK_URL}"},"user-service":{"url":"${USER_URL}"}}}'
EOF
}
kafka_env() {
  cat <<EOF
            - name: KAFKA_BOOTSTRAP_SERVERS
              value: "${KAFKA}"
EOF
}

# name : port : db : extras(feign kafka)
SERVICES=(
  "book-service:8083:bookstore_books_db:"
  "user-service:8082:bookstore_user_db:"
  "auth-service:8081:bookstore_auth_db:"
  "notification-service:8085:bookstore_notification_db:kafka"
  "payment-service:8087:bookstore_payment_db:feign"
  "order-service:8084:bookstore_order_db:feign kafka"
  "analytics-service:8088:bookstore_analytics_db:kafka"
)

for entry in "${SERVICES[@]}"; do
  IFS=":" read -r name port db extras <<< "$entry"
  {
    cat <<HEAD
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${name}
  namespace: bookstore
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${name}
  template:
    metadata:
      labels:
        app: ${name}
    spec:
      containers:
        - name: ${name}
          image: ${REGISTRY}/${name}:v2
          ports:
            - containerPort: ${port}
          env:
            - name: SPRING_PROFILES_ACTIVE
              value: "docker"
HEAD
    db_env "$db"
    [[ "$extras" == *feign* ]] && feign_env
    [[ "$extras" == *kafka* ]] && kafka_env
    cat <<TAIL
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: ${name}
  namespace: bookstore
spec:
  selector:
    app: ${name}
  ports:
    - port: ${port}
      targetPort: ${port}
  type: ClusterIP
TAIL
  } > "${name}.yaml"
  echo "Generated ${name}.yaml (extras: ${extras:-none})"
done

echo ""
echo "Done. Next:"
echo "  kubectl apply -f kafka.yaml"
echo "  kubectl apply -f ."
