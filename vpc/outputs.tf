# Later phases (EKS, RDS) need these IDs to know where to place resources.

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (where services and databases run)."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (where the load balancer runs)."
  value       = module.vpc.public_subnets
}
