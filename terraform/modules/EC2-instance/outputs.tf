#-------------------------------------------------------------
# EC2 Instance Outputs
#-------------------------------------------------------------
output "ami" {
  description = "The AMI ID used for the EC2 instance"
  value       = aws_instance.ec2_instance.ami
}

output "arn" {
  description = "The ARN of the EC2 instance"
  value       = aws_instance.ec2_instance.arn
}
output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.ec2_instance.id
}

output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.ec2_instance.public_ip
}

output "private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.ec2_instance.private_ip
}

output "tags" {
  description = "The tags assigned to the EC2 instance"
  value       = aws_instance.ec2_instance.tags

}

output "ebs_volume_id" {
  description = "The ID of the EBS volume attached to the EC2 instance"
  value       = var.ec2.ebs_device_volume != null ? aws_ebs_volume.ebs_volume[0].id : null
}

