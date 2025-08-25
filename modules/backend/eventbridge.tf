########################################################################################
# EventBridge Rule for Weekly Update of Crimes
########################################################################################

resource "aws_cloudwatch_event_rule" "weekly_update_crimes" {
  name                = "weekly-update-crimes"
  description         = "Trigger update_crimes Lambda every week"
  schedule_expression = "cron(0 0 ? * 1 *)"
}

resource "aws_lambda_permission" "allow_eventbridge_update_crimes" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_crimes.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_update_crimes.arn
}

resource "aws_cloudwatch_event_target" "update_crimes_target" {
  rule      = aws_cloudwatch_event_rule.weekly_update_crimes.name
  target_id = "UpdateCrimesLambda"
  arn       = aws_lambda_function.update_crimes.arn
}

########################################################################################
# Event setup to ping the PI lambdas to keep them warm
########################################################################################

resource "aws_cloudwatch_event_rule" "thaw_api_lambdas_cron" {
  name                = "thaw_api_lambdas_cron"
  description         = "Trigger API lambdas every 10 minutes to keep them warm"
  schedule_expression = "rate(10 minutes)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_target" "thaw_get_direction_cron" {
  arn  = aws_lambda_function.get_direction.arn
  rule = aws_cloudwatch_event_rule.thaw_api_lambdas_cron.id
  input = jsonencode({
    "action" : "thaw"
  })
}

resource "aws_cloudwatch_event_target" "thaw_get_unsafe_areas_cron" {
  arn  = aws_lambda_function.get_unsafe_areas.arn
  rule = aws_cloudwatch_event_rule.thaw_api_lambdas_cron.id
  input = jsonencode({
    "action" : "thaw"
  })
}