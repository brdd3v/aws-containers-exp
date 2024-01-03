variable "image_tag" {
  default = "v1"
}

data "aws_ecr_repository" "ecr_repo" {
  name = "flask-app"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-exp"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rpa_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-exp"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rpa_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "rpa_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "rpa_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_cluster" "cluster" {
  name     = "eks-cluster-exp"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = data.aws_subnets.all.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.rpa_AmazonEKSClusterPolicy
  ]
}

resource "aws_eks_node_group" "node_group" {
  node_group_name = "eks-node-group-exp"
  cluster_name    = aws_eks_cluster.cluster.name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.all.ids
  disk_size       = 45 # Defalut 20
  # instance_types  = ["t3.medium"] # Default, 2 vCPU, 4 GiB Memory

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.rpa_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.rpa_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.rpa_AmazonEC2ContainerRegistryReadOnly
  ]
}

# output "eks_cluster_endpoint" {
#   value = aws_eks_cluster.cluster.endpoint
# }

resource "kubernetes_deployment" "app" {
  metadata {
    name = "flask-app"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "flask-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "flask-app"
        }
      }
      spec {
        container {
          name  = "flask-app"
          image = "${data.aws_ecr_repository.ecr_repo.repository_url}:${var.image_tag}"
          port {
            container_port = 5000
          }
          # resources {
          #   limits = {
          #     cpu    = "512m"
          #     memory = "1024m"
          #   }
          # }
        }
      }
    }
  }
  depends_on = [aws_eks_node_group.node_group]
}

resource "kubernetes_service" "app" {
  metadata {
    name = "flask-app"
  }
  spec {
    selector = {
      app = kubernetes_deployment.app.spec.0.template.0.metadata.0.labels.app
      app = "flask-app"
    }
    type = "NodePort"
    port {
      node_port   = 31479
      port        = 5000
      target_port = 5000
    }
  }
  # depends_on = [kubernetes_deployment.app]
}
