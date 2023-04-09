resource "aws_config_configuration_recorder" "default" {
  name     = "default"
  role_arn = aws_iam_service_linked_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "default" {
  name           = aws_config_configuration_recorder.default.name
  s3_bucket_name = module.config_log_bucket.name
  depends_on     = [aws_config_configuration_recorder.default]
}

resource "aws_config_configuration_recorder_status" "default" {
  is_enabled = true
  name       = aws_config_configuration_recorder.default.name
  depends_on = [aws_config_delivery_channel.default]
}

resource "aws_config_config_rule" "restricted_ssh" {
  name        = "restricted-ssh"
  description = "SSHポートがIPアドレス制限をしているか確認します。"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  scope {
    compliance_resource_types = [
      "AWS::EC2::SecurityGroup"
    ]
  }
}
