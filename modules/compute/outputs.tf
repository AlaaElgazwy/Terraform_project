output "app_sg_id" {
  description = "The ID of the Application Security Group"
  value       = aws_security_group.app_sg.id
}