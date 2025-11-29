variable "project" {
  description = "Project name"
  default     = "devops-sw-pipelines-assignment-3"
}

variable "terraform_state_bucket" {
  description = "S3 bucket name in AWS for storing Terraform state"
  default     = "devops-sw-pipelines-assignment-3-tf-state"
}

variable "terraform_state_lock_table" {
  description = "Dynamo DB table name for Terraform state locking"
  default     = "devops-sw-pipelines-assignment-3-tf-state"
}

variable "contact" {
  description = "Contact email for created resources (useful if team environment)"
  default     = "L00196611@atu.ie"
}
