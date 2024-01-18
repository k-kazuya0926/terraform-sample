resource "aws_budgets_budget" "monthly_cost" {
  name              = "MonthlyCost"
  budget_type       = "COST"
  limit_amount      = "15.0"
  limit_unit        = "USD" # コスト予算の場合、単位はドルのみ
  time_unit         = "MONTHLY"
  time_period_start = "2023-01-01_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL" # 予測値の場合は"FORECASTED"
    subscriber_email_addresses = ["test@example.com"]
  }
}
