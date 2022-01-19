resource "aws_api_gateway_rest_api" "hash_check" {
  name = "${var.service}-${var.environment}"
  description = "API gateway for the bcrypt hash check service"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "hash_check_resource" {
  rest_api_id = aws_api_gateway_rest_api.hash_check.id
  parent_id   = aws_api_gateway_rest_api.hash_check.root_resource_id
  path_part   = "hashcheck"
}

resource "aws_api_gateway_method" "hash_check_method" {
  rest_api_id   = aws_api_gateway_rest_api.hash_check.id
  resource_id   = aws_api_gateway_resource.hash_check_resource.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.hash_check.id
  resource_id             = aws_api_gateway_resource.hash_check_resource.id
  http_method             = aws_api_gateway_method.hash_check_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.hash_check.invoke_arn
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.hash_check.id
  resource_id = aws_api_gateway_resource.hash_check_resource.id
  http_method = aws_api_gateway_method.hash_check_method.http_method
  status_code = "200"
  response_models = {
    "text/plain" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "hash_check_integration_response" {
  depends_on = [
    aws_api_gateway_integration.integration
  ]
  rest_api_id = aws_api_gateway_rest_api.hash_check.id
  resource_id = aws_api_gateway_resource.hash_check_resource.id
  http_method = aws_api_gateway_method.hash_check_method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
  response_templates = {
    "text/plain" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.body
EOF
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.integration,
    aws_api_gateway_integration_response.hash_check_integration_response,
    aws_api_gateway_method_response.response_200
  ]

  rest_api_id = aws_api_gateway_rest_api.hash_check.id
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = var.environment
  rest_api_id   = aws_api_gateway_rest_api.hash_check.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}

resource "aws_api_gateway_api_key" "hash_check_key" {
  name = "${var.service}-${var.environment}-key"
  description = "API key for accessing the ${var.service} gateway, this is auto generated by AWS"
}

resource "aws_api_gateway_usage_plan" "hash_check_usage_plan" {
  name = "${var.service}-${var.environment}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.hash_check.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.hash_check_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.hash_check_usage_plan.id
}

output "api_key" {
  value = aws_api_gateway_api_key.hash_check_key.value
}