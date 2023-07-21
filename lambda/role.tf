

data "aws_iam_role" "lambda_role" {
  name = "${var.role_name_prefix}-lambda-${var.environment}"
}

resource "aws_iam_policy" "kms_lambda_policy" {
  name        = "kms-${var.environment}-policy"
  description = "KMS Decrypt policy for lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:GenerateDataKey"
            ],
            "Resource": "${data.aws_kms_alias.sqs_kms.arn}"
        }
    ]
}
EOF
}
resource "aws_iam_policy" "sqs_policy_for_lambda" {
  name        = "sqs-${var.environment}-policy"
  description = "Allow Lambda Access to SQS"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sqs:ChangeMessageVisibility",
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes"
            ],
            "Resource": [
                "arn:aws:sqs:${var.region}:${var.aws_account}:${local.sqs_name}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "sqs:ListQueues"
            ],
            "Resource": [
                "arn:aws:sqs:${var.region}:${var.aws_account}:${local.sqs_name}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:*"
            ],
            "Resource": "${aws_lambda_function.lambda_function_with_java_src.arn}",
            "Condition": {
                "StringLike": {
                  "aws:SourceArn": "arn:aws:sqs:${var.region}:${var.aws_account}:${local.sqs_name}"
                },
                "Bool": {
                  "aws:SecureTransport": "true"
                }
            }
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "logging_policy" {
  role       = "${data.aws_iam_role.lambda_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
resource "aws_iam_role_policy_attachment" "lambda_role_policy" {
  role       = "${data.aws_iam_role.lambda_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_role_policy_attachment" "sqs_role_policy" {
  role       = "${data.aws_iam_role.lambda_role.name}"
  #policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  policy_arn = "${aws_iam_policy.sqs_policy_for_lambda.arn}"
}
resource "aws_iam_role_policy_attachment" "kms_lambda_role" {
  role       = "${data.aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.kms_lambda_policy.arn}"
}
data "aws_kms_alias" "sqs_kms" {
  name = "alias/sqs-kms-${var.environment}"
}
