output "cluster_manager_arn" {
    description = "ARN for Cluster Manager Role"
    value = aws_iam_role.eks_cluster_manager_role.arn
}

output "worker_node_arn" {
    description = "ARN for Worker Node Role"
    value = aws_iam_role.eks_worker_node_user_role.arn
}