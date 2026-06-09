# plat-converter – Terraform Infrastructure

Provisions the full AWS stack that was previously run by hand in `history.txt`.

## Architecture

```
Internet
   │
   ▼
[ALB :80]  ──→  [Target Group :8080]
                        │
              ┌─────────┴─────────┐
              ▼                   ▼
         [ECS Task]          [ECS Task]    (Fargate, desired=2)
         eu-north-1a         eu-north-1b
              │                   │
              └──── [ECS SG] ─────┘
                  (only ALB SG may reach :8080)
```

## Resources created

| File | Resources |
|---|---|
| `ecr.tf` | ECR repository |
| `vpc.tf` | VPC, 2 public subnets, IGW, default route table, ALB SG, ECS SG |
| `iam.tf` | ECS task execution role + `AmazonECSTaskExecutionRolePolicy` |
| `cloudwatch.tf` | CloudWatch log group `/ecs/plat-converter` |
| `alb.tf` | ALB, target group, HTTP :80 listener |
| `ecs.tf` | ECS cluster, task definition, ECS service |

## Usage

### 1. Prerequisites
- [Terraform ≥ 1.5](https://developer.hashicorp.com/terraform/downloads)
- AWS credentials configured (`aws configure` or environment variables)

### 2. Deploy

```bash
cd terraform

terraform init
terraform plan
terraform apply
```

### 3. Build & push your image

After `apply`, grab the ECR URL from the output and push your image:

```bash
ECR_URL=$(terraform output -raw ecr_repository_url)
AWS_REGION=eu-north-1

# Authenticate Docker to ECR
aws ecr get-login-password --region $AWS_REGION \
  | docker login --username AWS --password-stdin $ECR_URL

# Build, tag, push
docker build --platform linux/amd64 -t plat-converter . -f env/Dockerfile
docker tag plat-converter:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

Or simply run `./build-and-push.sh` to handle authentication and image pushing.

### 4. Force a new deployment (rolling update)

```bash
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service  $(terraform output -raw ecs_service_name) \
  --force-new-deployment
```

### 5. Tear down

Follow these steps in order to avoid dependency errors during destroy.

#### Step 1 – Scale the ECS service to zero

This drains all running tasks gracefully before any networking resources are removed.

```bash
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service  $(terraform output -raw ecs_service_name) \
  --desired-count 0 \
  --region eu-north-1
```

Wait until no tasks are running:

```bash
aws ecs wait services-stable \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw ecs_service_name) \
  --region eu-north-1
```

#### Step 2 – Destroy all infrastructure

`force_delete = true` is already set on the ECR repository, so Terraform will
delete it along with any images it contains.

```bash
terraform destroy
```

Review the plan Terraform prints and type `yes` to confirm.

#### Step 3 – Verify nothing remains

```bash
# ECS cluster should be gone
aws ecs describe-clusters \
  --clusters plat-converter-cluster \
  --region eu-north-1 \
  --query 'clusters[0].status'

# ECR repo should be gone
aws ecr describe-repositories \
  --repository-names plat-converter \
  --region eu-north-1 2>&1 | grep -i 'does not exist\|RepositoryNotFoundException'

# ALB should be gone
aws elbv2 describe-load-balancers \
  --names plat-converter-alb \
  --region eu-north-1 2>&1 | grep -i 'does not exist\|LoadBalancerNotFoundException'
```

All three commands should return a "not found" message confirming clean removal.

## Variables

Override any default by creating a `terraform.tfvars` file:

```hcl
app_name           = "plat-converter"
aws_region         = "eu-north-1"
desired_count      = 2
container_port     = 8080
task_cpu           = "256"
task_memory        = "512"
log_retention_days = 30
```
