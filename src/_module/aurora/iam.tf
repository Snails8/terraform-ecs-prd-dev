# ==============================================================
# IAM Roleで RDSの監視 を付与

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
# ==============================================================
resource "aws_iam_role" "postgresql" {
  name               = "${var.app_name}-aurora-monitoring-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "monitoring.rds.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
  tags = {
    Name    = "${var.app_name}-aurora-monitoring-role"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment
resource "aws_iam_policy_attachment" "aurora_monitoring_policy_attachment" {
  name       = "aurora_monitoring_policy_attachment"
  roles      = [aws_iam_role.postgresql.name]  # list
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}