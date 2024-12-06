output "vpc_id" {
  description = "The id of the vpc created"
  value       = aws_vpc.main.id
}


output "igw_id" {
  description = "The internet gateway id"
  value       = aws_internet_gateway.main_igw.id
}
