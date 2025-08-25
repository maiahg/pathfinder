########################################################################################
# Role and policies for the lambda
########################################################################################

data "aws_iam_policy_document" "lambda" {
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
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "lambda" {
  name        = "pathfinder-lambda-policy"
  description = "IAM policy for Pathfinder Lambda"
  policy      = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role" "lambda" {
  name               = "pathfinder-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "pathfinder_lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

########################################################################################
# Role and policies for DataSync S3 - EFS
########################################################################################

data "aws_iam_policy_document" "datasync" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]
    resources = [
      aws_s3_bucket.custom_files.arn,
      "${aws_s3_bucket.custom_files.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "datasync_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "datasync" {
  name               = "pathfinder-datasync"
  assume_role_policy = data.aws_iam_policy_document.datasync_assume_role.json
}

resource "aws_iam_policy" "datasync" {
  name        = "pathfinder-datasync-policy"
  description = "IAM policy for Pathfinder Datasync role"
  policy      = data.aws_iam_policy_document.datasync.json
}

resource "aws_iam_role_policy_attachment" "datasync" {
  role       = aws_iam_role.datasync.name
  policy_arn = aws_iam_policy.datasync.arn
}

########################################################################################
# Role and policies for the ECS execution
########################################################################################

data "aws_iam_policy_document" "ecs_execution" {
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:DescribeMountTargets"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "pathfinder-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_policy" "ecs_execution" {
  name   = "pathfinder-ecs-execution-policy"
  description = "IAM policy for Pathfinder ECS execution role"
  policy = data.aws_iam_policy_document.ecs_execution.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_execution.arn
}