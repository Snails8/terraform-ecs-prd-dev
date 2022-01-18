# ===================================================================
# cloud watch event

# laravel ではapp側でcron 判定をもたせることができるので定時処理には不要だが、Go とかで使えそうな考えなので残しておく

# worker を毎分ごとに立ち上げている。
# 立ち上げ時にコマンドが実行されるので結果としてcommandが実行される(heroku側でも毎分コマンドを叩いている仕組み)
# いつ実行されるかはapplication側で制御している
# ===================================================================
# app側のcommand実行
data "template_file" "php_artisan_schedule" {
  template = file("../_module/ecs/laravel_backend/worker/ecs_container_overrides.json")

  vars = {
    command = "inspire" # test 用
    #    command = "schedule:run"
    # option  = "--tries=1"
  }
}

# 毎分ごとにworkerを起動するルールを定義
resource "aws_cloudwatch_event_rule" "schedule" {
  description         = "run php artisan schedule at 0:00"
  is_enabled          = true
  name                = "schedule_every_days"
  #  schedule_expression = "cron(* * * * ? *)"
  schedule_expression = "cron(0 15 * * ? *)"  # 日本時間15+9-> 24(0)時に実行
}

# workerを毎分操作するためにcloud watch event で司令している
resource "aws_cloudwatch_event_target" "schedule" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  arn       = var.cluster_arn
  target_id = "worker" # worker の task 定義を書き換える
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
