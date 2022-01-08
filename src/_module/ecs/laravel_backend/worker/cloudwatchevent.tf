# ===================================================================
# cloud watch event

# worker を毎分ごとに立ち上げている。
# 立ち上げ時にコマンドが実行されるので結果としてcommandが実行される(heroku側でも毎分コマンドを叩いている仕組み)
# いつ実行されるかはapplication側で制御している
# ===================================================================
# app側のcommand実行
data "template_file" "php_artisan_schedule" {
  template = file("../_module/ecs/laravel_backend/worker/ecs_container_overrides.json")

  vars = {
    command = "schedule:run"
    # option  = "--tries=1"
  }
}

# 毎分ごとにworkerを起動するルールを定義
resource "aws_cloudwatch_event_rule" "schedule" {
  description         = "run php artisan schedule every minutes"
  is_enabled          = true
  name                = "schedule_every_minutes"
  schedule_expression = "cron(* * * * ? *)"
}

# workerを毎分操作するためにcloud watch event で司令している
resource "aws_cloudwatch_event_target" "schedule" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  arn       = var.cluster_arn
  target_id = "schedule"
  role_arn  = aws_iam_role.ecs_events_run_task.arn
  input     = data.template_file.php_artisan_schedule.rendered

  ecs_target {
    launch_type         = "FARGATE"
    task_count          = 1
    task_definition_arn = replace(aws_ecs_task_definition.main.arn, "/:[0-9]+$/", "")

    network_configuration {
      security_groups = var.sg_list
      subnets         = var.placement_subnet
    }
  }
}
