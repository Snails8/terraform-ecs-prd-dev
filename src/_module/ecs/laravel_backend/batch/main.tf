# ===================================================================
# タスク定義
# ===================================================================
resource "aws_ecs_task_definition" "main" {
  family = "${var.app_name}-batch"

  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = data.template_file.batch_container_definitions.rendered

  volume {
    name = "app-storage"
  }

  task_role_arn      = var.iam_role_task_execution_arn
  execution_role_arn = var.iam_role_task_execution_arn
}

# ===================================================================
# サービス
# ===================================================================
resource "aws_ecs_service" "main" {
  #   depends_on = [aws_lb_listener_rule.main]
  name                   = "${var.app_name}-batch"
  enable_execute_command = true

  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  desired_count    = 1
  cluster          = var.cluster

  task_definition = aws_ecs_task_definition.main.arn
  # GitHubActionsと整合性を取りたい場合は下記のようにrevisionを指定しなければよい
  # task_definition = "arn:aws:ecs:ap-northeast-1:${local.account_id}:task-definition/${aws_ecs_task_definition.main.family}"

  network_configuration {
    subnets          = var.placement_subnet
    security_groups  = var.sg_list
    assign_public_ip = true
  }

  # lb の設定は不要
  # cloudmap を使うほどではなかったので一旦コメントアウト
  #  service_registries {
  #    registry_arn = var.service_registries_arn
  #  }

}

# ===================================================================
# Log
# ===================================================================
resource "aws_cloudwatch_log_group" "main" {
  name              = "/${var.app_name}/batch"
  retention_in_days = 7
}

# ===================================================================
# IAM Role の設定
# ===================================================================
data "aws_iam_policy_document" "events_assume_role" {
  statement {
    sid     = "CloudWatchEvents"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["events.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "ecs_events_run_task" {
  name               = "${var.app_name}-batch-ECSEventsRunTask"
  assume_role_policy = data.aws_iam_policy_document.events_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_events_run_task" {
  role       = aws_iam_role.ecs_events_run_task.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}
