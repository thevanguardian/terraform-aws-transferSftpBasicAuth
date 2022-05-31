resource "aws_api_gateway_account" "custom_identity" {
  cloudwatch_role_arn = module.APICloudWatchLogs-IAM.iamRoleArn
}
resource "aws_api_gateway_rest_api" "custom_identity" {
  name        = var.apiGatewayName
  description = "API used for Transfer Family to access user information in Secrets Manager and Parameter Store"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
resource "aws_api_gateway_deployment" "custom_identity" {
  rest_api_id = aws_api_gateway_rest_api.custom_identity.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.servers,
      aws_api_gateway_resource.serverid,
      aws_api_gateway_resource.users,
      aws_api_gateway_resource.username,
      aws_api_gateway_resource.config,
      aws_api_gateway_method.get_user_config,
      aws_api_gateway_integration.get_user_config,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_api_gateway_stage" "custom_identity" {
  rest_api_id   = aws_api_gateway_rest_api.custom_identity.id
  deployment_id = aws_api_gateway_deployment.custom_identity.id
  stage_name    = "prod"
  lifecycle {
    ignore_changes = [
      cache_cluster_size
    ]
  }
}
resource "aws_api_gateway_method_settings" "custom_identity" {
  rest_api_id = aws_api_gateway_rest_api.custom_identity.id
  stage_name  = aws_api_gateway_stage.custom_identity.stage_name
  method_path = "*/*"

  settings {
    logging_level          = "INFO"
    data_trace_enabled     = false
    throttling_burst_limit = "5000"
    throttling_rate_limit  = "10000"
  }
}
resource "aws_api_gateway_resource" "servers" {
  rest_api_id = aws_api_gateway_rest_api.custom_identity.id
  parent_id   = aws_api_gateway_rest_api.custom_identity.root_resource_id
  path_part   = "servers"
}
resource "aws_api_gateway_resource" "serverid" {
  rest_api_id = aws_api_gateway_rest_api.custom_identity.id
  parent_id   = aws_api_gateway_resource.servers.id
  path_part   = "{serverId}"
}
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.custom_identity.id
  parent_id   = aws_api_gateway_resource.serverid.id
  path_part   = "users"
}
resource "aws_api_gateway_resource" "username" {
  rest_api_id = aws_api_gateway_rest_api.custom_identity.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{username}"
}
resource "aws_api_gateway_resource" "config" {
  rest_api_id = aws_api_gateway_rest_api.custom_identity.id
  parent_id   = aws_api_gateway_resource.username.id
  path_part   = "config"
}
resource "aws_api_gateway_model" "get_user_config_response" {
  rest_api_id  = aws_api_gateway_rest_api.custom_identity.id
  name         = "UserConfigResponseModel"
  description  = "API Response for GetUserConfig method"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    type      = "object"
    title     = "UserUserConfig"
    properties = {
      Policy = {
        type = "string"
      }
      Role = {
        type = "string"
      }
      HomeDirectory = {
        type = "string"
      }
      PublicKeys = {
        type = "array"
        items = {
          type = "string"
        }
      }
    }
  })
}
resource "aws_api_gateway_method" "get_user_config" {
  rest_api_id   = aws_api_gateway_rest_api.custom_identity.id
  resource_id   = aws_api_gateway_resource.config.id
  authorization = "AWS_IAM"
  http_method   = "GET"
  request_parameters = {
    "method.request.header.Password" = "false"
  }
}
resource "aws_api_gateway_integration" "get_user_config" {
  rest_api_id             = aws_api_gateway_rest_api.custom_identity.id
  resource_id             = aws_api_gateway_resource.config.id
  http_method             = aws_api_gateway_method.get_user_config.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.get_user_config.invoke_arn
  request_templates = {
    "application/json" = <<-EOF
      {
        "username": "$util.urlDecode($input.params('username'))",
        "password": "$util.escapeJavaScript($input.params('Password')).replaceAll("\\'","'")",
        "protocol": "$input.params('protocol')",
        "serverId": "$input.params('serverId')",
        "sourceIp": "$input.params('sourceIp')"
      }
    EOF
  }
}
resource "aws_api_gateway_integration_response" "get_user_config" {
  rest_api_id = aws_api_gateway_rest_api.custom_identity.id
  resource_id = aws_api_gateway_resource.config.id
  http_method = aws_api_gateway_method.get_user_config.http_method
  status_code = aws_api_gateway_method_response.get_user_config.status_code
}
resource "aws_api_gateway_method_response" "get_user_config" {
  rest_api_id = aws_api_gateway_rest_api.custom_identity.id
  resource_id = aws_api_gateway_resource.config.id
  http_method = aws_api_gateway_method.get_user_config.http_method
  status_code = "200"

  response_models = {
    "application/json" = "UserConfigResponseModel"
  }
}
