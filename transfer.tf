resource "aws_transfer_server" "sftp" {
  identity_provider_type = "API_GATEWAY"
  invocation_role        = module.TransferIdentityProvider-IAM.iamRoleArn
  url                    = aws_api_gateway_stage.custom_identity.invoke_url
  logging_role           = aws_iam_role.TransferCWLogging-IAM.arn
  endpoint_type          = var.publicAccessible ? "PUBLIC" : "VPC_ENDPOINT"
  domain                 = upper(var.storageBackend)
  dynamic "endpoint_details" {
    for_each = var.publicAccessible ? [] : [1]
    content {
      vpc_endpoint_id = aws_vpc_endpoint.transfer[*].id
    }
  }
}
