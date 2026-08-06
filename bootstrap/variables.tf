variable "region" {
  description = "Primary AWS region for state and workloads."
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Short project slug, used to name resources."
  type        = string
  default     = "bookstore"
}

variable "budget_email" {
  description = "Email address that receives billing alerts."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly spend threshold in USD that triggers alerts."
  type        = string
  default     = "50"
}
