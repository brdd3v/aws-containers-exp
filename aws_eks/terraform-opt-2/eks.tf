resource "aws_eks_cluster" "cluster" {
  name     = "eks-cluster-exp"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public_1a.id,
      aws_subnet.public_1b.id,
      aws_subnet.private_1a.id,
      aws_subnet.private_1b.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.rpa_AmazonEKSClusterPolicy
  ]
}

resource "aws_eks_fargate_profile" "eks_fargate_profile" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "fargate-profile-exp"
  pod_execution_role_arn = aws_iam_role.eks_fargate_profile_role.arn
  subnet_ids = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1b.id
  ]

  selector {
    namespace = "default"
  }
}
