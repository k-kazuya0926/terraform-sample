resource "aws_athena_database" "security_log" {
  name   = "security_log"
  bucket = module.athena_query_result_bucket.name
}

locals {
  create_table = templatefile("${path.module}/create_table.sql", {
    database_name = aws_athena_database.security_log.name
    table_name    = "cloudtrail"
    bucket_name   = data.aws_s3_bucket.cloudtrail_log.id
    account_id    = data.aws_caller_identity.current.account_id
    regions       = join(",", data.aws_regions.current.names)
  })
}

data "aws_s3_bucket" "cloudtrail_log" {
  bucket = "cloudtrail-log-cloud-bankruptcy-iac-kazuya-kobayashi"
}

data "aws_regions" "current" {}

resource "null_resource" "create_table" {
  provisioner "local-exec" { # 原則的には使用は控えるべき。Terraformのライフサイクルと相性がよくない
    command = <<EOT
      aws athena start-query-execution --result-configuration \
      OutputLocation=s3://${module.athena_query_result_bucket.name} \
      --query-string "${local.create_table}"
    EOT
  }

  triggers = { # Nullリソースの変更を検知するトリガー
    create_table = local.create_table
  }
}
