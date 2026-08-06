variable "region" {
  description = "AWS region for the cluster."
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Short project slug, used to name resources."
  type        = string
  default     = "bookstore"
}

# The Kubernetes version the control plane runs. Kept current as of 2026.
variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.33"
}

# t3.medium = 2 vCPU, 4 GB RAM. Fine for an empty learning cluster.
# We may bump this up in Phase 5 when the memory-hungry Spring Boot services deploy.
variable "node_instance_type" {
  description = "EC2 instance type for the worker nodes."
  type        = string
  default     = "m7i-flex.large"
}
