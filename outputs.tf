output "order_ingest_lambda_arn" {
  value = module.order_ingest_lambda.function_arn
}

output "order_validator_lambda_arn" {
  value = module.order_validator_lambda.function_arn
}

output "order_processor_lambda_arn" {
  value = module.order_processor_lambda.function_arn
}
