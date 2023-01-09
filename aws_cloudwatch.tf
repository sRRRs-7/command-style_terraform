
####################################################
# cloud watch
####################################################
resource "aws_cloudwatch_log_group" "nginx" {
    name = "/ecs/nginx"
    retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "nextjs" {
    name = "/ecs/nextjs"
    retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "api" {
    name = "/ecs/api"
    retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "postgres" {
    name = "/ecs/postgres"
    retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "redis" {
    name = "/ecs/redis"
    retention_in_days = 14
}