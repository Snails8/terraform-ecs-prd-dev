# ==============================================================
# SQS
# ==============================================================
resource "aws_sqs_queue" "terraform_queue" {
  name                      = "${var.app_name}-sqs"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400  # SQSがメッセージを保持する秒数
  receive_wait_time_seconds = 10     # ReceiveMessage呼び出しがメッセージが到着するまで待機する時間（ロングポーリング）。0から20（秒）までの整数


  # エラーハンドリング周り
  # https://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html
  #  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.terraform_queue_deadletter.arn}\",\"maxReceiveCount\":4}" # デッドレターキュー(詳しくはAWS)

  #  一旦コメントアウト
#  redrive_policy = jsonencode({
#    deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
#    maxReceiveCount     = 4
#  })
#  redrive_allow_policy = jsonencode({
#    redrivePermission = "byQueue",
#    sourceQueueArns   = ["${aws_sqs_queue.terraform_queue_deadletter.arn}"]
#  })

  tags = {
    Environment = "production"
  }
}


# ==============================================================
# High-throughput FIFO queue
# ==============================================================
resource "aws_sqs_queue" "terraform_queue" {
  name                        = "terraform-example-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}

# ==============================================================
# ==============================================================
resource "aws_sqs_queue" "terraform_queue" {
  name                              = "terraform-example-queue"
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}