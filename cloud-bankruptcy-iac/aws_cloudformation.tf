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

resource "aws_cloudformation_stack" "chatbot" {
  name = "chatbot"

  template_body = yamlencode({
    Description = "Managed by Terraform"
    Resources = {
      AlertNotifications = {
        Type = "AWS::Chatbot::SlackChannelConfiguration"
        Properties = {
          ConfigurationName = "AlertNotifications"
          SlackWorkspaceId  = "T045PJDTT5H"
          SlackChannelId    = "C0462A8R6FK"
          IamRoleArn        = module.chatbot_iam_role.arn
          SnsTopicArns      = [aws_sns_topic.chatbot.arn]
        }
      }
    }
  })
}
