module "alternative-log" {
  source = "./log_bucket_module"
  name   = "alternative-log-cloud-bankruptcy-iac-kazuya-kobayashi"
}

resource "aws_s3_bucket_policy" "alternative-log" {
  bucket     = module.alternative-log.name
  policy     = data.aws_iam_policy_document.alternative-log.json
  depends_on = [module.alternative-log] # 同時applyできない
}

module "cloudtrail_log_bucket" {
  source = "./log_bucket_module"
  name   = "cloudtrail-log-cloud-bankruptcy-iac-kazuya-kobayashi"
}

resource "aws_s3_bucket_policy" "cloudtrail_log" {
  bucket     = module.cloudtrail_log_bucket.name
  policy     = data.aws_iam_policy_document.cloudtrail_log.json
  depends_on = [module.cloudtrail_log_bucket]
}

module "config_log_bucket" {
  source = "./log_bucket_module"
  name   = "config-log-cloud-bankruptcy-iac-kazuya-kobayashi"
}

resource "aws_s3_bucket_policy" "config_log" {
  bucket     = module.config_log_bucket.name
  policy     = data.aws_iam_policy_document.config_log.json
  depends_on = [module.config_log_bucket]
}
