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

module "alternative_ec2" {
  source     = "./iam_role_module"
  name       = "alternative-ec2"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.alternative_ec2.json
}

data "aws_iam_policy_document" "alternative_ec2" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "cloudtrail_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [module.cloudtrail_log_bucket.arn]

    principals {
      identifiers = ["cloudtrail.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${module.cloudtrail_log_bucket.arn}/*"]

    principals {
      identifiers = ["cloudtrail.amazonaws.com"]
      type        = "Service"
    }

    condition {
      test     = "StringEquals"
      values   = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }
  }
}

data "aws_iam_policy_document" "cloudtrail" {
  statement {
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:log-group:*:log-stream:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

module "cloudtrail_iam_role" {
  source     = "./iam_role_module"
  name       = "cloudtrail"
  identifier = "cloudtrail.amazonaws.com"
  policy     = data.aws_iam_policy_document.cloudtrail.json
}

data "aws_iam_policy_document" "config_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [module.config_log_bucket.arn]

    principals {
      identifiers = ["config.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${module.config_log_bucket.arn}/AWSLogs/*/Config/*"]

    principals {
      identifiers = ["config.amazonaws.com"]
      type        = "Service"
    }

    condition {
      test     = "StringEquals"
      values   = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }
  }
}

resource "aws_iam_service_linked_role" "config" {
  aws_service_name = "config.amazonaws.com"
}

# すでに存在する場合
#data "aws_iam_role" "config" {
#  name = "AWSServiceRoleForConfig"
#}

data "aws_iam_policy_document" "cloudwatch_events" {
  statement {
    effect    = "Allow"
    resources = [aws_sns_topic.mail.arn]
    actions   = ["sns:Publish"]

    principals {
      identifiers = [
        "events.amazonaws.com",
        "cloudwatch.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_access" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
    ]
  }
}

module "chatbot_iam_role" {
  source     = "./iam_role_module"
  name       = "chatbot"
  identifier = "chatbot.amazonaws.com"
  policy     = data.aws_iam_policy_document.cloudwatch_access.json
}

data "aws_iam_policy_document" "chatbot" {
  statement {
    effect    = "Allow"
    resources = [aws_sns_topic.chatbot.arn]
    actions   = ["sns:Publish"]

    principals {
      identifiers = [
        "events.amazonaws.com",
        "cloudwatch.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "security_group_access" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:RevokeSecurityGroupIngress"]
    resources = ["*"]
  }
}

module "automation_security_group_iam_role" {
  source     = "./iam_role_module"
  name       = "automation-security-group"
  identifier = "ssm.amazonaws.com"
  policy     = data.aws_iam_policy_document.security_group_access.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "Bool"
      values   = ["true"]
      variable = "aws:MultiFactorAuthPresent" # MFAを実行したか
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "example" {
  name               = "example"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "example" {
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
  role       = aws_iam_role.example.name
}

data "aws_iam_policy_document" "assume_role_access" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["*"] # 本来は明示すべき
  }
}

resource "aws_iam_policy" "assume_role_access" {
  name   = "assume-role-access"
  policy = data.aws_iam_policy_document.assume_role_access.json
}

data "aws_iam_policy_document" "rotate_access_key_access" {
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateAccessKey",
      "iam:UpdateAccessKey",
      "iam:DeleteAccessKey",
      "iam:ListAccessKeys",
      "iam:GetAccessKeyLastUsed",
      "iam:GetUser",
    ]
    resources = ["arn:aws:iam::${local.account_id}:user/&{aws:username}"] # &{aws:username}：自身のIAMユーザー名
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_iam_policy" "rotate_access_key_access" {
  name   = "rotate-access-key-access"
  policy = data.aws_iam_policy_document.rotate_access_key_access.json
}

resource "aws_iam_group" "assumable" {
  name = "assumable"
}

resource "aws_iam_group_policy_attachment" "assume_role_access" {
  group      = aws_iam_group.assumable.name
  policy_arn = aws_iam_policy.assume_role_access.arn
}

resource "aws_iam_group_policy_attachment" "rotate_access_key_access" {
  group      = aws_iam_group.assumable.name
  policy_arn = aws_iam_policy.rotate_access_key_access.arn
}

resource "aws_iam_user" "base" {
  name          = "base"
  force_destroy = true
}

resource "aws_iam_group_membership" "assumable" {
  name  = aws_iam_group.assumable.name
  group = aws_iam_group.assumable.name
  users = [aws_iam_user.base.name]
}

resource "aws_iam_role" "readonly" {
  name               = "readonly"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "readonly" {
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  role       = aws_iam_role.readonly.name
}

resource "aws_iam_role" "admin" {
  name               = "admin"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "admin" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.admin.name
}
