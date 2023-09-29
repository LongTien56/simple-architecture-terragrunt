///////////////////////
//      schedule     //
///////////////////////
variable "schedule_name" {
  description = "The name of the schedule for this lambda function"
  type        = string
  default     = "Lambda"
}

variable "schedule_description" {
  description = "The description of the schedule"
  type        = string
  default     = "Lambda Schedule"
}

variable "schedule_expression" {
  description = "The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes)"
  type        = string
  default     = "cron(33 3 ? * MON-FRI *)"
}

resource "aws_lambda_permission" "cloudwatch_trigger" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = element(concat(aws_lambda_function.this.*.arn, [""]), 0)
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda.arn
}

resource "aws_cloudwatch_event_rule" "lambda" {
  name                = var.schedule_name
  description         = var.schedule_description
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda" {
  target_id = element(concat(aws_lambda_function.this.*.function_name, [""]), 0)
  rule      = aws_cloudwatch_event_rule.lambda.name
  arn       = element(concat(aws_lambda_function.this.*.arn, [""]), 0)
}
