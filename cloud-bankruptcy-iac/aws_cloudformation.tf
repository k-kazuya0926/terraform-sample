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

# 2020年9月時点ではTerraformでは設定できなかったためCloudFormationを使っている
resource "aws_cloudformation_stack" "disable_security_group" {
  name = "AWS-DisablePublicAccessForSecurityGroup"

  template_body = yamlencode({
    Description = "Managed by Terraform"
    Resources = {
      DisablePublicAccessForSecurityGroup = {
        Type = "AWS::Config::RemediationConfiguration"
        Properties = {
          ConfigRuleName = aws_config_config_rule.restricted_ssh.name
          TargetType     = "SSM_DOCUMENT"
          TargetId       = "AWS-DisablePublicAccessForSecurityGroup"
          Parameters = {
            GroupId = {
              ResourceValue = {
                Value = "RESOURCE_ID"
              }
            },
            AutomationAssumeRole = {
              StaticValue = {
                Values = [module.automation_security_group_iam_role.arn]
              }
            }
          }
          Automatic                = true
          MaximumAutomaticAttempts = 1
          RetryAttemptSeconds      = 60
        }
      }
    }
  })
}
