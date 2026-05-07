resource "aws_kms_key" "this" {
  description         = "Encryption key for service ${local.resource_name}"
  enable_key_rotation = true
  is_enabled          = true
  tags                = var.tags
  policy              = data.aws_iam_policy_document.encryption_key.json
}

data "aws_iam_policy_document" "encryption_key" {
  #bridgecrew:skip=CKV_AWS_109: Skipping "Permissions management without constraints". False positive as this is attached as a key policy and is implicitly constrained by the key.
  #bridgecrew:skip=CKV_AWS_111: Skipping "Write IAM policies without constraints". False positive as this is attached as a key policy and is implicitly constrained by the key.
  #bridgecrew:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions". False positive as this is attached as a key policy and implicitly constrained by the key.
  statement {
    sid       = "Enable IAM User permissions"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${var.partition}:iam::${var.account_id}:root"]
    }
  }

  statement {
    sid       = "Enable Cloudwatch Log encryption"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${var.partition}:logs:${var.region}:${var.account_id}:*"]
    }
  }

  statement {
    sid       = "Enable App Decrypt secrets"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:Decrypt"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.executor.arn]
    }
  }
}
