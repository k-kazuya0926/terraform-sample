terraform {
  required_version = "1.4.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.59.0"
    }
  }

  # S3を使用する場合
  #  backend "s3" {
  #    backet = "tfstate-pragmatic-terraform"
  #    key    = "example/terraform.tfstate"
  #    region = "ap-northeast-1"
  #  }

  # Terraform Cloudを使用する場合
  backend "remote" {
    organization = "kazuya-kobayashi"

    workspaces {
      name = "example_workspace"
    }
  }
}
