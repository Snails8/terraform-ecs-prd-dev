## AutoScaling_ECSService
resource "aws_iam_role" "auto_scale" {
  name               = "ecs_auto_scale_role"
  assume_role_policy = file("${path.module}/policy/auto_scale.json")
}

resource "aws_iam_policy" "auto_scale" {
  name        = "AWSApplicationAutoscalingECSService_Policy"
  description = "AWSApplicationAutoscalingECSService_Policy"
  policy      = file("${path.module}/policy/auto_scale_ecs_service.json")
}

resource "aws_iam_role_policy_attachment" "ecs_autoscale_role_attach" {
  role       = aws_iam_role.auto_scale.name
  policy_arn = aws_iam_policy.auto_scale.arn
}