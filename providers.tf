provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Managed = "terraform-sample"
    }
  }
}

provider "github" {
  owner = "your-github-name"
}
