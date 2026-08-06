variable "region" {
  description = "AWS region for the VPC."
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Short project slug, used to name resources."
  type        = string
  default     = "bookstore"
}

# A CIDR block is just a range of private IP addresses for your network.
# 10.0.0.0/16 gives you ~65,000 addresses to carve subnets out of.
variable "vpc_cidr" {
  description = "IP address range for the whole VPC."
  type        = string
  default     = "10.0.0.0/16"
}

# Each subnet gets a slice of the VPC range. /24 = ~256 addresses each.
# Private subnets hold your services; public hold the load balancer.
variable "private_subnet_cidrs" {
  description = "IP ranges for the two private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "IP ranges for the two public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}
