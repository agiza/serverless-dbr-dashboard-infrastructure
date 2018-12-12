#--------------------------------------------------------------
# Terraform version validation
#--------------------------------------------------------------
terraform {
  required_version = ">= 0.11.8"
}

#--------------------------------------------------------------
# Providers
#--------------------------------------------------------------
# DBR require to use AWS as provider
provider "aws" {
  version = "~> 1.36"
  region  = "${var.region}"
}

provider "null" {
  version = "~> 1.0"
}

provider "template" {
  version = "~> 1.0"
}

#--------------------------------------------------------------
# IAM Policies
#--------------------------------------------------------------

data "template_file" "dynamodb_ro_access_policy" {
  template = "${file("${path.module}/policy/dynamodb_ro_access.tpl")}"

  vars {
    resources = "${aws_dynamodb_table.metrics_table.arn}"
  }
}

data "aws_iam_policy_document" "s3_full_access_policy" {
  statement {
    actions = ["s3:*"]

    resources = [
      "${aws_s3_bucket.athena_output_results.arn}",
      "${aws_s3_bucket.athena_output_results.arn}/*",
      "${aws_s3_bucket.billing_aws_parquet_reports.arn}",
      "${aws_s3_bucket.billing_aws_parquet_reports.arn}/*",
      "${data.aws_s3_bucket.billing_aws_reports.arn}",
      "${data.aws_s3_bucket.billing_aws_reports.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "cloudwatch_full_access_policy" {
  statement {
    actions = ["cloudwatch:*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

data "template_file" "athena_full_access_policy" {
  template = "${file("${path.module}/policy/athena_full_access.tpl")}"
}

data "template_file" "firehose_full_access_policy" {
  template = "${file("${path.module}/policy/firehose_full_access.tpl")}"

  vars {
    resources = "${aws_kinesis_firehose_delivery_stream.firehose_parquet.arn}"
  }
}

resource "aws_iam_policy" "athena_full_access" {
  name   = "${var.f360_env_dbr}-athena-full-access"
  policy = "${data.template_file.athena_full_access_policy.rendered}"
}

resource "aws_iam_policy" "cloudwatch_full_access" {
  name   = "${var.f360_env_dbr}-cloudwatch-full-access"
  policy = "${data.aws_iam_policy_document.cloudwatch_full_access_policy.json}"
}

resource "aws_iam_policy" "s3_full_access" {
  name   = "${var.f360_env_dbr}-s3-full-access"
  policy = "${data.aws_iam_policy_document.s3_full_access_policy.json}"
}

resource "aws_iam_policy" "dynamodb_ro_access" {
  name   = "${var.f360_env_dbr}-dynamodb-ro-access"
  policy = "${data.template_file.dynamodb_ro_access_policy.rendered}"
}

resource "aws_iam_policy" "firehose_full_access" {
  name   = "${var.f360_env_dbr}-firehose-full-access"
  policy = "${data.template_file.firehose_full_access_policy.rendered}"
}

data "aws_iam_policy_document" "lambda_service" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_parquet_service" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "firehose_service" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

#--------------------------------------------------------------
# DBR Lambda Role
#--------------------------------------------------------------
resource "aws_iam_role" "lambda_dbr_role" {
  name               = "${var.f360_env_dbr}-${var.lambda_dbr_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_service.json}"
}

resource "aws_iam_policy_attachment" "athena_access" {
  name       = "${var.f360_env_dbr}-athena-access"
  roles      = ["${aws_iam_role.lambda_dbr_role.name}", "${aws_iam_role.firehose_delivery.name}"]
  policy_arn = "${aws_iam_policy.athena_full_access.arn}"
}

resource "aws_iam_policy_attachment" "cloudwatch_access" {
  name       = "${var.f360_env_dbr}-cloudwatch-full-access"
  roles      = ["${aws_iam_role.lambda_dbr_role.name}", "${aws_iam_role.lambda_parquet_role.name}"]
  policy_arn = "${aws_iam_policy.cloudwatch_full_access.arn}"
}

resource "aws_iam_policy_attachment" "s3_access" {
  name       = "${var.f360_env_dbr}-s3-full-access"
  roles      = ["${aws_iam_role.lambda_dbr_role.name}", "${aws_iam_role.lambda_parquet_role.name}", "${aws_iam_role.firehose_delivery.name}"]
  policy_arn = "${aws_iam_policy.s3_full_access.arn}"
}

resource "aws_iam_policy_attachment" "dynamodb_access" {
  name       = "${var.f360_env_dbr}-dynamodb-ro-access"
  roles      = ["${aws_iam_role.lambda_dbr_role.name}"]
  policy_arn = "${aws_iam_policy.dynamodb_ro_access.arn}"
}

#--------------------------------------------------------------
# ParquetParser Lambda Role
#--------------------------------------------------------------
resource "aws_iam_role" "lambda_parquet_role" {
  name               = "${var.f360_env_dbr}-${var.lambda_parquet_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_service.json}"
}

resource "aws_iam_policy_attachment" "firehose_access" {
  name       = "${var.f360_env_dbr}-firehose-full-access"
  roles      = ["${aws_iam_role.lambda_parquet_role.name}"]
  policy_arn = "${aws_iam_policy.firehose_full_access.arn}"
}

#--------------------------------------------------------------
# Kinesis firehose role
#--------------------------------------------------------------
resource "aws_iam_role" "firehose_delivery" {
  name               = "${var.firehose_delivery_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.firehose_service.json}"
}

#--------------------------------------------------------------
# S3 Bucket to put Athena Results files
#--------------------------------------------------------------
resource "aws_s3_bucket" "athena_output_results" {
  bucket = "${var.athena_output_results_bucket_name}"
  acl    = "private"
  region = "${var.region}"

  force_destroy = true

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.athena_output_results_bucket_name}"
    )
  )}"
}

#--------------------------------------------------------------
# S3 Bucket billing reports files
#--------------------------------------------------------------
data "aws_s3_bucket" "billing_aws_reports" {
  bucket = "${var.billing_aws_reports_bucket_name}"
}

#--------------------------------------------------------------
# S3 Bucket billing reports files in parquet format
#--------------------------------------------------------------
resource "aws_s3_bucket" "billing_aws_parquet_reports" {
  bucket = "${var.billing_aws_parquet_reports_bucket_name}"
  acl    = "private"
  region = "${var.region}"

  force_destroy = false

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.billing_aws_parquet_reports_bucket_name}"
    )
  )}"
}

