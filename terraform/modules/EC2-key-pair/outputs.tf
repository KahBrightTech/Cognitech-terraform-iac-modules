#--------------------------------------------------------------------
# Outputs for ec2 key pairs
#--------------------------------------------------------------------
output "name" {
  description = "The name of the generated key pair"
  value       = aws_key_pair.generated_key.key_name
}
