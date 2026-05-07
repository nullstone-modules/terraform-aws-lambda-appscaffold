output "executor" {
  value = {
    arn  = aws_iam_role.executor.arn
    name = aws_iam_role.executor.name
    id   = aws_iam_role.executor.id
  }
  description = "The Lambda execution IAM role. The Lambda function assumes this role at runtime; capability-layer policies should attach to its name."
}

output "kms_key" {
  value = {
    id  = aws_kms_key.this.id
    arn = aws_kms_key.this.arn
  }
  description = "KMS key used to encrypt the Lambda function and Secrets Manager secrets, and that grants CloudWatch Log encryption."
}

output "log_group" {
  value = {
    name = module.logs.name
    arn  = module.logs.arn
  }
  description = "CloudWatch log group for the Lambda function (`/aws/lambda/<resource_name>`)."
}

output "log_reader" {
  value       = module.logs.reader
  description = "An AWS User with explicit privilege to read logs from CloudWatch."
  sensitive   = true
}

output "deployer" {
  value = {
    role_arn         = aws_iam_role.deployer.arn
    session_duration = 3600
  }
  description = "IAM role with permissions to publish new Lambda versions (and, for `Zip` packaging, upload artifacts to the bucket; for `Image` packaging, the KMS grant needed for encrypted ECR pulls). Assumable by the principals in var.op_assumer_arns."
}

output "image_pusher" {
  value = {
    role_arn         = try(aws_iam_role.image_pusher[0].arn, "")
    session_duration = 900
  }
  description = "IAM role with ECR push/pull on the caller-owned ECR repo. Assumable by the principals in var.op_assumer_arns. role_arn is empty when var.package_type = \"Zip\"."
}
