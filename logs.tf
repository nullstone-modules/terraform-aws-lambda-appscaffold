module "logs" {
  source  = "nullstone-modules/logs/aws"
  version = "~> 0.3.0"

  // NOTE: This name must be `/aws/lambda/{function_name}` to properly collect logs from the function.
  name                       = "/aws/lambda/${local.resource_name}"
  tags                       = var.tags
  log_reader_type            = "role"
  log_reader_role_principals = var.op_assumer_arns
  enable_get_metrics         = true
  retention_in_days          = var.log_retention_in_days
}
