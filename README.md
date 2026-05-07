# terraform-aws-lambda-appscaffold

An OpenTofu module that scaffolds IAM and cloud resources for an AWS Lambda function (executor IAM role with secrets-read inline policy, KMS key, CloudWatch log group via `nullstone-modules/logs/aws`, deployer IAM role, and — for `Image` packaging — an image-pusher IAM role).

The caller owns the Lambda function itself, the source storage (S3 artifacts bucket for `Zip` packaging, ECR repo for `Image` packaging), networking, secrets, and capability wiring; this module concentrates the boilerplate IAM and KMS pieces that are otherwise duplicated between `aws-lambda-service` and `aws-lambda-container-service`.
