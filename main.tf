terraform {
  backend "atlas" {
    name = "shiftwise-amn/terraform-test"
  }
}

provider "aws" {
  region = "us-west-2"
}

variable git_token { default = "" }

resource "aws_iam_role" "ci_lambda_role" {
  name = "CiLambdaRole"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
  }
EOF
}

resource "aws_lambda_function" "ci_update" {
  filename         = "ci_update/ci_update.zip"
  description      = "Updates CI VPC with latest tags from Develop"
  function_name    = "CI_Update"
  role             = "${aws_iam_role.ci_lambda_role.arn}"
  handler          = "index.handler"
  source_code_hash = "${base64sha256(file("ci_update/ci_update.zip"))}"
  runtime          = "nodejs6.10"
  memory_size      = "512"
  timeout          = "5"
  publish          = "true"

  environment {
    variables = {
      GitHub_Token = "${var.git_token}"
    }
  }
}

resource "aws_lambda_function" "ci_intervals" {
  filename         = "ci_intervals/ci_intervals.zip"
  description      = "Kicks off CI functional tests"
  function_name    = "CI_Intervals"
  role             = "${aws_iam_role.ci_lambda_role.arn}"
  handler          = "index.handler"
  source_code_hash = "${base64sha256(file("ci_intervals/ci_intervals.zip"))}"
  runtime          = "nodejs6.10"
  memory_size      = "512"
  timeout          = "10"
  publish          = "true"

  environment {
    variables = {
      BRANCH       = "develop"
      REPO         = "continuous-integration"
      GITHUB       = "${var.git_token}"
      TARGET_ENVIRONMENT = "ci"
    }
  }
}

resource "aws_lambda_function" "rc_intervals" {
  filename         = "ci_intervals/ci_intervals.zip"
  description      = "Kicks off RC functional tests"
  function_name    = "RC_Intervals"
  role             = "${aws_iam_role.ci_lambda_role.arn}"
  handler          = "index.handler"
  source_code_hash = "${base64sha256(file("ci_intervals/ci_intervals.zip"))}"
  runtime          = "nodejs6.10"
  memory_size      = "512"
  timeout          = "10"
  publish          = "true"

  environment {
    variables = {
      BRANCH       = "master"
      REPO         = "continuous-integration"
      GITHUB       = "${var.git_token}"
      TARGET_ENVIRONMENT = "rc"
    }
  }
}

resource "aws_cloudwatch_event_rule" "CI_Intervals" {
  name                = "CI_Intervals"
  description         = "Start CI Test Run"
  schedule_expression = "cron(0 3/6 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_rule" "CI_Update" {
  name                = "CI_Update"
  description         = "Update the CI environment"
  schedule_expression = "cron(0 2/6 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_rule" "RC_Intervals" {
  name                = "RC_Intervals"
  description         = "Start RC Test Run"
  schedule_expression = "cron(0 3/6 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "ci_update_target" {
  rule      = "${aws_cloudwatch_event_rule.CI_Update.name}"
  arn       = "${aws_lambda_function.ci_update.arn}"
  target_id = "CI_Update"
}

resource "aws_cloudwatch_event_target" "ci_intervals_target" {
  rule      = "${aws_cloudwatch_event_rule.CI_Intervals.name}"
  arn       = "${aws_lambda_function.ci_intervals.arn}"
  target_id = "CI_Intervals"
}

resource "aws_cloudwatch_event_target" "rc_intervals_target" {
  rule      = "${aws_cloudwatch_event_rule.RC_Intervals.name}"
  arn       = "${aws_lambda_function.rc_intervals.arn}"
  target_id = "RC_Intervals"
}
