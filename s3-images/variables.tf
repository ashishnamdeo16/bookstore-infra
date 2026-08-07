variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Short project slug."
  type        = string
  default     = "bookstore"
}

variable "cluster_name" {
  description = "EKS cluster name (for IRSA OIDC lookup)."
  type        = string
  default     = "bookstore-eks"
}
