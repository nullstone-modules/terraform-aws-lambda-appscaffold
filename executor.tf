locals {
  resource_name = "${var.block_ref}-${var.resource_suffix}"
}

resource "aws_iam_role" "executor" {
  name               = local.resource_name
  assume_role_policy = data.aws_iam_policy_document.executor_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "executor_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "executor_basic" {
  role       = aws_iam_role.executor.name
  policy_arn = "arn:${var.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "executor_vpc" {
  role       = aws_iam_role.executor.name
  policy_arn = "arn:${var.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "executor" {
  role   = aws_iam_role.executor.id
  policy = data.aws_iam_policy_document.executor.json
}

locals {
  secret_statement_resources = length(var.secret_arns) > 0 ? [var.secret_arns] : []
}

data "aws_iam_policy_document" "executor" {
  statement {
    sid       = "AllowBasicSecretsListing"
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = local.secret_statement_resources

    content {
      sid       = "AllowReadSecrets"
      effect    = "Allow"
      resources = statement.value

      actions = [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt",
      ]
    }
  }
}
