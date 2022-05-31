resource "aws_security_group" "transfer" {
  count       = var.publicAccessible ? 0 : 1
  name        = "${local.common_name}-SecurityGroup"
  description = "Default security group for Transfer SFTP Service"
  vpc_id      = var.vpcId

  ingress {
    description = "SFTP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "lambda-efs" {
  count       = lower(var.storageBackend) == "efs" ? 1 : 0
  name        = "${local.common_name}-LambdaEFS"
  description = "Security group allowing communication between the Lambda function and EFS."
  vpc_id      = var.vpcId

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    self      = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
