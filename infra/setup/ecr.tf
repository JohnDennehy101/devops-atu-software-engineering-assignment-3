resource "aws_ecr_repository" "frontend" {
  name                 = "devops-sw-pipelines-assignment-3-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    # TODO - reenable when submitting
    scan_on_push = false
  }
}

resource "aws_ecr_repository" "backend" {
  name                 = "devops-sw-pipelines-assignment-3-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    # TODO - reenable when submitting
    scan_on_push = false
  }
}

resource "aws_ecr_repository" "prometheus" {
  name                 = "devops-sw-pipelines-assignment-3-prometheus"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    # TODO - reenable when submitting
    scan_on_push = false
  }
}

resource "aws_ecr_repository" "grafana" {
  name                 = "devops-sw-pipelines-assignment-3-grafana"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    # TODO - reenable when submitting
    scan_on_push = false
  }
}
