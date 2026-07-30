# Allows the Nullstone agent to deploy new Lambda function versions,
# (for `Zip` packaging) upload artifacts to the S3 artifacts bucket,
# and invoke the function on behalf of `nullstone run`.

resource "aws_iam_role" "deployer" {
  name               = "deployer-${local.resource_name}"
  tags               = var.tags
  assume_role_policy = data.aws_iam_policy_document.deployer_assume.json
}

data "aws_iam_policy_document" "deployer_assume" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
      "sts:SetSourceIdentity",
    ]

    principals {
      type        = "AWS"
      identifiers = var.op_assumer_arns
    }
  }
}

resource "aws_iam_role_policy" "deployer" {
  role   = aws_iam_role.deployer.name
  policy = data.aws_iam_policy_document.deployer.json
}

locals {
  deployer_zip_statements = var.package_type == "Zip" ? [{
    bucket_arn = var.artifacts_bucket_arn
  }] : []

  deployer_image_statements = var.package_type == "Image" ? [{
    kms_key_arn = aws_kms_key.this.arn
  }] : []
}

data "aws_iam_policy_document" "deployer" {
  # `Zip` packaging: grant S3 access to the artifacts bucket.
  dynamic "statement" {
    for_each = local.deployer_zip_statements

    content {
      sid    = "AllowFindBucket"
      effect = "Allow"
      actions = [
        "s3:ListBucket",
        "s3:GetBucketLocation",
      ]
      resources = [statement.value.bucket_arn]
    }
  }

  dynamic "statement" {
    for_each = local.deployer_zip_statements

    content {
      sid    = "AllowEditObjects"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
      ]
      resources = ["${statement.value.bucket_arn}/*"]
    }
  }

  # Both packagings: pass-role on the executor and lambda update grants.
  statement {
    sid       = "AllowUpdatePassRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.executor.arn]
  }

  statement {
    sid    = "AllowLambdaDeploy"
    effect = "Allow"

    actions = [
      "lambda:GetFunctionConfiguration",
      "lambda:UpdateFunctionConfiguration",
      "lambda:UpdateFunctionCode",
      "lambda:PublishVersion",
    ]

    resources = [var.lambda_function_arn]
  }

  # `nullstone run` performs a synchronous invocation using these credentials.
  # The CLI invokes `$LATEST` today; the qualified ARN covers a published
  # version or alias, which only matches this function -- not its siblings.
  statement {
    sid     = "AllowLambdaInvoke"
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]

    resources = [
      var.lambda_function_arn,
      "${var.lambda_function_arn}:*",
    ]
  }

  # `Image` packaging: a container-based lambda needs a KMS grant to pull
  # images from the encrypted ECR repo on cold starts after a code update.
  dynamic "statement" {
    for_each = local.deployer_image_statements

    content {
      sid       = "AllowEditKmsEncryptedLambda"
      effect    = "Allow"
      resources = [statement.value.kms_key_arn]

      actions = [
        "kms:CreateGrant",
        "kms:GenerateDataKey",
      ]
    }
  }
}
