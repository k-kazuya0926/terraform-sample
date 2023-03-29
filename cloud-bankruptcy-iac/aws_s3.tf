resource "aws_s3_bucket" "log" {
  bucket = "log-cloud-bankruptcy-iac-kazuya-kobayashi"
}

resource "aws_s3_bucket_versioning" "log" {
  bucket = aws_s3_bucket.log.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log" {
  bucket = aws_s3_bucket.log.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "log" {
  bucket = aws_s3_bucket.log.id

  rule {
    id     = "expiration"
    status = "Enabled"
    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log" {
  bucket                  = aws_s3_bucket.log.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

#resource "aws_s3_bucket_policy" "log" {
#  bucket     = aws_s3_bucket.log.id
#  policy     = data.aws_iam_policy_document.log.json
#  depends_on = [aws_s3_bucket_public_access_block.log] # 同時applyできない
#}

module "alternative_log" {
  source = "./log_bucket_module"
  name   = "alternative-log-cloud-bankruptcy-iac-kazuya-kobayashi"
}
