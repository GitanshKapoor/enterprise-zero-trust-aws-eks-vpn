output "eks_cluster_url" {
  description = "The URL to connect to the cluster"
  # WIRING: Grab the URL from the EKS module and print it to the screen!
  value       = module.eks.cluster_endpoint
}

output "vpn_client_private_key" {
  description = "Your secret VPN Private Key (Run: terraform output -raw vpn_client_private_key)"
  value       = module.vpn.client_private_key
  sensitive   = true
}

output "vpn_client_certificate" {
  description = "Your public VPN Certificate"
  value       = module.vpn.client_certificate
  sensitive   = true
}