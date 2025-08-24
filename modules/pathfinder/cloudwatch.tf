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
# Event setup to ping the PI lambdas to keep them warm
########################################################################################

resource "aws_cloudwatch_event_rule" "thaw_api_lambdas_cron" {
  name                = "pathfinder-thaw_api_lambdas_cron"
  description         = "Trigger API lambdas every 10 minutes to keep them warm"
  schedule_expression = "rate(10 minutes)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_target" "thaw_get_direction_cron" {
    arn      = aws_lambda_function.get_direction.arn
    rule     = aws_cloudwatch_event_rule.thaw_api_lambdas_cron.id
    input = jsonencode({
      "action": "thaw"
    })
}

resource "aws_cloudwatch_event_target" "thaw_get_unsafe_areas_cron" {
  arn       = aws_lambda_function.get_unsafe_areas.arn
  rule      = aws_cloudwatch_event_rule.thaw_api_lambdas_cron.id
  input = jsonencode({
    "action": "thaw"
})
}