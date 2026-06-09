#!/bin/bash

PROJECT_ROOT=$(dirname "$0")
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
