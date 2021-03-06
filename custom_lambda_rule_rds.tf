resource "aws_config_config_rule" "no_rds_instances_in_public_subnets_check" {
  name        = "rds_vpc_public_subnet"
  description = "A Config rule that checks that no RDS Instances are in Public Subnet."
  depends_on  = [aws_lambda_permission.LambdaPermissionConfigRule, module.secure-baseline_config-baseline]

  scope {
    compliance_resource_types = ["AWS::RDS::DBInstance"]
  }
  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.LambdaFunctionConfigRule.arn
    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
    source_detail {
      event_source = "aws.config"
      message_type = "OversizedConfigurationItemChangeNotification"
    }
  }

}

data "archive_file" "lambda_zip_inline_LambdaFunctionConfigRule" {
  type        = "zip"
  output_path = "${path.module}/index.zip"

  source {
    filename = "index.py"
    content  = "${file("${path.module}/custom_lambda_rules/no_rds_instances_in_public_subnets_check.py")}"

  }
}

resource "aws_lambda_function" "LambdaFunctionConfigRule" {
  function_name    = "LambdaFunctionForrds_vpc_public_subnet"
  timeout          = "300"
  runtime          = "python3.6"
  handler          = "index.lambda_handler"
  role             = aws_iam_role.LambdaIamRoleConfigRule.arn
  filename         = data.archive_file.lambda_zip_inline_LambdaFunctionConfigRule.output_path
  source_code_hash = data.archive_file.lambda_zip_inline_LambdaFunctionConfigRule.output_base64sha256

  vpc_config {
    security_group_ids = var.custom_lambda_vpc_security_group_ids
    subnet_ids         = var.custom_lambda_vpc_private_subnets
  }
}

resource "aws_lambda_permission" "LambdaPermissionConfigRule" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.LambdaFunctionConfigRule.function_name
  principal     = "config.amazonaws.com"
}

resource "aws_iam_role" "LambdaIamRoleConfigRule" {
  name               = "IamRoleForrds_vpc_public_subnet"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["lambda.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "LambdaIamRoleConfigRuleManagedPolicyRoleAttachment0" {
  role       = aws_iam_role.LambdaIamRoleConfigRule.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "LambdaIamRoleConfigRuleManagedPolicyRoleAttachment1" {
  role       = aws_iam_role.LambdaIamRoleConfigRule.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRulesExecutionRole"
}

resource "aws_iam_role_policy_attachment" "LambdaIamRoleConfigRuleManagedPolicyRoleAttachment2" {
  role       = aws_iam_role.LambdaIamRoleConfigRule.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}