#--------------------------------------------------------------
# DynamoDB table where for storage metrics
#--------------------------------------------------------------
resource "aws_dynamodb_table" "metrics_table" {
  name           = "${var.dynamodb_metrics_table_name}"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "metric_name"

  attribute {
    name = "metric_name"
    type = "S"
  }

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.dynamodb_metrics_table_name}"
    )
  )}"
}

#--------------------------------------------------------------
# Athena Database To run the queries
#--------------------------------------------------------------
resource "aws_athena_database" "dbr_aws_billing" {
  name   = "${var.athena_db_name}"
  bucket = "${aws_s3_bucket.athena_output_results.bucket}"
}

#--------------------------------------------------------------
# Athena Database Table
#--------------------------------------------------------------
data "template_file" "athena_metric_table" {
  template = "${file("${path.module}/athena/schema.sql.tpl")}"

  vars {
    s3_bucket_name = "${aws_s3_bucket.billing_aws_parquet_reports.id}"
    athena_db      = "${aws_athena_database.dbr_aws_billing.name}"
    athena_table   = "${var.athena_table_name}"
  }
}

module "aws_cli_install" {
  source = "../cli"
}

data "template_file" "athena_dbr_billing_table" {
  template = <<EOF
  ${module.aws_cli_install.script}

  "$WORKDIR"/aws/bin/aws --region=${var.region} athena start-query-execution --query-string "${data.template_file.athena_metric_table.rendered}" --result-configuration OutputLocation=s3://${aws_s3_bucket.athena_output_results.id}
  EOF
}

resource "null_resource" "athena_dbr_billing_table" {
  provisioner "local-exec" {
    command = "${data.template_file.athena_dbr_billing_table.rendered}"
  }
}

resource "aws_athena_named_query" "dbr_billing" {
  name     = "${var.athena_table_query}"
  database = "${aws_athena_database.dbr_aws_billing.name}"
  query    = "${data.template_file.athena_metric_table.rendered}"
}

#--------------------------------------------------------------
# Lambda Input file
#--------------------------------------------------------------
resource "null_resource" "lambda_input_file" {
  triggers = {
    filename = "${path.module}/dbr.zip"
  }

  provisioner "local-exec" {
    command = "curl https://github.com/full360/serverless-dbr-dashboard/releases/download/v${var.lambda_version}/dbr_${var.lambda_version}_Linux-x86_64.zip -fsSL -o ${path.module}/dbr.zip"
  }
}

#--------------------------------------------------------------
# DBR Lambda Function
#--------------------------------------------------------------
resource "aws_lambda_function" "dbr_lambda" {
  filename         = "${null_resource.lambda_input_file.triggers.filename}"
  function_name    = "${var.lambda_dbr_function_name}"
  handler          = "${var.lambda_dbr_handler_name}"
  source_code_hash = "${base64sha256(null_resource.lambda_input_file.triggers.filename)}"
  runtime          = "${var.lambda_dbr_runtime}"
  role             = "${aws_iam_role.lambda_dbr_role.arn}"
  timeout          = "20"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = "${var.dynamodb_metrics_table_name}"
      ATHENA_TABLE_QUERY  = "${aws_athena_named_query.dbr_billing.id}"
      BCK_OUT_RESULTS     = "${aws_s3_bucket.athena_output_results.id}"
    }
  }

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.lambda_dbr_function_name}"
    )
  )}"
}

