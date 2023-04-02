# Security HubはGuardDuty・IAM Access Analyzer・Inspector・Macie・Firewall Manager・サードパーティのプロダクトを集約管理するもの。
# FindingsをASFF(AWS Security Finding Format)という標準的な形式へ変換して一貫性のあるビューを提供する。

resource "aws_securityhub_account" "default" {}

resource "aws_securityhub_standards_subscription" "aws_best_practices" {
  standards_arn = "arn:aws:securityhub:ap-northeast-1::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.default]
}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:ap-northeast-1::standards/pci-dss/v/3.2.1"
  depends_on    = [aws_securityhub_account.default]
}
