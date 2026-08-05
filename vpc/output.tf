output "vpc_id" {
  description = "The ID of the VPC we just created"
  value       = aws_vpc.project_vpc.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets we just created"
  value       = aws_subnet.project_public_subnet[*].id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets we just created"
  value       = aws_subnet.project_private_subnet[*].id
}