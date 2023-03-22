resource "aws_codebuild_project" "example" {
  name         = "example"
  service_role = module.codebuild_role.iam_role_arn

  source { # ビルド対象
    type = "CODEPIPELINE"
  }

  artifacts { # ビルド出力アーティファクト
    type = "CODEPIPELINE"
  }

  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:2.0"
    privileged_mode = true # dockerコマンドを使うのに必要
  }
}
