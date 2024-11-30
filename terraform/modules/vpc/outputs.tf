output "vpc_arn" {
  description = "The arn of the vpc"
  value       = aws_vpc.main.arn

}

output "vpc_id" {
  description = "The id of the vpc created"
  value       = aws_vpc.main.ifd
}
