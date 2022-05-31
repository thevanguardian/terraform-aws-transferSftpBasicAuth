data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_kms_alias" "efs" {
  name = "alias/aws/elasticfilesystem"
}
data "archive_file" "lambda_function" {
  type        = "zip"
  output_path = "${path.root}/.terraform/lambda.zip"
  source {
    content  = file("${path.module}/lambda/index.py")
    filename = "index.py"
  }
}

data "aws_iam_policy_document" "transfer-cw" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}
