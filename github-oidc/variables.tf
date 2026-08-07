variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-west-2"
}

variable "github_org" {
  description = "Your GitHub username or org."
  type        = string
  default     = "ashishnamdeo16"
}

variable "github_repo" {
  description = "The repo GitHub Actions runs in (where the code lives)."
  type        = string
  default     = "bookstore"
}
