resource "aws_lambda_function" "manage_batch" {
  filename      = "${path.module}/src/function.zip"
  function_name = "manage_batch"
  role          = aws_iam_role.iam_for_lambda.arn
  runtime       = "go1.x"
  handler       = "main"
}

# ===================================================================
# BATCHのタスク数を0,1にする設定
# ===================================================================
resource "aws_cloudwatch_event_target" "activate_batch" {
  arn       = aws_lambda_function.manage_batch.arn
  target_id = aws_lambda_function.manage_batch.id
  rule      = aws_cloudwatch_event_rule.activate_batch.id

  input_transformer {
    input_paths = {
      instance = "$.detail.instance",
      status   = "$.detail.status",
    }
    # ここでほしいタスクのカウント数を調整する。
    # BatchはOverlapしないようにPHPがわでも処理が書いてあるのでよい
    input_template = <<EOF
    {"DesiredCount": 1}
    EOF
  }
}

resource "aws_cloudwatch_event_target" "inactive_batch" {
  arn       = aws_lambda_function.manage_batch.arn
  target_id = aws_lambda_function.manage_batch.id
  rule      = aws_cloudwatch_event_rule.inactive_batch.id
  input_transformer {
    input_template = <<EOF
    {"DesiredCount": 0}
    EOF
  }
}

