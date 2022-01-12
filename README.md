# sample-terraform
![Image](.docs/ECS.drawio.png)
### 環境変数をsetする

---

1. .envに値をsetする
``` 
$ cp .env.example .env
```
``` 
注意
TF_VAR_APP_NAME -> 必ず対象アプリケーションのリポジトリ名にすること(小文字ハイフンつなぎ)
TF_VAR_DB_MASTER_NAME,TF_VAR_DB_MASTER_PASS  -> 共にハイフンは使用不可
TF_VAR_DB_NAME -> 文字列+数字にすること (ハイフン,文字列のみは使用不可)
TF_VAR_DOMAIN, TF_VAR_ZONE ->  Route53に登録してあるもの
TF_VAR_LOKI_USER, TF_VAR_LOKI_PASS -> なくても問題ない
```

2. public キーをセットする
```shell:
$ vim ec2/sample-ec2-key.pub
```

3. Creating s3-tf-bucket 
```shell
$ make s3_tfbackend
```

### TerraformでAWS環境のbuildする

---
1. Terraform の読み込みと環境の作成
```shell:
$ make up
$ make init 
$ make apply

> Apply complete! Resources: 54 added, 1 changed, 0 destroyed!
```

2. ビルドした AWS環境 の環境変数を SSM に設定する
```shell:
// .env.productionに値の書き込み
$ make outputs

> DB_HOST末尾のportだけ削除(:5432 の削除) 

// SSM (パラメーターストア)に値の登録
// .env.production にあるvalueを登録 or 上書き
$ make ssm-store     
```

3. ECRにイメージをpushする
```
// set ECR
$ make ecr-repo
``` 

### アプリケーション側の設定

---
1. .env.githubの環境変数を確認して環境変数を登録する
```shell:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_ACCOUNT_ID  *awsにlogin後、右上の画面を確認すると以下画像のように見れる
SUBNETS   *outputsで確認後 [] 内の内容のみを登録
SECURITY_GROUPS *outputsで確認して登録
LOKI_ID     *コメントアウトで不要
LOKI_SECRET *コメントアウトで不要
```

2. Task-definitionの環境の参照先を注意する
```json:
# SSM に値がある場合
{
    "name": "AWS_ACCESS_KEY_ID",
    "valueFrom": "/SED_TARGET_APP_NAME/ACCESS_KEY_ID"
},

# 登録していない場合
{
    "name": "APP_URL",
    "value": "https://snails8.site"
},
```

## 注意
Q  how to connect ec2 ?
```
$ ssh -i ~/.ssh/秘密鍵 ec2-user@IPアドレス
```

Q.  RDS instance failed to create 
please check .env value
```
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_CreateDBInstance.html
・1〜16文字の英数字とアンダースコアを含めることができます。
・その最初の文字は文字でなければなりません。
・データベースエンジンによって予約された単語にすることはできません。

✕: ハイフン(-), ✕:誰もが使いそうなusername=admin (すでに予約されているため)
```


## 運用 注意
- ドメインをRoute53に登録していないと怒られるので注意
- laravel_backend のgithub_iam に対象のアプリケーションリポジトリ名を追加


フロント側
- 必ずフロントエンドの locals = app_name -> フロント側のリポジトリ名 にしてください
- 先にRoute53にホストゾーンを設定してください
- frontend.tfのlocals内に必ずドメイン名を記載してください

## 懸念点
github-actionsでアプリケーションのdeployをしているため、task-definition が二重管理になってしまっている。

外部デプロイを利用すれば回避できるが以下の問題がある
- https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/userguide/deployment-type-external.html

対応策

・AWS Copilot を使用
https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/userguide/getting-started-aws-copilot-cli.html

・パイプラインの使用
https://zenn.dev/reireias/articles/8e987af2762eaa

理想
github-actions にCodePipelineをかませる


## Architecture
``` 
.
├── MakeFile
├── settings
│   ├── bin
│   │   └── sessionmanager-bundle  
│   │       └── bin : utilty for aws cli
│   └── template : container definition template file.
└── src
    ├── _module: Used for dev or prod envrionment
    │   ├── acm      *aws certificate manager
    │   ├── iam     
    │   ├── cloudmap 
    │   ├── ec2
    │   ├── ecs
    │   │   ├── cluster
    │   │   ├── frontend   :frontend container ,which connected to backend/app
    │   │   └── laravel_backend
    │   │       ├── app    : app + nginx (php-fpm)
    │   │       └── worker : worker (redis) 
    │   ├── elasticache   *redis
    │   ├── elb      
    │   ├── iam
    │   ├── network
    │   ├── rds     
    │   └── security_group
    │   └── ses
    │
    ├── dev : AWS Environment for dev.
    └── prod
```