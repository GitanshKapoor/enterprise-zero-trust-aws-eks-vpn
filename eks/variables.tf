variable "cluster_name" {
    description = "Name of the Cluster"
    type        = string
}

variable "cluster_role" {
    description = "Cluster Manager Role"
    type        = string
}

variable "worker_node_role" {
    description = "Cluster Worker Node Role"
    type        = string
}

variable "public_subnet_ids" {
    description = "Public Subnet ID List"
    type        = list(string)
}

variable "private_subnet_ids" {
    description = "Private Subnet ID List"
    type        = list(string)
}

variable "machine_type" {
    description = "Worker Node Machine Type"
    type        = string
}

variable "vpc_cidr" {
    description = "VPC CIDR Block"
    type        = string
}