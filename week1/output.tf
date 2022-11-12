output "public_ip" {
  value       = aws_instance.webserver.public_ip
  description = "The public IP of the Instance"
}
