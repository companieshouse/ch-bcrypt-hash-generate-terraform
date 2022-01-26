locals {
  lambda_function_name = "${var.service}-${var.environment}"
}

resource "aws_lambda_function" "hash_generate" {
  depends_on = [
    aws_cloudwatch_log_group.hash_generate,
    aws_iam_role.lambda_execution
  ]

  function_name = local.lambda_function_name
  s3_bucket     = var.release_bucket_name
  s3_key        = var.release_artifact_key
  role          = aws_iam_role.lambda_execution.arn
  handler       = var.lambda_handler_name
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout_seconds
  runtime       = var.lambda_runtime

  tags = {
    Name        = local.lambda_function_name
    Environment = var.environment
    Service     = var.service
  }
}

resource "aws_cloudwatch_log_group" "hash_generate" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = var.lambda_logs_retention_days
}

resource "aws_iam_role" "lambda_execution" {
  name               = "${var.service}-${var.environment}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    sid = "LambdaCanAssumeThisRole"

    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowApiToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = local.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # source_arn = "${aws_api_gateway_rest_api.hash_generate.execution_arn}/*/*/*"
}

data "aws_iam_policy" "logging" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = data.aws_iam_policy.logging.arn
}
