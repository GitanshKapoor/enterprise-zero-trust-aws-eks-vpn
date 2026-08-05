output "client_private_key" {
  description = "The raw private key for the VPN client"
  value       = tls_private_key.client.private_key_pem
  sensitive   = true  # Keeps it hidden from normal terminal logs for safety
}

output "client_certificate" {
  description = "The raw certificate for the VPN client"
  value       = tls_locally_signed_cert.client.cert_pem
  sensitive   = true  # Marked sensitive to prevent leaking in CI logs or terraform plan output
}