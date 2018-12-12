variable "athena_output_results_bucket_name" {
  default = "dbr-athena-results"
}

variable "dynamodb_metrics_table_name" {
  default = "dbr-metrics"
}

variable "athena_db_name" {
  default = "dbr_billing"
}

variable "athena_table_name" {
  default = "dbr_analyzer"
}

variable "athena_table_query" {
  default = "dbr_analyzer_table_query"
}

variable "billing_aws_parquet_reports_bucket_name" {
  default = "dbr-billings-parquet-report"
}

variable "lambda_dbr_function_name" {
  default = "dbr-billing-analyzer"
}

variable "lambda_parquet_function_name" {
  default = "dbr-parquet-parser"
}

variable "firehose_dbr_name" {
  default = "dbr-billing-parquet"
}

variable "lambda_dbr_handler_name" {
  default = "dbr"
}

variable "lambda_dbr_runtime" {
  default = "go1.x"
}

variable "lambda_dbr_role_name" {
  default = "lambda"
}

variable "firehose_delivery_role_name" {
  default = "dbr-firehose"
}

variable "lambda_parquet_role_name" {
  default = "dbr-parquet-lambda"
}

variable "dbr_dashboard_name" {
  default = "DBRdashboard"
}

variable "lambda_parquet_handler_name" {
  default = "parquetparser"
}

variable "lambda_parquet_runtime" {
  default = "go1.x"
}

variable "common_tags" {
  type = "map"

  default = {
    Terraform   = true
    Author      = "dbr"
    Department  = "dbr"
    Environment = "prod"
  }
}

variable "f360_env_dbr" {
  default = "dbr-prod"
}

variable "parquet_parser_file_filter" {
  default = "aws-billing-detailed-line-items-2"
}

variable "billing_aws_reports_bucket_name" {}
variable "region" {}
variable "lambda_version" {}
