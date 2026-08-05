variable "project_name" {
  description = "VPC and Cluster name"
  type = string
}

variable "machine_type" {
  description = "Machine type for the instances"

  type = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type = string
}

variable "vpn_cidr" {
  description = "VPN CIDR block"
  type = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"

  type = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type = list(string)
}