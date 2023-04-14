module "tokyo" {
  source = "./guardduty_module"
}

module "virginia" {
  source = "./guardduty_module"

  providers = {
    aws = aws.virginia
  }
}
