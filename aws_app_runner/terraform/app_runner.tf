variable "image_tag" {
  default = "v1"
}

data "aws_ecr_repository" "ecr_repo" {
  name = "flask-app"
}

data "aws_iam_role" "service_role" {
  name = "AppRunnerECRAccessRole"
}

resource "aws_apprunner_service" "svc" {
  service_name = "flask-app-svc"

  source_configuration {
    authentication_configuration {
      access_role_arn = data.aws_iam_role.service_role.arn
    }

    image_repository {
      image_configuration {
        port = "5000"
      }
      image_identifier      = "${data.aws_ecr_repository.ecr_repo.repository_url}:${var.image_tag}"
      image_repository_type = "ECR"
    }
    auto_deployments_enabled = false
  }
  instance_configuration {
    cpu    = "512"  # default: 1024
    memory = "1024" # default: 2048
  }
}

output "service_url" {
  value = aws_apprunner_service.svc.service_url
}
