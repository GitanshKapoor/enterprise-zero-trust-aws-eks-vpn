resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.cluster_role

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }
}

resource "aws_eks_node_group" "main" {
    cluster_name = aws_eks_cluster.main.name
    node_group_name = "${var.cluster_name}-node-group"
    node_role_arn = var.worker_node_role
    subnet_ids = var.private_subnet_ids

    instance_types = [var.machine_type]

    scaling_config {
        desired_size = 3
        max_size     = 4
        min_size     = 2
    }

}

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  tags = {
    Name       = "${var.cluster_name}-log-group",
    environment = "Test"
  }
}

resource "aws_security_group_rule" "vpn_to_eks" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}