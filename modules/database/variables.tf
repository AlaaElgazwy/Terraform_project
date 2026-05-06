variable "vpc_id" {}
variable "private_subnet_ids" { type = list(string) }
variable "app_sg_id" { 
  description = "Security Group ID of the Application EC2 to allow traffic from"
}
variable "environment" {}