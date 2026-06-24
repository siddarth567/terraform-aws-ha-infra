output "instance_id" {
  value = aws_instance.bastion.id
}

output "private_ip" {
  value = aws_instance.bastion.private_ip
}

output "public_ip" {
  value = var.assign_eip ? aws_eip.bastion[0].public_ip : aws_instance.bastion.public_ip
}
