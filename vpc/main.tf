terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state in the bucket you created in Phase 0.
  backend "s3" {
    bucket       = "bookstore-tfstate-016257615899"
    key          = "vpc/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

# Pick the first two availability zones in the region automatically.
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-vpc"
  cidr = var.vpc_cidr

  # Spread across the first two AZs.
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Two private subnets (services live here) and two public (load balancer).
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  # The one-way exit door for private subnets. single_nat_gateway = true
  # means ONE shared NAT instead of one-per-AZ — much cheaper for learning.
  # For real production high-availability you'd set this to false.
  enable_nat_gateway = true
  single_nat_gateway = true

  # Needed so pods and services can resolve DNS names.
  enable_dns_hostnames = true
  enable_dns_support   = true

  # These tags tell AWS load balancers which subnets to use. EKS reads them
  # in later phases: public subnets host internet-facing load balancers,
  # private subnets host internal ones.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
