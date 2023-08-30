terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.11.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }

  required_version = "~> 1.4.1"
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Env   = "Dev"
      Owner = "TFProviders"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"

  registry_auth {
    address  = data.aws_ecr_authorization_token.container_registry_token.proxy_endpoint
    username = data.aws_ecr_authorization_token.container_registry_token.user_name
    password = data.aws_ecr_authorization_token.container_registry_token.password
  }
}

variable "image_tag" {
  default = "v1"
}

data "aws_ecr_authorization_token" "container_registry_token" {}


resource "aws_ecr_repository" "ecr_repo" {
  name = "flask-app"
}

resource "docker_image" "image" {
  name = "${aws_ecr_repository.ecr_repo.repository_url}:${var.image_tag}"

  build {
    context = "../../app"
  }
}

resource "docker_registry_image" "ri" {
  name = docker_image.image.name
}
