provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
}

# Pobranie istniejącej roli laboratoryjnej AWS Educate
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# --- 1. ZARZĄDZANIE SEKRETAMI (+0.5) ---
resource "aws_ssm_parameter" "db_password" {
  name        = "/myapp/db_password"
  type        = "SecureString"
  value       = var.db_password # Podawane bezpiecznie przez CI/CD lub plik tfvars
}

# --- 2. ZASOBY PODSTAWOWE (3.0) ---

# S3 Bucket
resource "aws_s3_bucket" "orders" {
  bucket_prefix = "order-processing-bucket-"
}

# SQS Queue
resource "aws_sqs_queue" "orders_queue" {
  name = "order-processing-queue"
}

# SNS Topic
resource "aws_sns_topic" "order_updates" {
  name = "order-updates-topic"
}

# --- 3. LAMBDA FUNKCJE Z WYKORZYSTANIEM MODUŁU (+0.5) ---

module "order_ingest" {
  source        = "./modules/lambda_function"
  function_name = "order-ingest"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  role_arn      = data.aws_iam_role.lab_role.arn
  source_dir    = "${path.module}/functions/order_ingest"
  
  environment_vars = {
    ORDER_BUCKET    = aws_s3_bucket.orders.id
    ORDER_QUEUE_URL = aws_sqs_queue.orders_queue.id
    DB_SECRET_NAME  = aws_ssm_parameter.db_password.name
  }
}

module "order_validator" {
  source        = "./modules/lambda_function"
  function_name = "order-validator"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  role_arn      = data.aws_iam_role.lab_role.arn
  source_dir    = "${path.module}/functions/order_validator"
}

module "order_processor" {
  source        = "./modules/lambda_function"
  function_name = "order-processor"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  role_arn      = data.aws_iam_role.lab_role.arn
  source_dir    = "${path.module}/functions/order_processor"
  
  environment_vars = {
    SNS_TOPIC_ARN = aws_sns_topic.order_updates.arn
  }
}

# --- 4. STEP FUNCTIONS (State Machine) ---
resource "aws_sfn_state_machine" "order_pipeline" {
  name     = "order-processing-pipeline"
  role_arn = data.aws_iam_role.lab_role.arn

  definition = jsonencode({
    Comment = "Order Processing Pipeline"
    StartAt = "ValidateOrder"
    States = {
      ValidateOrder = {
        Type     = "Task"
        Resource = module.order_validator.arn
        Next     = "ProcessOrder"
      }
      ProcessOrder = {
        Type     = "Task"
        Resource = module.order_processor.arn
        End      = true
      }
    }
  })
}

# --- 5. API GATEWAY (REST API dla order-ingest) ---
resource "aws_api_gateway_rest_api" "order_api" {
  name = "OrderIngestAPI"
}

resource "aws_api_gateway_resource" "order_resource" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  parent_id   = aws_api_gateway_rest_api.order_api.root_resource_id
  path_part   = "orders"
}

resource "aws_api_gateway_method" "order_method" {
  rest_api_id   = aws_api_gateway_rest_api.order_api.id
  resource_id   = aws_api_gateway_resource.order_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.order_api.id
  resource_id             = aws_api_gateway_resource.order_resource.id
  http_method             = aws_api_gateway_method.order_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${module.order_ingest.arn}/invocations"
}