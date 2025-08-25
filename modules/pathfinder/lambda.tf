########################################################################################
# Trigger resource used to force the archive to be generated at the apply stage
########################################################################################

resource "random_uuid" "archive_trigger" {
  keepers = {
    timestamp = timestamp()
  }
}

locals {
  python_runtime = "python3.11"

  common_python_files = {
    "commons/constants.py"       = "${path.root}/scripts/commons/constants.py"
    "commons/dynamodb_helper.py" = "${path.root}/scripts/commons/dynamodb_helper.py"
  }

  service_python_files = {
    "services/crime_service.py" = "${path.root}/scripts/services/crime_service.py"
  }

  all_python_files = merge(local.common_python_files, local.service_python_files)
}

resource "aws_lambda_layer_version" "python_layer" {
  filename            = "${path.root}/lambda_layers/python.zip"
  layer_name          = "python_layer"
  compatible_runtimes = [local.python_runtime]
}

########################################################################################
# Lambda add_crimes
########################################################################################

resource "aws_lambda_function" "add_crimes" {
  filename         = data.archive_file.add_crimes.output_path
  function_name    = "add-crimes"
  handler          = "add_crimes.lambda_handler"
  source_code_hash = data.archive_file.add_crimes.output_base64sha256
  description      = "Lambda function to add crimes to DynamoDB"
  role             = aws_iam_role.lambda.arn
  runtime          = local.python_runtime
  timeout          = 300
  layers           = [aws_lambda_layer_version.python_layer.arn]
  depends_on       = [data.archive_file.add_crimes]
}

data "archive_file" "add_crimes" {
  type        = "zip"
  output_path = "${path.module}/temp/add_crimes.zip"

  source {
    content  = file("${path.module}/lambda/add_crimes.py")
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

########################################################################################
# Lambda update_crimes
########################################################################################

resource "aws_lambda_function" "update_crimes" {
  filename         = data.archive_file.update_crimes.output_path
  function_name    = "update-crimes"
  handler          = "update_crimes.lambda_handler"
  source_code_hash = data.archive_file.update_crimes.output_base64sha256
  description      = "Lambda function to update crimes in DynamoDB"
  role             = aws_iam_role.lambda.arn
  runtime          = local.python_runtime
  timeout          = 300
  layers           = [aws_lambda_layer_version.python_layer.arn]
  depends_on       = [data.archive_file.add_crimes]
}

data "archive_file" "update_crimes" {
  type        = "zip"
  output_path = "${path.module}/temp/update_crimes.zip"

  source {
    content  = file("${path.module}/lambda/update_crimes.py")
    filename = "update_crimes.py"
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

########################################################################################
# Lambda get_direction
########################################################################################

resource "aws_lambda_function" "get_direction" {
  filename         = data.archive_file.get_direction.output_path
  function_name    = "get-direction"
  handler          = "get_direction.lambda_handler"
  source_code_hash = data.archive_file.get_direction.output_base64sha256
  description      = "Lambda function to get direction between origin and destinations"
  role             = aws_iam_role.lambda.arn
  runtime          = local.python_runtime
  timeout          = 300
  layers           = [aws_lambda_layer_version.python_layer.arn]
  depends_on       = [data.archive_file.add_crimes]
}

data "archive_file" "get_direction" {
  type        = "zip"
  output_path = "${path.module}/temp/get_direction.zip"

  source {
    content  = file("${path.module}/lambda/get_direction.py")
    filename = "get_direction.py"
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

resource "aws_lambda_permission" "get_direction" {
  statement_id  = "AllowAPIGatewayInvokeGetDirection"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_direction.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}

########################################################################################
# Lambda get_unsafe_areas
########################################################################################

resource "aws_lambda_function" "get_unsafe_areas" {
  filename         = data.archive_file.get_unsafe_areas.output_path
  function_name    = "get-unsafe-areas"
  handler          = "get_unsafe_areas.lambda_handler"
  source_code_hash = data.archive_file.get_unsafe_areas.output_base64sha256
  description      = "Lambda function to get unsafe areas from the database"
  role             = aws_iam_role.lambda.arn
  runtime          = local.python_runtime
  timeout          = 300
  layers           = [aws_lambda_layer_version.python_layer.arn]
  depends_on       = [data.archive_file.add_crimes]
}

data "archive_file" "get_unsafe_areas" {
  type        = "zip"
  output_path = "${path.module}/temp/get_unsafe_areas.zip"

  source {
    content  = file("${path.module}/lambda/get_unsafe_areas.py")
    filename = "get_unsafe_areas.py"
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

resource "aws_lambda_permission" "get_unsafe_areas" {
  statement_id  = "AllowAPIGatewayInvokeGetUnsafeAreas"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_unsafe_areas.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}