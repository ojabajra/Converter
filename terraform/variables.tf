variable "app_name" {
  description = "Application name – used as a prefix for every resource."
  type        = string
  default     = "plat-converter"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-north-1"
}

variable "desired_count" {
  description = "Number of ECS task replicas to keep running."
  type        = number
  default     = 2
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)."
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = string
  default     = "512"
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days."
  type        = number
  default     = 30
}
