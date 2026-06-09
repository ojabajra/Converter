# ECR repository that holds the application image.
# The history.txt pushed to this repo; Terraform now owns its lifecycle.
resource "aws_ecr_repository" "app" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true   # allows `terraform destroy` to delete the repo even if images exist

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.app_name
  }
}
