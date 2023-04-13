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
