# usage:
# $ make init-(dev or prod or etc.)
# $ make plan-(dev or prod or etc.)
# $ make apply-(dev or prod or etc.)
include .env
SRC := $1

DC := docker-compose exec terraform
ENV_PROD := .env.production
ENV_GITHUB := .env.github

TF_STATE_BUCKET := tfstate-${APP_NAME}-${SRC}
#TR_INIT_OPTION := -reconfigure -reconfigure -backend-config="bucket=${TF_STATE_BUCKET}"  \
#           -backend-config="key=terraform.tfstate.${SRC}" \
#          -backend-config="region=ap-northeast-1"

# ==========================================================
# 環境切り替え処理    *本番では make [cmd] SRC=prod とする(space注意)
# ==========================================================
ENV=dev

pre:
ifdef SRC
ENV=${SRC}
endif

SET_ENV := export ENV=$(ENV) ;\
           export COMPOSE_PATH_SEPARATOR=: ;\
           export COMPOSE_FILE=docker-compose.$(ENV).yml
# ==========================================================
# make コマンド (SRC=prod が必要な場合のみoption で加える)

# ymlに値を渡すために.envをセット
up:
	docker-compose up -d --build

terraform:
	docker-compose exec terraform /bin/ash

init: pre
	${SET_ENV} && \
	${DC} terraform init

plan: pre
	${SET_ENV} && \
	${DC} terraform init && \
	${DC} terraform plan

migrate: pre
	${SET_ENV} && \
	${DC} terraform init -migrate-state

apply: pre
	${SET_ENV} && \
	${DC} terraform init ${TR_INIT_OPTION} && \
	${DC} terraform apply

destroy: pre
	${SET_ENV} && \
	${DC} terraform init && \
	${DC} terraform destroy

# aws cliは入っておく。
ecr-repo:
	aws ecr create-repository --repository-name $(TF_VAR_APP_NAME)-app
	aws ecr create-repository --repository-name $(TF_VAR_APP_NAME)-nginx

ssm-store:
	sh ./setting/bin/ssm-put.sh $(TF_VAR_APP_NAME) .env.production && \
	sh ./setting/bin/ssm-put.sh $(TF_VAR_APP_NAME) .env

# SSM / Github SECRETに登録する値の用意
outputs:
	${SET_ENV} && \
	${DC} terraform output -json |  ${DC} jq -r '"DB_HOST=\(.db_endpoint.value)"'  > $(ENV_PROD)  && \
	${DC} terraform output -json |  ${DC} jq -r '"REDIS_HOST=\(.redis_hostname.value[0].address)"' >> $(ENV_PROD)  && \
	${DC} terraform output -json |  ${DC} jq -r '"SUBNETS=\(.db_subnets.value)"' > $(ENV_GITHUB) && \
    ${DC} terraform output -json |  ${DC} jq -r '"SECURITY_GROUPS=\(.db_security_groups.value)"' >> $(ENV_GITHUB)

s3_tfbackend:
	# S3 bucket作成 versioning機能追加
	aws s3 mb s3://${TF_STATE_BUCKET}&& \
	aws s3api put-bucket-versioning --bucket ${TF_STATE_BUCKET} --versioning-configuration Status=Enabled
