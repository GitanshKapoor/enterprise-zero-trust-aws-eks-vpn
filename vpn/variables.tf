variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpn_cidr_block" {
  description = "CIDR block for the VPN"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs to attach the VPN to"
  type        = list(string)
}