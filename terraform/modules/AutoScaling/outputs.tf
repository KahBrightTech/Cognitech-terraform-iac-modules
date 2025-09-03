output "name" {
  description = "The name of the Auto Scaling group"
  value       = aws_autoscaling_group.main.name
}

output "arn" {
  description = "The ARN of the Auto Scaling group"
  value       = aws_autoscaling_group.main.arn
}

output "id" {
  description = "The ID of the Auto Scaling group"
  value       = aws_autoscaling_group.main.id

}

output "subnet_ids" {
  description = "The subnet IDs associated with the Auto Scaling group"
  value       = aws_autoscaling_group.main.vpc_zone_identifier
}
