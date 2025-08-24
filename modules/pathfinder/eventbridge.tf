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
