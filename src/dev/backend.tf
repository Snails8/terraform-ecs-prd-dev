## CI/CD で使用 (無駄な使用を避けるためあえてコメントアウトしている)
#terraform {
#  # backend s3を指定するとtf.stateがs3に勝手に上がる
#  backend "s3" {
#    # S3 bucket作成：aws s3 mb s3://tfstate-${var.app_name}
#    # bucket="tfstate-${var.app_name}"
#    bucket = "バケット名を指定"
#    key    = "terraform.tfstate"
#    region = "ap-northeast-1"
#
#  }
#  required_providers {
#    aws = {
#      source  = "hashicorp/aws"
#      version = "~> 3.27"
#    }
#  }
#  required_version = ">= 0.14.9"
#}