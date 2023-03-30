# メールプロトコルのサブスクリプションはTerraformで実装できないため、CloudFormationを使う
resource "aws_cloudformation_stack" "mail_subscription" {
  name = "mail-subcription"

  template_body = yamlencode({
    Description = "Managed by Terraform"
    Resources = {
      MailSubscription = {
        Type = "AWS::SNS::Subscription"
        Properties = {
          TopicArn = aws_sns_topic.mail.arn
          Protocol = "email"
          Endpoint = "test@example.com"
        }
      }
    }
  })
}
