resource "aws_s3_bucket" "private" {
  bucket = "private-pragmatic-terraform"

  # depricated
  #  versioning {
  #    enabled = true
  #  }

  # depricated
  #  server_side_encryption_configuration {
  #    rule {
  #      apply_server_side_encryption_by_default {
  #        sse_algorithm = "AES256"
  #      }
  #    }
  #  }
}

resource "aws_s3_bucket_versioning" "private" {
  bucket = aws_s3_bucket.private.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private" {
  bucket = aws_s3_bucket.private.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "public" {
  bucket = "public-pragmatic-terraform"
  # depricated
  #  acl = "public-read"

  # depricated
  #  cors_rule {
  #    allowed_methods = []
  #    allowed_origins = []
  #  }
}

resource "aws_s3_bucket_acl" "public" {
  bucket = aws_s3_bucket.public.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "public" {
  bucket = aws_s3_bucket.public.id

  cors_rule {
    allowed_origins = ["https://example.com"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-pragmatic-terraform"

  # depricated
  #  lifecycle_rule {
  #    enabled = true
  #
  #    expiration {
  #      days = "180"
  #    }
  #  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id

  rule {
    id     = "expiration"
    status = "Enabled"
    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      identifiers = ["582318560864"]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket" "artifact" {
  bucket = "artifact-pragmatic-terraform"
}

resource "aws_s3_bucket_lifecycle_configuration" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  rule {
    id     = "expiration"
    status = "Enabled"
    expiration {
      days = "180"
    }
  }
}
