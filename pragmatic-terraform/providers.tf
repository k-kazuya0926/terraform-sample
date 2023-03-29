provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Managed = "terraform-sample"
    }
  }
}

provider "aws" { # Multipleプロバイダ
  alias  = "virginia"
  region = "us-east-1"
}

provider "github" {
  owner = "your-github-name"
}
