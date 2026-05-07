# Allows the Nullstone agent to push container images to ECR.
# Created only when `package_type = "Image"`.

locals {
  create_image_pusher = var.package_type == "Image"
}

resource "aws_iam_role" "image_pusher" {
  count = local.create_image_pusher ? 1 : 0

  name               = "image-pusher-${local.resource_name}"
  tags               = var.tags
  assume_role_policy = data.aws_iam_policy_document.image_pusher_assume.json
}

data "aws_iam_policy_document" "image_pusher_assume" {
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

resource "aws_iam_role_policy" "image_pusher" {
  count = local.create_image_pusher ? 1 : 0

  role   = aws_iam_role.image_pusher[0].id
  policy = data.aws_iam_policy_document.image_pusher.json
}

data "aws_iam_policy_document" "image_pusher" {
  statement {
    sid    = "AllowPushPull"
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:ListImages",
    ]

    resources = [var.ecr_repository_arn]
  }

  statement {
    sid       = "AllowAuthorization"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}
