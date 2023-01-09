# ECR CLIMAKEFILE_DIR = $(dir $(lastword $(MAKEFILE_LIST)))
AWS_REGION=ap-northeast-1
IMAGE_NAME=go_api
CONTAINER_NAME=go_api
DOCKER_FILE=../server

init:
	terraform init
	# docker-compose run --rm terraform init
validate:
	terraform validate
	# docker-compose run --rm terraform validate
fmt:
	terraform fmt -recursive --diff
	# docker-compose run --rm terraform fmt -recursive --diff
plan:
	terraform plan
	# docker-compose run --rm terraform plan
apply:
	terraform apply -auto-approve
	# docker-compose run --rm terraform apply -auto-approve
destroy:
	terraform destroy -auto-approve
	# docker-compose run --rm terraform destroy -auto-approve
console:
	terraform console
	# docker-compose run --rm terraform console
show:
	terraform show
	# docker-compose run --rm terraform show
graph:
	terraform graph | dot -Tpng > graph.png

.PHONY: init, validate, plan, apply, destroy, fmt, console, show

# RDS
pg_instance:
	aws rds describe-orderable-db-instance-options \
	--engine postgres \
	--engine-version 13.7 \
	--query 'OrderableDBInstanceOptions[].[DBInstanceClass,StorageType,Engine,EngineVersion]' \
	--output table \
	--region ap-northeast-1
aurora_instance:
	aws rds describe-orderable-db-instance-options \
	--engine aurora-postgresql \
	--engine-version 13.7 \
	--query 'OrderableDBInstanceOptions[].[DBInstanceClass,StorageType,Engine,EngineVersion]' \
	--output table \
	--region ap-northeast-1
rm_instance:
	aws rds delete-db-instance \
    --db-instance-identifier rds-insttance-1 \
    --skip-final-snapshot \
    --no-delete-automated-backups

.PHONY: pg_instance, aurora_instance


# ECR
list:
	aws ecr describe-repositories
login:
	aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 234660340542.dkr.ecr.ap-northeast-1.amazonaws.com
log:
	aws ecs describe-tasks --cluster command-style-cluster --tasks 89bbcc403b624e7484a0e820645c68c7

# ECS
ecs_list:
	aws ecs list-clusters
ecs_debug:
	aws ecs list-tasks --cluster ECS-Cluster --desired-status STOPPED
ecs_task:
	aws ecs describe-tasks --cluster ECS-Cluster --tasks bcae2564178f4fcaab09f206d3fe9e70

# nginx
repo_nginx:
	aws ecr create-repository --repository-name nginx
# docker-compose up -d
tag_nginx:
	docker tag server-nginx:latest 234660340542.dkr.ecr.ap-northeast-1.amazonaws.com/nginx:latest
push_nginx:
	docker push 234660340542.dkr.ecr.ap-northeast-1.amazonaws.com/nginx:latest

# front
repo_next:
	aws ecr create-repository --repository-name next_app
# docker-compose up -d
tag_next:
	docker tag server-nextjs:latest 234660340542.dkr.ecr.ap-northeast-1.amazonaws.com/next_app:latest
push_next:
	docker push 234660340542.dkr.ecr.ap-northeast-1.amazonaws.com/next_app:latest

# api
repo_api:
	aws ecr create-repository --repository-name go_api
# docker-compose up -d
tag_api:
	docker tag server-api:latest 234660340542.dkr.ecr.ap-northeast-1.amazonaws.com/go_api:latest
push_api:
	docker push 234660340542.dkr.ecr.ap-northeast-1.amazonaws.com/go_api:latest

# postgres
repo_pg:
	aws ecr create-repository --repository-name postgres
# docker-compose up -d
tag_pg:
	docker tag server-postgres:latest 234660340542.dkr.ecr.ap-northeast-1.amazonaws.com/postgres:latest
push_pg:
	docker push 234660340542.dkr.ecr.ap-northeast-1.amazonaws.com/postgres:latest


# curl
http:
	curl -I app.command-style.com
https:
	curl -I https://app.command-style.com

