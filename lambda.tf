resource "aws_lambda_function" "get_user_config" {
  filename      = data.archive_file.lambda_function.output_path
  function_name = "${local.common_name}_GetUserConfig"
  role          = module.LambdaExecution-IAM.iamRoleArn
  handler       = "index.lambda_handler"

  source_code_hash = filebase64sha256(data.archive_file.lambda_function.output_path)
  runtime          = "python3.7"
  timeout          = "3"

  environment {
    variables = {
      SecretStoreRegion        = data.aws_region.current.name
      ParameterStorePathPrefix = var.parameterStorePathPrefix
      EnabledSecretStore       = var.secretsBackend
    }
  }
  dynamic "file_system_config" {
    for_each = lower(var.storageBackend) == "efs" ? toset([var.storageBackend]) : []
    content {
      arn              = aws_efs_access_point.root[0].arn
      local_mount_path = "/mnt/efs"
    }
  }
  dynamic "vpc_config" {
    for_each = lower(var.storageBackend) == "efs" ? toset([var.storageBackend]) : []
    content {
      subnet_ids         = flatten(var.subnetIds)
      security_group_ids = [aws_security_group.lambda-efs[0].id]
    }
  }
  dynamic "tracing_config" {
    for_each = var.enableXrayTracing ? toset([var.enableXrayTracing]) : []
    content {
      mode = var.xrayTracingMode
    }
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowApiInvoke"
  action        = "lambda:invokeFunction"
  function_name = aws_lambda_function.get_user_config.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.custom_identity.execution_arn}/*"
}
