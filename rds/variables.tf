variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Short project slug, used to name resources."
  type        = string
  default     = "bookstore"
}

# db.t3.micro is free-tier eligible. If your account rejects it, we'll check
# which RDS instance classes your plan allows (same idea as the EC2 restriction).
variable "db_instance_class" {
  description = "RDS instance size."
  type        = string
  default     = "db.t3.micro"
}

variable "engine_version" {
  description = "MySQL major version."
  type        = string
  default     = "8.4"
}

# 20 GB is the free-tier storage allowance.
variable "allocated_storage" {
  description = "Database storage in GB."
  type        = number
  default     = 20
}

variable "db_username" {
  description = "Master username for the database."
  type        = string
  default     = "bookstore_admin"
}
