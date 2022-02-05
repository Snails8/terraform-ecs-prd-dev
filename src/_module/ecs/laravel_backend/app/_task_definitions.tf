#data "template_file" "container_definitions" {
#  template = jsonencode(local.ecs_tasks)
#}

locals {
  ecs_tasks = [{
    name      = "nginx" // var.entry_container_name
    image     = "${local.account_id}.dkr.${local.region}.amazonaws.com/${var.app_name}-nginx:latest"
    essential = true
    memory    = 256
    cpu       = 256

    portMappings = [
      {
        containerPort = var.entry_container_port
        hostPort      = var.entry_container_port
        protocol      = "tcp"
      }
    ]
    linuxParameters = {
      initProcessEnabled = true
    }
    managedAgents = [
      {
        lastStartedAt = "2021-03-01T14:49:44.574000-06:00",
        name          = "ExecuteCommandAgent",
        lastStatus    = "RUNNING"
      }
    ]
    mountPoints = [
      {
        sourceVolume  = "app-storage",
        containerPath = "/app"
      }
    ]
    logconfiguration = [
      {
        logDriver = "awslogs",
        options = {
          awslogs-region        = "ap-northeast-1",
          awslogs-group         = "/${var.app_name}/ecs",
          awslogs-stream-prefix = "${var.app_name}-app"
        }
      }
    ]


    "environment": [
      {
        name  = "APP_NAME",
        value = "laravel-api"
      },
      {
        name  = "APP_ENV",
        value = "production"
      },
      {
        name  = "APP_SCHEME",
        value = "https"
      },
      {
        name  = "APP_DEBUG",
        value = "false"
      },
      {
        name  = "APP_URL",
        value = "https://snails8.site"
      },
      {
        name  = "AWS_BUCKET",
        value = "laravel-api-prod"
      },
      {
        name  = "AWS_DEFAULT_REGION",
        value = "ap-northeast-1"
      },
      {
        name  = "LANG",
        value = "ja_JP.UTF-8"
      },
      {
        name  = "TZ",
        value = "Asia/Tokyo"
      },
      {
        name  = "LOG_CHANNEL",
        value = "stderr"
      },
      {
        name  = "DB_PORT",
        value = "5432"
      },
      {
        name  = "DB_CONNECTION",
        value = "pgsql"
      },
      {
        name  = "SESSION_DRIVER",
        value = "redis"
      },
      {
        name  = "CACHE_DRIVER",
        value = "redis"
      },
      {
        name  = "QUEUE_DRIVER",
        value = "redis"
      },
      {
        name  = "QUEUE_CONNECTION",
        value = "redis"
      },
      {
        "name"  = "MAIL_DRIVER",
        "value" = "ses"
      },
      {
        "name"  = "MAIL_FROM_ADDRESS",
        "value" = "snails8d+ses@gmail.com"
      },
      {
        "name"  = "MAIL_FROM_NAME",
        "value" = "snail-test-email"
      },
      {
        "name"  = "SES_REGION",
        "value" = "ap-northeast-1"
      }
    ],

    secrets = [
      {
        name      = "APP_KEY",
        valueFrom = "${var.app_name}/APP_KEY"
      },
      {
        name      = "REDIS_HOST",
        valueFrom = "${var.app_name}/REDIS_HOST"
      },
      {
        name      = "DB_HOST",
        valueFrom = "${var.app_name}/DB_HOST"
      },
      {
        name      = "DB_DATABASE",
        valueFrom = "${var.app_name}/DB_NAME"
      },
      {
        name      = "DB_USERNAME",
        valueFrom = "${var.app_name}/DB_MASTER_NAME"
      },
      {
        name      = "DB_PASSWORD",
        valueFrom = "${var.app_name}/DB_MASTER_PASS"
      }
    ]

  }]

}