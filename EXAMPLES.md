# Examples

This directory contains example `terraform.tfvars` configurations for different use cases.
Each example shows how you can customise the architecture without touching any module code.

---

## 📁 examples/

```
examples/
├── minimal/          # Smallest possible setup (1 node, cheapest instance)
├── production/       # Multi-AZ, larger nodes, more replicas
└── multi-region/     # How to extend this to a second AWS region
```

---

## 🟢 Minimal (Dev / Learning)

Use this when you just want to spin up the architecture quickly and cheaply.

```hcl
# examples/minimal/terraform.tfvars

project_name = "dev-cluster"
machine_type = "t2.micro"

vpc_cidr             = "10.0.0.0/16"
vpn_cidr             = "10.1.0.0/16"

public_subnet_cidrs  = ["10.0.1.0/24"]
private_subnet_cidrs = ["10.0.3.0/24"]
```

**Estimated cost:** ~$0.15/hr while running

---

## 🔵 Standard (This Project)

The default configuration used in this project.

```hcl
# terraform.tfvars (root)

project_name = "Multi-Tier-Architecture"
machine_type = "t2.small"

vpc_cidr             = "10.0.0.0/16"
vpn_cidr             = "10.1.0.0/16"

public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
```

**Estimated cost:** ~$0.20/hr while running

---

## 🟠 Production

Use this for a more resilient, higher-availability setup.
Requires updating the `scaling_config` in `eks/main.tf` as well.

```hcl
# examples/production/terraform.tfvars

project_name = "prod-cluster"
machine_type = "t3.medium"

vpc_cidr             = "10.0.0.0/16"
vpn_cidr             = "10.2.0.0/16"

public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
```

Also update `eks/main.tf` scaling config for production:
```hcl
scaling_config {
  desired_size = 3
  max_size     = 6
  min_size     = 3
}
```

**Estimated cost:** ~$0.50/hr while running

---

## 🌍 Multi-Region Extension

To extend this architecture to a second AWS region (e.g., `eu-west-2`), add a provider alias in `provider.tf`:

```hcl
# provider.tf

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu"
  region = "eu-west-2"
}
```

Then call a second instance of each module, passing the aliased provider:

```hcl
# main.tf

module "vpc_eu" {
  source = "./vpc"
  providers = { aws = aws.eu }

  vpc_name             = "${var.project_name}-eu-vpc"
  vpc_cidr             = "10.10.0.0/16"   # Different CIDR from US!
  public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs = ["10.10.3.0/24", "10.10.4.0/24"]
}

module "eks_eu" {
  source = "./eks"
  providers = { aws = aws.eu }

  cluster_name       = "${var.project_name}-eu-cluster"
  cluster_role       = module.iam.cluster_manager_arn
  worker_node_role   = module.iam.worker_node_arn
  private_subnet_ids = module.vpc_eu.private_subnet_ids
  public_subnet_ids  = module.vpc_eu.public_subnet_ids
  machine_type       = var.machine_type
}
```

> ⚠️ Each region needs its own **VPN Endpoint** and its own **non-overlapping CIDR blocks**.

---

## 💡 Tips

| Tip | Detail |
|---|---|
| **Change instance type** | Edit `machine_type` in `terraform.tfvars` |
| **Scale nodes** | Edit `desired_size` / `max_size` in `eks/main.tf` |
| **Change region** | Edit the `provider` block in `provider.tf` |
| **Use a different VPN CIDR** | Make sure it does NOT overlap with `vpc_cidr` |
| **Add more subnets** | Add more CIDRs to `public_subnet_cidrs` or `private_subnet_cidrs` |
