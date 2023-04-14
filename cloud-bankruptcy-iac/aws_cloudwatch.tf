resource "aws_cloudwatch_log_group" "logs" {
  name              = "CloudTrail/logs"
  retention_in_days = 14
}

resource "aws_cloudwatch_event_rule" "guardduty" {
  name = "guardduty"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty" {
  target_id = "guardduty"
  rule      = aws_cloudwatch_event_rule.guardduty.name
  arn       = data.aws_sns_topic.mail.arn

  input_transformer {
    input_paths = {
      "type"        = "$.detail.type"
      "description" = "$.detail.description"
      "severity"    = "$.detail.severity"
    }

    # 指定しない場合、CloudWatch Eventsが生成するJSONが配信される
    input_template = <<EOF
      "You have a severity <severity> GuardDuty finding type <type>"
      "<description>"
    EOF
  }
}

data "aws_sns_topic" "mail" {
  name = "alert-mail"
}

resource "aws_cloudwatch_event_rule" "access_analyzer" {
  name = "access-analyzer"

  event_pattern = jsonencode({
    source      = ["aws.access-analyzer"]
    detail-type = ["Access Analyzer Finding"]
    detail = { # リソースを非公開にした場合などでもイベントが発火するため、ACTIVEのみを対象とする
      status = ["ACTIVE"]
    }
  })
}

resource "aws_cloudwatch_event_target" "access_analyzer" {
  target_id = "access-analyzer"
  rule      = aws_cloudwatch_event_rule.access_analyzer.name
  arn       = data.aws_sns_topic.mail.arn

  input_transformer {
    input_paths = {
      "type"     = "$.detail.resourceType"
      "resource" = "$.detail.resource"
      "action"   = "$.detail.action"
    }

    input_template = <<EOF
    "<type>/<resource> allows public access."
    "Action granted: <action>"
    EOF
  }
}

