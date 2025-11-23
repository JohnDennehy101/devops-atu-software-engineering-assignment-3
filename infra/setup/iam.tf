##########################################################################
# IAM user for use in Github Actions pipelines for continuous deployment #
##########################################################################

resource "aws_iam_user" "cd" {
  name = "devops-sw-pipelines-assignment-3-cd"
}

resource "aws_iam_access_key" "cd" {
  user = aws_iam_user.cd.name
}

######################################################################
# Define policy to allow Terraform backend to S3 and DynamoDB access #
######################################################################

data "aws_iam_policy_document" "terraform_backend" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.terraform_state_bucket}"]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}/terraform-state-deploy/*",
      "arn:aws:s3:::${var.terraform_state_bucket}/terraform-state-deploy-env/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:*:*:table/${var.terraform_state_lock_table}"]
  }
}

resource "aws_iam_policy" "terraform_backend" {
  name        = "${aws_iam_user.cd.name}-terraform-s3-dynamodb"
  description = "Provide user with permissions for S3 and DynamoDB for Terraform backend"
  policy      = data.aws_iam_policy_document.terraform_backend.json
}

resource "aws_iam_user_policy_attachment" "terraform_backend" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.terraform_backend.arn
}

###############################################
# Define Policy for ECR access for CI/CD user #
###############################################

data "aws_iam_policy_document" "ecr" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
    resources = [
      aws_ecr_repository.frontend.arn,
      aws_ecr_repository.backend.arn,
    ]
  }
}

resource "aws_iam_policy" "ecr" {
  name        = "${aws_iam_user.cd.name}-ecr"
  description = "Enable CI/CD user to manage ECR resources"
  policy      = data.aws_iam_policy_document.ecr.json
}

resource "aws_iam_user_policy_attachment" "ecr" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.ecr.arn
}
