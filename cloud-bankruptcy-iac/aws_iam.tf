data "aws_iam_policy_document" "admin_access" {
  statement {
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "admin_access" {
  name   = "admin-access"
  policy = data.aws_iam_policy_document.admin_access.json
}

resource "aws_iam_user" "terraform" {
  name          = "cloud-bankruptcy-iac" # 本ではterraformとなっている
  force_destroy = true
}

resource "aws_iam_group" "admin" {
  name = "admin"
}

# IAMグループへIAMユーザーを関連付け
resource "aws_iam_group_membership" "admin" {
  name  = aws_iam_group.admin.name
  group = aws_iam_group.admin.name
  users = [aws_iam_user.terraform.name]
}

# IAMグループへIAMポリシーをアタッチ
resource "aws_iam_group_policy_attachment" "admin" {
  group      = aws_iam_group.admin.name
  policy_arn = aws_iam_policy.admin_access.arn
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 32
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true # !@#$%^&*()_+=[]{}|'
  allow_users_to_change_password = true
  password_reuse_prevention      = 24 # 24は最大値
  max_password_age               = 0
}

# IPアドレス制限
data "aws_iam_policy_document" "alternative-log" {
  statement {
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["${module.alternative-log.arn}/*"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "NotIpAddress"
      values   = ["192.0.2.1/32"]
      variable = "aws:SourceIp"
    }
  }
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "s3_access" {
  name   = "s3-access"
  policy = data.aws_iam_policy_document.s3_access.json
}

# 信頼ポリシー
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ec2.amazonaws.com"] # IAMロールをEC2にアタッチ可能
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ec2" {
  policy_arn = aws_iam_policy.s3_access.arn
  role       = aws_iam_role.ec2.name
}
