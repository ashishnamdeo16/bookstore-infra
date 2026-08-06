terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "bookstore-tfstate-016257615899"
    key          = "rds/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

# Read the VPC from Phase 2's remote state.
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "bookstore-tfstate-016257615899"
    key    = "vpc/terraform.tfstate"
    region = "us-west-2"
  }
}

# Look up the VPC to get its CIDR range for the firewall rule.
data "aws_vpc" "this" {
  id = data.terraform_remote_state.vpc.outputs.vpc_id
}

# Tells RDS which subnets it may live in. Private subnets only.
resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-db-subnets"
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
}

# Firewall: allow Postgres (port 5432) only from inside the VPC. Nothing public.
resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "Allow MySQL from inside the VPC only"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "MySQL from within the VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  identifier     = "${var.project}-postgres"
  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "bookstore" # the initial database created with the instance
  username = var.db_username

  # RDS generates the master password and stores it in Secrets Manager.
  # You never see or handle it. This is the modern, recommended approach.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds.id]

  multi_az            = false # single-AZ to save cost; true = prod high-availability
  publicly_accessible = false # private — reachable only from inside the VPC
  skip_final_snapshot = true  # no snapshot on destroy (fine for a learning DB)

  tags = {
    Project   = var.project
    ManagedBy = "terraform"
  }
}
