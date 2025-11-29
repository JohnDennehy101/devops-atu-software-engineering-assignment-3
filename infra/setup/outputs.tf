output "cd_user_access_key_id" {
  description = "AWS key ID for continuous deployment (CD) user"
  value       = aws_iam_access_key.cd.id
}

output "cd_user_access_key_secret" {
  description = "AWS key secret for continuous deployment (CD) user"
  value       = aws_iam_access_key.cd.secret
  sensitive   = true
}

output "ecr_repo_frontend" {
  description = "ECR repo url for image which will contain frontend code"
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecr_repo_backend" {
  description = "ECR repo url for image which will contain backend code"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_repo_prometheus" {
  description = "ECR repo url for Prometheus image"
  value       = aws_ecr_repository.prometheus.repository_url
}

output "ecr_repo_grafana" {
  description = "ECR repo url for Grafana image"
  value       = aws_ecr_repository.grafana.repository_url
}
