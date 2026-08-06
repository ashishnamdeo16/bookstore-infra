# -----------------------------------------------------------------------------
# STEP 2 (run AFTER the first `terraform apply` creates the bucket):
#
#   1. Copy the bucket name from the `state_bucket_name` output.
#   2. Paste it into the `bucket` field below and uncomment this whole block.
#   3. Run:  terraform init -migrate-state
#      Terraform will offer to copy your local state into the new bucket. Say yes.
#
# From now on this bootstrap manages its own state remotely, just like every
# other config you'll write. `use_lockfile = true` gives you S3-native locking
# with no DynamoDB table.
# -----------------------------------------------------------------------------

 terraform {
  backend "s3" {
      bucket       = "bookstore-tfstate-016257615899"
      key          = "bootstrap/terraform.tfstate"
      region       = "us-west-2"
      encrypt      = true
      use_lockfile = true
    }
 }
