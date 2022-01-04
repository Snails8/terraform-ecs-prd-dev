# usage:
# $ make init-(dev or prod or etc.)
# $ make plan-(dev or prod or etc.)
# $ make apply-(dev or prod or etc.)
include .env

DC := docker-compose exec terraform
ENV_PROD := .env.production
ENV_GITHUB := .env.github

SCOPE := src
CD = [[ -d $(SCOPE) ]] && cd $(SCOPE)

.PHONY: all init

up:
	docker-compose up -d --build

# aws cliは入っておく。
ecr-repo:
	aws ecr create-repository --repository-name $(TF_VAR_APP_NAME)-app
	aws ecr create-repository --repository-name $(TF_VAR_APP_NAME)-nginx

ssm-store:
	sh ssm-put.sh $(TF_VAR_APP_NAME) .env.production && \
	sh ssm-put.sh $(TF_VAR_APP_NAME) .env

all:
	@more Makefile

init-%:
	@[[ -d $(SCOPE)/${@:init-%=%} ]] && \
	cd $(SCOPE)/${@:init-%=%}  && \
	DC terraform init

plan-%:
	@[[ -d $(SCOPE)/${@:plan-%=%} ]] && \
	cd $(SCOPE)/${@:plan-%=%}  && \
	DC terraform plan

migrate-%:
	@[[ -d $(SCOPE)/${@:migrate-%=%} ]] && \
	cd $(SCOPE)/${@:migrate-%=%}  && \
	DC terraform init -migrate-state

apply-%:
	@[[ -d $(SCOPE)/${@:apply-%=%} ]] && \
	cd $(SCOPE)/${@:apply-%=%}  && \
	DC terraform apply

destroy-%:
	@[[ -d $(SCOPE)/${@:destroy-%=%} ]] && \
	cd $(SCOPE)/${@:destroy-%=%}  && \
	DC terraform destroy

outputs:
	@${DC} terraform output -json | ${DC} jq -r '"DB_HOST=\(.db_endpoint.value)"'  > $(ENV_PROD)  && \
	${DC} terraform output -json |  ${DC} jq -r '"REDIS_HOST=\(.redis_hostname.value[0].address)"' >> $(ENV_PROD)  && \
	${DC} terraform output -json |  ${DC} jq -r '"SUBNETS=\(.db_subnets.value)"' > $(ENV_GITHUB) && \
    ${DC} terraform output -json |  ${DC} jq -r '"SECURITY_GROUPS=\(.db_security_groups.value)"' >> $(ENV_GITHUB)