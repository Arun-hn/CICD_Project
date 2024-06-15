resource "aws_eks_cluster" "eks" {
  name     = "eks"
  version  = "1.27"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    endpoint_public_access = true
    subnet_ids = [
      aws_subnet.private1.id,
      aws_subnet.private2.id,
      aws_subnet.public1.id,
      aws_subnet.public2.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.amazon_eks_cluster_policy]
}