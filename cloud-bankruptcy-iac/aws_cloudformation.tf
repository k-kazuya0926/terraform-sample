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
          SlackWorkspaceId  = "EXAMPLEID"
          SlackChannelId    = "ABCBBLZZZ"
          IamRoleArn        = module.chatbot_iam_role.arn
          SnsTopicArns = [
            module.tokyo.sns_topic_arn,
            module.virginia.sns_topic_arn,
          ]
        }
      }
    }
  })
}

# 2020年9月時点ではTerraformでは設定できないためCloudFormationを使っている
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
