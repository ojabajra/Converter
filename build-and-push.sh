#!/bin/bash

PROJECT_ROOT=$(cd "$(dirname "$0")" && pwd)
cd "$PROJECT_ROOT/terraform"
ECR_URL=$(terraform output -raw ecr_repository_url)
cd "$PROJECT_ROOT"

# Login
# ECR URL format: <account>.dkr.ecr.<region>.amazonaws.com/<repo>
AWS_REGION=$(echo "$ECR_URL" | cut -d. -f4)

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_URL"

# Build & push (run from the project root where env/Dockerfile lives)
docker build --platform linux/amd64 -t plat-converter . -f ./env/Dockerfile
docker tag plat-converter:latest $ECR_URL:latest
docker push $ECR_URL:latest

read -r -p "Force a new ECS deployment? [y/N] " REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
  cd "$PROJECT_ROOT/terraform"
  aws ecs update-service \
    --no-cli-pager \
    --cluster $(terraform output -raw ecs_cluster_name) \
    --service  $(terraform output -raw ecs_service_name) \
    --force-new-deployment
  echo "Deployment triggered."
else
  echo "Skipping deployment."
fi