resource "aws_cloudwatch_event_rule" "securityhub" {
  name = "securityhub"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        ProductFields = {
          "aws/securityhub/ProductName" = [
            "GuardDuty",
            "IAM Access Analyzer",
          ]
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "securityhub" {
  target_id = "securityhub"
  arn       = data.aws_sns_topic.mail.arn
  rule      = aws_cloudwatch_event_rule.securityhub.name

  input_transformer {
    input_paths = {
      "description" = "$.detail.findings[0].Description"
      "severity"    = "$.detail.findings[0].Severity.Label"
    }
    input_template = "\"Security Hub(<severity>) - <description>\""
  }
}

resource "aws_cloudwatch_event_target" "chatbot" {
  target_id = "chatbot"
  arn       = aws_sns_topic.chatbot.arn
  rule      = aws_cloudwatch_event_rule.guardduty.name
}

module "alternative_root_account_usages" {
  source    = "./cloudwatch_alarms_module"
  name      = "alternative-root-account-usages"
  threshold = 1
  pattern   = "{$.userIdentity.type=\"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType !=\"AwsServiceEvent\"}"
}

module "cloud_trail_changes" {
  source    = "./cloudwatch_alarms_module"
  name      = "cloud_trail_changes"
  threshold = 1
  pattern   = "{($.eventName=CreateTrail) || ($.eventName=UpdateTrail) || ($.eventName=DeleteTrail) || ($.eventName=StartLogging) || ($.eventName=StopLogging)}"
}

module "aws_config_changes" {
  source    = "./cloudwatch_alarms_module"
  name      = "aws_config_changes"
  threshold = 1
  pattern   = "{($.eventSource=config.amazonaws.com) && (($.eventName=StopConfigurationRecorder) || ($.eventName=DeleteDeliveryChannel) || ($.eventName=PutDeliveryChannel) || ($.eventName=PutConfigurationRecorder))}"
}

module "console_sign_in_without_mfa" {
  source    = "./cloudwatch_alarms_module"
  name      = "console_sign_in_without_mfa"
  threshold = 1
  pattern   = "{($.eventName=\"ConsoleLogin\") && ($.additionalEventData.MFAUsed !=\"Yes\")}"
}

module "vpc_changes" {
  source    = "./cloudwatch_alarms_module"
  name      = "vpc-changes"
  threshold = 1
  pattern   = "{($.eventName=CreateVpc) || ($.eventName=DeleteVpc) || ($.eventName=ModifyVpcAttribute) || ($.eventName=AcceptVpcPeeringConnection) || ($.eventName=CreateVpcPeeringConnection) || ($.eventName=DeleteVpcPeeringConnection) || ($.eventName=RejectVpcPeeringConnection) || ($.eventName=AttachClassicLinkVpc) || ($.eventName=DetachClassicLinkVpc) || ($.eventName=DisableVpcClassicLink) || ($.eventName=EnableVpcClassicLink)}"
}

module "gateway_changes" {
  source    = "./cloudwatch_alarms_module"
  name      = "gateway-changes"
  threshold = 1
  pattern   = "{($.eventName=CreateCustomerGateway) || ($.eventName=DeleteCustomerGateway) || ($.eventName=AttachInternetGateway) || ($.eventName=CreateInternetGateway) || ($.eventName=DeleteInternetGateway) || ($.eventName=DetachInternetGateway)}"
}

module "route_table_changes" {
  source    = "./cloudwatch_alarms_module"
  name      = "route-table-changes"
  threshold = 1
  pattern   = "{($.eventName=CreateRoute) || ($.eventName=CreateRouteTable) || ($.eventName=ReplaceRoute) || ($.eventName=ReplaceRouteTableAssociation) || ($.eventName=DeleteRouteTable) || ($.eventName=DeleteRoute) || ($.eventName=DisassociateRouteTable)}"
}

module "network_acl_changes" {
  source    = "./cloudwatch_alarms_module"
  name      = "network-acl-changes"
  threshold = 1
  pattern   = "{($.eventName=CreateNetworkAcl) || ($.eventName=CreateNetworkAclEntry) || ($.eventName=DeleteNetworkAcl) || ($.eventName=DeleteNetworkAclEntry) || ($.eventName=ReplaceNetworkAclEntry) || ($.eventName=ReplaceNetworkAclAssociation)}"
}

module "s3_bucket_policy_changes" {
  source    = "./cloudwatch_alarms_module"
  name      = "s3-bucket-policy-changes"
  threshold = 1
  pattern   = "{($.eventSource=s3.amazonaws.com) && (($.eventName=PutBucketAcl) || ($.eventName=PutBucketPolicy) || ($.eventName=PutBucketCors) || ($.eventName=PutBucketLifecycle) || ($.eventName=PutBucketReplication) || ($.eventName=DeleteBucketPolicy) || ($.eventName=DeleteBucketCors) || ($.eventName=DeleteBucketLifecycle) || ($.eventName=DeleteBucketReplication))}"
}

module "cmk_changes" {
  source    = "./cloudwatch_alarms_module"
  name      = "cmk-changes"
  threshold = 1
  pattern   = "{($.eventSource=kms.amazonaws.com) && (($.eventName=DisableKey) || ($.eventName=ScheduleKeyDeletion))}"
}

module "console_sign_in_failures" {
  source    = "./cloudwatch_alarms_module"
  name      = "console-sign-in-failures"
  threshold = 3
  pattern   = "{($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\")}"
}

module "authorization_failures" {
  source    = "./cloudwatch_alarms_module"
  name      = "authorization-failures"
  threshold = 3
  pattern   = "{($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\")}"
}

module "security_group_changes" {
  source    = "./cloudwatch_alarms_module"
  name      = "security-group-changes"
  threshold = 1
  pattern   = "{($.eventName=AuthorizeSecurityGroupIngress) || ($.eventName=AuthorizeSecurityGroupEgress) || ($.eventName=RevokeSecurityGroupIngress) || ($.eventName=RevokeSecurityGroupEgress) || ($.eventName=CreateSecurityGroup) || ($.eventName=DeleteSecurityGroup)}"
}

module "iam_policy_changes" {
  source    = "./cloudwatch_alarms_module"
  name      = "iam-policy-changes"
  threshold = 1
  pattern   = "{($.eventName=DeleteGroupPolicy) || ($.eventName=DeleteRolePolicy) || ($.eventName=DeleteUserPolicy) || ($.eventName=PutGroupPolicy) || ($.eventName=PutRolePolicy) || ($.eventName=PutUserPolicy) || ($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=CreatePolicyVersion) || ($.eventName=DeletePolicyVersion) || ($.eventName=AttachRolePolicy) || ($.eventName=DetachRolePolicy) || ($.eventName=AttachUserPolicy) || ($.eventName=DetachUserPolicy) || ($.eventName=AttachGroupPolicy) || ($.eventName=DetachGroupPolicy)}"
}
