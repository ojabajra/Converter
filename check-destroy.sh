#!/bin/bash
#
APP_NAME=plat-converter

aws ecs list-clusters
aws elbv2 describe-load-balancers
aws ecr describe-repositories
aws iam list-roles --query "Roles[?contains(RoleName, '${APP_NAME}')]"
