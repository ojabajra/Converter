#!/bin/bash
#
PROJECT_ROOT=$(cd "$(dirname "$0")" && pwd)
cd "$PROJECT_ROOT/terraform"
aws ecs update-service \
  --no-cli-pager \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service  $(terraform output -raw ecs_service_name) \
  --desired-count 0 \
  --region eu-north-1

aws ecs wait services-stable \
  --no-cli-pager \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw ecs_service_name) \
  --region eu-north-1

terraform destroy -auto-approve
