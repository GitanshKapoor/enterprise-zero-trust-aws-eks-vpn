# 🛡️ Enterprise Zero-Trust AWS EKS Architecture

> A hands-on Terraform revision exercise covering VPC networking, EKS, IAM, and AWS Client VPN from scratch. Built to sharpen infrastructure-as-code skills across real AWS services.

---

## 👨‍💻 About This Project

This is a **personal practice repository** I built to revise and deepen my Terraform skills. With ~2 years of cloud/infrastructure experience, I wanted to go beyond the basics and build something that reflects real-world patterns — a fully private EKS cluster locked behind a Mutual TLS Client VPN, all deployed as code with zero manual console clicks.

**What I practised:**
- Writing and structuring Terraform modules from scratch
- Wiring implicit dependencies between modules
- Working with the `tls` provider to automate certificate generation
- Troubleshooting Terraform state (`terraform import`)
- Debugging real AWS networking and firewall rules
- Connecting to a private Kubernetes cluster securely via VPN

---

## 🗂️ Module Structure

```
.
├── main.tf               # Root module — wires all modules together
├── variables.tf          # Root input variables
├── output.tf             # Root outputs (VPN certificates)
├── backend.tf            # S3 remote state backend
├── provider.tf           # AWS provider configuration
├── terraform.tfvars      # Variable values (NOT committed — see below)
│
├── vpc/                  # VPC, Subnets, IGW, NAT, Route Tables
├── iam/                  # IAM Roles for EKS Cluster & Worker Nodes
├── eks/                  # EKS Cluster, Node Group, CloudWatch Logs
└── vpn/                  # Client VPN, TLS Certs, ACM, Auth Rules
```

---

## 🚨 Before You Commit — Remove Sensitive Files

**Never commit these files to Git:**

| File / Pattern | Why it's sensitive |
|---|---|
| `terraform.tfvars` | Contains your CIDR blocks and project config |
| `*.tfstate` | Contains ALL resource IDs, ARNs, and raw certificate private keys in plaintext |
| `*.tfstate.backup` | Same as above |
| `.terraform/` | Contains provider binaries (large, not needed in git) |
| `my_key.txt` | Your raw VPN private key |
| `my_rsa_key.txt` | Your converted VPN private key |
| `*.ovpn` | Contains your client certificate and private key |

Make sure your `.gitignore` contains at minimum:
```gitignore
# Terraform state — contains sensitive data in plaintext!
*.tfstate
*.tfstate.backup
.terraform/
.terraform.lock.hcl

# Variable files — may contain secrets
terraform.tfvars
*.auto.tfvars

# VPN keys and profiles — highly sensitive!
*.pem
*.key
my_key.txt
my_rsa_key.txt
*.ovpn
```

> ⚠️ If you accidentally committed a `.tfstate` file, your VPN private keys are exposed in plain text in your git history. Rotate the certificates immediately by running `terraform apply` which will regenerate all TLS keys.

---

## 📐 Architecture Overview

![AWS EKS Zero-Trust Architecture Diagram](Docs/Architecture%20Diagram.jpg)

---

## ⚙️ Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured (`aws configure`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Tunnelblick](https://tunnelblick.net/) (macOS OpenVPN client)

---

## 🚀 Quick Start

### 1. Configure your variables
Create a `terraform.tfvars` file (do not commit this!):
```hcl
project_name         = "my-cluster"
machine_type         = "t2.small"
vpc_cidr             = "10.0.0.0/16"
vpn_cidr             = "10.1.0.0/16"   # Must NOT overlap with vpc_cidr!
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
```

### 2. Deploy
```bash
terraform init
terraform plan
terraform apply
```

### 3. Connect via VPN
```bash
# Export client certificate
terraform output vpn_client_certificate

# Export private key and convert to RSA format
terraform output -raw vpn_client_private_key > my_key.txt
openssl rsa -in my_key.txt -out my_rsa_key.txt
```
Download the `.ovpn` profile from the AWS Console → Client VPN Endpoints → **Download Client Configuration**, then paste the cert and key into it and load it into Tunnelblick.

### 4. Access the cluster
```bash
aws eks update-kubeconfig --region us-east-1 --name <your-cluster-name>
kubectl get nodes
```

### 5. Tear down (important!)
```bash
terraform destroy
```

---

## 📦 What Each Module Does

### `vpc/` — The Network Foundation
Builds a custom VPC with public and private subnets across two Availability Zones. Public subnets route to the Internet Gateway. Private subnets route through a NAT Gateway so worker nodes can download container images without being publicly accessible.

### `iam/` — The Identity Layer
Creates two IAM Roles: one for the EKS Control Plane (so AWS can manage the cluster) and one for the Worker Nodes (so EC2 instances can join the cluster and pull from ECR).

### `eks/` — The Compute Layer
Deploys a private EKS cluster with the public API endpoint disabled. Worker nodes live in private subnets. CloudWatch logging is enabled for audit trails. A security group rule opens Port 443 specifically for VPN traffic.

### `vpn/` — The Secure Access Layer
Uses the Terraform `tls` provider to act as its own Certificate Authority — generating a Root CA, a Server Certificate, and a Client Certificate entirely in code. Certificates are uploaded to ACM and a Client VPN Endpoint is created with Split Tunnel enabled so only cluster traffic goes through the VPN.

---

## 🔑 Key Design Decisions

| Decision | Reason |
|---|---|
| Private EKS endpoint only | API server is invisible to the public internet |
| Mutual TLS VPN | Both sides verify identity — more secure than password auth |
| Split Tunnel | Normal internet works while connected; only cluster traffic routes through VPN |
| Terraform-generated certs | No manual OpenSSL needed; fully reproducible as code |
| S3 remote state | Shared state without needing DynamoDB for this scale |
| Single NAT Gateway | Cost-optimised for practice; use one per AZ in production |

---

## ⚠️ Cost Warning

These AWS resources charge **by the hour**. Always destroy when done:

```bash
terraform destroy
```

| Resource | Approx Cost |
|---|---|
| EKS Cluster | ~$0.10/hr |
| NAT Gateway | ~$0.045/hr + data |
| EC2 Nodes (t2.small ×2) | ~$0.046/hr |
| Client VPN Endpoint | ~$0.10/hr + connections |

---