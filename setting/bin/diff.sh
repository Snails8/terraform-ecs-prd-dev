#! /bin/bash
# 開発環境と本番環境のリソースの違いを確認するために使用
set -euC

REF=$1
TARGET=$2
echo $REF
SCOPE_REF=src/${REF}
SCOPE_TARGET=src/${TARGET}

colordiff ${SCOPE_REF}/main.tf ${SCOPE_TARGET}/main.tf
colordiff ${SCOPE_REF}/variables.tf ${SCOPE_TARGET}/variables.tf
colordiff ${SCOPE_REF}/output.tf ${SCOPE_TARGET}/output.tf     