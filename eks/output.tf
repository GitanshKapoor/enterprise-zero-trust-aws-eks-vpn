output "cluster_endpoint" {
  description = "The API URL of the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}