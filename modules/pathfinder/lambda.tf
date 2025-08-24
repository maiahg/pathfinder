# Trigger resource used to force the archive to be generated at the apply stage
resource "random_uuid" "archive_trigger" {
  keepers = {
    timestamp = timestamp()
  }
}

locals {
    python_runtime = "python3.11"

    common_python_files = {
        "commons/constants.py" = "${path.root}/scripts/commons/constants.py"
        "commons/dynamodb_helper.py" = "${path.root}/scripts/commons/dynamodb_helper.py"
    }

    service_python_files = {
        "services/crime_service.py" = "${path.root}/scripts/services/crime_service.py"
    }

    all_python_files = merge(local.common_python_files, local.service_python_files)
}

resource "aws_lambda_layer_version" "python_layer" {
    filename         = "${path.root}/lambda_layers/python.zip"
    layer_name       = "python_layer"
    compatible_runtimes = [local.python_runtime]
}

# Lambda add_crimes
resource "aws_lambda_function" "add_crimes" {
  filename = data.archive_file.add_crimes.output_path  
  function_name = "add-crimes"
  handler       = "add_crimes.lambda_handler"
  source_code_hash = data.archive_file.add_crimes.output_base64sha256
  description   = "Lambda function to add crimes to DynamoDB"
  role          = aws_iam_role.pathfinder_lambda.arn
  runtime       = local.python_runtime
  timeout       = 300
  layers = [aws_lambda_layer_version.python_layer.arn]
  depends_on = [data.archive_file.add_crimes]
}

data "archive_file" "add_crimes" {
  type        = "zip"
  output_path = "${path.module}/temp/add_crimes.zip"

  source {
    content = file("${path.module}/lambda/add_crimes.py")
    filename = "add_crimes.py"
  }

  dynamic "source" {
    for_each = local.all_python_files
    
    content {
      content  = file(source.value)
      filename = source.key
    }
  }

  depends_on = [random_uuid.archive_trigger]
}