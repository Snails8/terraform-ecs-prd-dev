# ===================================================================
# cloudwatch event rule
# ===================================================================
resource "aws_cloudwatch_event_rule" "activate_batch" {
  name                = "activate_batch"
  description         = "Active ECS batch task desired count from 0 to 1."
  schedule_expression = var.activate_schedule_cron_expression
}

resource "aws_cloudwatch_event_rule" "inactive_batch" {

  name                = "inactive_batch"
  description         = "Inactive ECS batch task desired count from 1 to 0."
  schedule_expression = var.inactivate_schedule_cron_expression
}

# ===================================================================
# cloudwatch event rule permission
# ===================================================================
resource "aws_lambda_permission" "inactivate_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch_inactivate"
  action        = "lambda:InvokeFunction"
  function_name = aws_cloudwatch_event_target.inactive_batch.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.inactive_batch.arn
}
resource "aws_lambda_permission" "activate_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch_activate"
  action        = "lambda:InvokeFunction"
  function_name = aws_cloudwatch_event_target.activate_batch.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.activate_batch.arn
}

variable "inactivate_schedule_cron_expression" {
  type    = string
  default = "cron(0 10 * * ? *)"
}
variable "activate_schedule_cron_expression" {
  type    = string
  default = "cron(0 8 * * ? *)"
}