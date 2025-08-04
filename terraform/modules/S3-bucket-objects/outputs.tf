output "ids" {
  description = "IDs of the S3 bucket objects"
  value       = length(aws_s3_object.objects) > 0 ? values(aws_s3_object.objects)[*].id : null

}

output "objects" {
  description = "S3 bucket objects"
  value       = length(aws_s3_object.objects) > 0 ? values(aws_s3_object.objects) : null

}
