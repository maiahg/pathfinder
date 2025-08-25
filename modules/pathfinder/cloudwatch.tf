########################################################################################
# Log groups for the lambda functions
########################################################################################

resource "aws_cloudwatch_log_group" "add_crimes" {
  name              = "/aws/lambda/${aws_lambda_function.add_crimes.function_name}"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_group" "update_crimes" {
  name              = "/aws/lambda/${aws_lambda_function.update_crimes.function_name}"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_group" "get_direction" {
  name              = "/aws/lambda/${aws_lambda_function.get_direction.function_name}"
  retention_in_days = 3
}
resource "aws_cloudwatch_log_group" "get_unsafe_areas" {
  name              = "/aws/lambda/${aws_lambda_function.get_unsafe_areas.function_name}"
  retention_in_days = 3
}

########################################################################################
# Log group for API Gateway
########################################################################################

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/api-gateway/${aws_api_gateway_rest_api.rest_api.name}"
  retention_in_days = 3
}

########################################################################################
# Log group for Datasync
########################################################################################

resource "aws_cloudwatch_log_group" "datasync" {
  name              = "/aws/datasync/${aws_datasync_task.s3_to_efs.name}"
  retention_in_days = 3
}