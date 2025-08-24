data "aws_iam_policy_document" "pathfinder_lambda" {
  statement {
    effect = "Allow"
    actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:DeleteItem",
        "dynamodb:UpdateItem",
        "dynamodb:Scan",
    ]

    resources = [
        aws_dynamodb_table.ytd_crime_data.arn,
    ]
  }
  statement {
    effect = "Allow"
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
    ]

    resources = [
        "arn:aws:logs:*:*:log-group:*",
    ]
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "pathfinder_lambda" {
  name        = "pathfinder-lambda-policy"
  description = "IAM policy for Pathfinder Lambda"
  policy      = data.aws_iam_policy_document.pathfinder_lambda.json
}

resource "aws_iam_role" "pathfinder_lambda" {
  name               = "pathfinder-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "pathfinder_lambda" {
  role       = aws_iam_role.pathfinder_lambda.name
  policy_arn = aws_iam_policy.pathfinder_lambda.arn
}