#bin/sh
# 開発環境と本番環境のリソースの違いを確認するために使用

colordiff src/$1/main.tf src/$2/main.tf
colordiff src/$1/variables.tf src/$2/variables.tf
colordiff src/$1/output.tf src/$2/output.tf