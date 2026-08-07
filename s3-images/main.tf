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
    key          = "s3-images/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# The bucket that holds book cover images.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "book_images" {
  bucket = "${var.project}-book-images-${data.aws_caller_identity.current.account_id}"
}

# Public READ only — anyone can view an image by URL, nobody can list/write
# without credentials. This is what makes covers directly usable as <img src>.
resource "aws_s3_bucket_public_access_block" "book_images" {
  bucket = aws_s3_bucket.book_images.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.book_images.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.book_images.arn}/*"
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.book_images]
}

# CORS: lets the browser fetch/display images cross-origin from the frontend.
resource "aws_s3_bucket_cors_configuration" "book_images" {
  bucket = aws_s3_bucket.book_images.id
  cors_rule {
    allowed_methods = ["GET", "HEAD"]
    allowed_origins  = ["*"]
    allowed_headers  = ["*"]
    max_age_seconds  = 3000
  }
}

# Keep the bucket tidy in cost/versioning terms — versioning off (covers are
# replaceable, no need to keep old versions and pay for them).
resource "aws_s3_bucket_versioning" "book_images" {
  bucket = aws_s3_bucket.book_images.id
  versioning_configuration {
    status = "Disabled"
  }
}

# ---------------------------------------------------------------------------
# IAM policy that lets book-service UPLOAD (and delete/replace) images.
# Attached to a role book-service's pod assumes (IRSA) so no access keys
# are baked into the app.
# ---------------------------------------------------------------------------
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_role" "book_service_s3" {
  name = "book-service-s3-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:bookstore:book-service"
          "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "book_service_s3" {
  name = "s3-book-images"
  role = aws_iam_role.book_service_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ]
      Resource = "${aws_s3_bucket.book_images.arn}/*"
    }]
  })
}

output "bucket_name" {
  value = aws_s3_bucket.book_images.bucket
}

output "bucket_url" {
  description = "Base URL images are publicly reachable at: <this>/<key>"
  value       = "https://${aws_s3_bucket.book_images.bucket}.s3.${var.region}.amazonaws.com"
}

output "book_service_role_arn" {
  description = "IAM role ARN to annotate the book-service ServiceAccount with."
  value       = aws_iam_role.book_service_s3.arn
}