resource "aws_lambda_permission" "allow_dbr_bucket" {
  statement_id  = "allow-execution-${var.lambda_dbr_function_name}-from-s3-bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.dbr_lambda.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.billing_aws_parquet_reports.arn}"
}

resource "aws_s3_bucket_notification" "new_billing_parquet_file_s3_notification" {
  bucket = "${aws_s3_bucket.billing_aws_parquet_reports.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.dbr_lambda.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".parquet"
  }
}

#--------------------------------------------------------------
# DBR Dashboard
#--------------------------------------------------------------
data "template_file" "dbr_dashboard_overview" {
  template = "${file("${path.module}/dashboard/dbr_dashboard.tpl")}"

  vars {
    region = "${var.region}"
  }
}

resource "aws_cloudwatch_dashboard" "dbr_dashboard" {
  dashboard_name = "${var.dbr_dashboard_name}"
  dashboard_body = "${data.template_file.dbr_dashboard_overview.rendered}"
}

#--------------------------------------------------------------
# Firehose To parse to parquet files
#--------------------------------------------------------------
resource "aws_kinesis_firehose_delivery_stream" "firehose_parquet" {
  depends_on = [
    "aws_iam_role.firehose_delivery",
    "null_resource.athena_dbr_billing_table",
  ]

  name        = "${var.firehose_dbr_name}"
  destination = "extended_s3"

  extended_s3_configuration {
    bucket_arn  = "${aws_s3_bucket.billing_aws_parquet_reports.arn}"
    role_arn    = "${aws_iam_role.firehose_delivery.arn}"
    buffer_size = "64"

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = "${aws_athena_database.dbr_aws_billing.name}"
        role_arn      = "${aws_iam_role.firehose_delivery.arn}"
        table_name    = "${var.athena_table_name}"
      }
    }
  }
}

#--------------------------------------------------------------
# CSVToParquet Lambda Function
#--------------------------------------------------------------
resource "aws_lambda_function" "parquet_lambda" {
  depends_on = [
    "aws_kinesis_firehose_delivery_stream.firehose_parquet",
  ]

  filename         = "${null_resource.lambda_input_file.triggers.filename}"
  function_name    = "${var.lambda_parquet_function_name}"
  handler          = "${var.lambda_parquet_handler_name}"
  source_code_hash = "${base64sha256(null_resource.lambda_input_file.triggers.filename)}"
  runtime          = "${var.lambda_parquet_runtime}"
  role             = "${aws_iam_role.lambda_parquet_role.arn}"
  timeout          = "180"

  environment {
    variables = {
      FIREHOSE_STREAM_NAME = "${aws_kinesis_firehose_delivery_stream.firehose_parquet.name}"
      FILE_FILTER          = "${var.parquet_parser_file_filter}"
    }
  }

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.lambda_parquet_function_name}"
    )
  )}"
}

resource "aws_lambda_permission" "allow_parquet_bucket" {
  statement_id  = "allow-execution-${var.lambda_parquet_function_name}-from-s3-bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.parquet_lambda.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${data.aws_s3_bucket.billing_aws_reports.arn}"
}

resource "aws_s3_bucket_notification" "new_billing_file_s3_notification" {
  bucket = "${data.aws_s3_bucket.billing_aws_reports.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.parquet_lambda.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".zip"
  }
}

#--------------------------------------------------------------
# Metrics
#--------------------------------------------------------------
data "template_file" "total_cost_per_service_metric" {
  template = "${file("${path.module}/dashboard/metrics/total_cost_per_service.tpl")}"

  vars {
    s3_bucket_name = "${aws_s3_bucket.athena_output_results.id}"
    athena_db      = "${aws_athena_database.dbr_aws_billing.name}"
    athena_table   = "${var.athena_table_name}"
  }
}

resource "aws_dynamodb_table_item" "total_cost_per_service_metric_item" {
  table_name = "${aws_dynamodb_table.metrics_table.name}"
  hash_key   = "${aws_dynamodb_table.metrics_table.hash_key}"
  item       = "${data.template_file.total_cost_per_service_metric.rendered}"
}

data "template_file" "total_cost_metric" {
  template = "${file("${path.module}/dashboard/metrics/total_cost.tpl")}"

  vars {
    s3_bucket_name = "${aws_s3_bucket.athena_output_results.id}"
    athena_db      = "${aws_athena_database.dbr_aws_billing.name}"
    athena_table   = "${var.athena_table_name}"
  }
}

resource "aws_dynamodb_table_item" "total_cost_metric_item" {
  table_name = "${aws_dynamodb_table.metrics_table.name}"
  hash_key   = "${aws_dynamodb_table.metrics_table.hash_key}"
  item       = "${data.template_file.total_cost_metric.rendered}"
}
