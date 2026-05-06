variable "email_address" {
  description = "Email address to verify and send alerts to"
  type        = string
}

variable "state_bucket_arn" {
  description = "ARN of the S3 bucket holding the state file"
  type        = string
}