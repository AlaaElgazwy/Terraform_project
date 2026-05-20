output "app_sg_id" {
  description = "The ID of the Application Security Group"
  value       = aws_security_group.app_sg.id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "application_private_ip" {
  value = aws_instance.application.private_ip
}