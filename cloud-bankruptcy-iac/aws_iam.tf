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
