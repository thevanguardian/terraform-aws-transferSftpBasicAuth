module "S3BucketAccess-IAM" {
  count          = lower(var.storageBackend) == "s3" ? 1 : 0
  source = "thevanguardian/generateIamRole/aws"
  version = "2.0.1"
  roleNamePrefix = "S3BucketAccess-"
  rolePath       = "/service/transfer/"
  assumeConfig = {
    actions     = ["sts:AssumeRole"]
    type        = "Service"
    identifiers = ["transfer.amazonaws.com"]
  }
  scopedConfig = {
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.default_storage[*].arn,
      "${aws_s3_bucket.default_storage[*].arn}/*"
    ]
  }
}

module "EFSAccess-IAM" {
  count          = lower(var.storageBackend) == "efs" ? 1 : 0
  source = "thevanguardian/generateIamRole/aws"
  version = "2.0.1"
  roleNamePrefix = "EFSAccess-"
  rolePath       = "/service/transfer/"
  assumeConfig = {
    actions     = ["sts:AssumeRole"]
    type        = "Service"
    identifiers = ["transfer.amazonaws.com"]
  }
  scopedConfig = {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]
    resources = [
      aws_efs_file_system.efs_storage[0].arn
    ]
  }
}

module "TransferIdentityProvider-IAM" {
  source = "thevanguardian/generateIamRole/aws"
  version = "2.0.1"
  roleNamePrefix = "TransferIdentityProvider-"
  rolePath       = "/service/transfer/"
  assumeConfig = {
    actions     = ["sts:AssumeRole"]
    type        = "Service"
    identifiers = ["transfer.amazonaws.com"]
  }
  scopedConfig = {
    actions = [
      "execute-api:Invoke",
    ]
    resources = [
      "${aws_api_gateway_rest_api.custom_identity.execution_arn}/prod/GET/*"
    ]
  }
  unscopedConfig = {
    actions = [
      "apigateway:GET"
    ]
  }
}

module "APICloudWatchLogs-IAM" {
  source = "thevanguardian/generateIamRole/aws"
  version = "2.0.1"
  roleNamePrefix = "APICloudWatchLogs-"
  rolePath       = "/service/transfer/"
  assumeConfig = {
    actions     = ["sts:AssumeRole"]
    type        = "Service"
    identifiers = ["apigateway.amazonaws.com"]
  }
  unscopedConfig = {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]
  }
}

module "LambdaExecution-IAM" {
  source = "thevanguardian/generateIamRole/aws"
  version = "2.0.1"
  roleNamePrefix  = "LambdaExecution-"
  rolePath        = "/service/transfer/"
  managedPolicies = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
  assumeConfig = {
    actions     = ["sts:AssumeRole"]
    type        = "Service"
    identifiers = ["lambda.amazonaws.com"]
  }
  scopedConfig = {
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
      "ssm:GetParameter"
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:s-*",
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${trim(var.parameterStorePathPrefix, "/")}/*"
    ]
  }
}
resource "aws_iam_role" "TransferCWLogging-IAM" {
  name_prefix         = "TransferCWLogging-"
  assume_role_policy  = data.aws_iam_policy_document.transfer-cw.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

