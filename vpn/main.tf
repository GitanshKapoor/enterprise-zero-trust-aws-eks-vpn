resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_private_key" "client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client" {
  private_key_pem = tls_private_key.client.private_key_pem
  subject {
    common_name  = "client.${var.project_name}.vpn.local"
    organization = "My Organization"
  }
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem   = tls_cert_request.client.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem
  
  validity_period_hours = 8760
  
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = "${var.project_name}.vpn.local"
    organization = "My Organization"
  }

  validity_period_hours = 8760
  is_ca_certificate     = true
  
  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name  = "server.${var.project_name}.vpn.local"
    organization = "My Organization"
  }
}

resource "tls_locally_signed_cert" "server" {
    cert_request_pem = tls_cert_request.server.cert_request_pem
    ca_private_key_pem = tls_private_key.ca.private_key_pem
    ca_cert_pem        = tls_self_signed_cert.ca.cert_pem
    
    validity_period_hours = 8760
    
    allowed_uses = [
        "key_encipherment",
        "digital_signature",
        "server_auth",
    ]
}

resource "aws_acm_certificate" "server" {
  private_key = tls_private_key.server.private_key_pem
  certificate_body = tls_locally_signed_cert.server.cert_pem
  certificate_chain = tls_self_signed_cert.ca.cert_pem
}

resource "aws_acm_certificate" "client" {
  private_key = tls_private_key.client.private_key_pem
  certificate_body = tls_locally_signed_cert.client.cert_pem
  certificate_chain = tls_self_signed_cert.ca.cert_pem
}

resource "aws_ec2_client_vpn_endpoint" "main" {
    description            = "${var.project_name}-vpn-endpoint"
    server_certificate_arn = aws_acm_certificate.server.arn
    client_cidr_block      = var.vpn_cidr_block
    split_tunnel = true

    authentication_options {
        type                       = "certificate-authentication"
        root_certificate_chain_arn = aws_acm_certificate.client.arn
    }

    connection_log_options {
        enabled = false
    }
}

resource "aws_ec2_client_vpn_network_association" "main" {
    client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
    # FIX: Used variable instead of module to respect module scope
    subnet_id              = var.private_subnet_ids[0]
}

resource "aws_ec2_client_vpn_authorization_rule" "main" {
    client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
    # FIX: Removed [] brackets because this expects a string, not a list
    target_network_cidr    = var.vpc_cidr
    authorize_all_groups   = true
}