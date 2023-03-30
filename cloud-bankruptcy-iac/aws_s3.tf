module "alternative-log" {
  source = "./log_bucket_module"
  name   = "alternative-log-cloud-bankruptcy-iac-kazuya-kobayashi"
}

resource "aws_s3_bucket_policy" "alternative-log" {
  bucket     = module.alternative-log.name
  policy     = data.aws_iam_policy_document.alternative-log.json
  depends_on = [module.alternative-log] # 同時applyできない
}
