resource "aws_appautoscaling_target" "main_ecs_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.dimensions_clusterName}/${var.dimensions_serviceName}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = data.aws_iam_role.ecs_service_autoscaling.arn
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
}

resource "aws_appautoscaling_policy" "main_scale_up" {
  name               = "main_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.dimensions_clusterName}/${var.dimensions_serviceName}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.main_ecs_target]
}

resource "aws_appautoscaling_policy" "main_scale_down" {
  name               = "main_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.dimensions_clusterName}/${var.dimensions_serviceName}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.main_ecs_target]
}

resource "aws_cloudwatch_metric_alarm" "main_cpu_high" {
  alarm_name          = "main_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    ClusterName = var.dimensions_clusterName
    ServiceName = var.dimensions_serviceName
  }

  alarm_actions = [aws_appautoscaling_policy.main_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "main_cpu_low" {
  alarm_name          = "main_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    ClusterName = var.dimensions_clusterName
    ServiceName = var.dimensions_serviceName
  }

  alarm_actions = [aws_appautoscaling_policy.main_scale_down.arn]
}

data "aws_iam_role" "ecs_service_autoscaling" {
  name = aws_iam_role.auto_scale.name
  #  name = "AWSServiceRoleForApplicationAutoScaling_ECSService"
}