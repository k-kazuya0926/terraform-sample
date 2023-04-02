resource "aws_sns_topic" "mail" {
  name = "alert-mail"
}

resource "aws_sns_topic_policy" "cloudwatch_events" {
  arn    = aws_sns_topic.mail.arn
  policy = data.aws_iam_policy_document.cloudwatch_events.json
}

resource "aws_sns_topic" "chatbot" {
  name = "chatbot"
}

resource "aws_sns_topic_policy" "chatbot" {
  arn    = aws_sns_topic.chatbot.arn
  policy = data.aws_iam_policy_document.chatbot.json
}
