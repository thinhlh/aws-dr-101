# AWS DRS Terrafrom

```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=

tf init -backend-config="bucket="
tf plan --var-file .tfvars
tf apply --var-file .tfvars
```
