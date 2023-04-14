resource "aws_guardduty_detector" "default" {
  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"
}

module "tokyo" {
  source = "./guardduty_module"
}

module "virginia" {
  source = "./guardduty_module"

  providers = {
    aws = aws.virginia
  }
}
