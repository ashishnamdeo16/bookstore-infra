variable "region" {
  description = "AWS region for the ECR repositories."
  type        = string
  default     = "us-west-2"
}

variable "service_names" {
  description = "One ECR repository is created per name in this list. Edit to match your services."
  type        = list(string)
  default = [
    "api-gateway",
    "book-service",
    "order-service",
    "notification-service",
    "payment-service",
    "analytics-service",
    "user-service",
    "auth-service",
  ]
}