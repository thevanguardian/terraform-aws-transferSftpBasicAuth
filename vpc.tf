resource "aws_vpc_endpoint" "transfer" {
  count             = var.publicAccessible ? 0 : 1
  vpc_id            = var.vpcId
  service_name      = "com.amazonaws.${data.aws_region.current.name}.transfer.server"
  vpc_endpoint_type = "Interface"
  auto_accept       = true
  subnet_ids        = flatten(var.subnetIds)

  policy = jsonencode({
    Statement = [
      {
        Action    = "*"
        Effect    = "Allow"
        Principal = "*"
        Resource  = "*"
      }
    ]
  })

  security_group_ids = [
    aws_security_group.transfer[*].id,
  ]
}
