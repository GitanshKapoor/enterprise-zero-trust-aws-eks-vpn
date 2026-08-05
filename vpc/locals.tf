locals {
    psub_count = length(var.public_subnet_cidrs)
    pisub_count = length(var.private_subnet_cidrs)
}