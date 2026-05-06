# 9- Verify Email in SES
resource "aws_ses_email_identity" "alert_email" {
  email = var.email_address
}

# 10- IAM Role for Lambda (للسماح لـ Lambda بإرسال إيميلات)
resource "aws_iam_role" "lambda_role" {
  name = "terraform_state_alert_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_ses_policy" {
  name = "lambda_ses_send_email_policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ses:SendEmail", "ses:SendRawEmail", "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# كود البايثون الخاص بـ Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source {
    content  = <<-EOF
      import boto3
      import os
      def lambda_handler(event, context):
          ses = boto3.client('ses', region_name='us-east-1')
          email = os.environ['EMAIL_ADDRESS']
          try:
              response = ses.send_email(
                  Source=email,
                  Destination={'ToAddresses': [email]},
                  Message={
                      'Subject': {'Data': 'Terraform State File Alert!'},
                      'Body': {'Text': {'Data': 'The terraform.tfstate file in your S3 bucket has been modified.'}}
                  }
              )
              return {"statusCode": 200, "body": "Email sent!"}
          except Exception as e:
              print(e)
              return {"statusCode": 500, "body": str(e)}
    EOF
    filename = "lambda_function.py"
  }
}

# 10- Create Lambda Function
resource "aws_lambda_function" "state_alert_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "TerraformStateAlert"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"

  environment {
    variables = {
      EMAIL_ADDRESS = var.email_address
    }
  }
}

# 11- EventBridge Trigger to detect state changes
resource "aws_cloudwatch_event_rule" "s3_state_change" {
  name        = "capture-s3-tfstate-changes"
  description = "Capture changes to terraform state file"
  
  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created", "Object Deleted"]
    detail = {
      bucket = {
        name = [split(":", var.state_bucket_arn)[5]]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.s3_state_change.name
  target_id = "SendAlertLambda"
  arn       = aws_lambda_function.state_alert_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.state_alert_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_state_change.arn
}