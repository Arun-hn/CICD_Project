resource "aws_eks_node_group" "private_nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "private-nodes"
  node_role_arn   = aws_iam_role.nodes.arn

  # Single subnet to avoid data transfer charges while testing.
  subnet_ids = [
    aws_subnet.private1.id
  ]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  labels = {
    role = "nodes-general"
  }

  tags = {
    Name        = "private-nodes"
    Environment = "testing"
    Project     = "Ultimate-CICD"
  }


  depends_on = [
    aws_iam_role_policy_attachment.nodes_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.nodes_amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.nodes_amazon_ec2_container_registry_read_only,
  ]
}
