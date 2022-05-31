resource "aws_route53_record" "transfer_endpoint" {
  count   = var.dnsZoneId != "" && var.dnsRecordName != "" ? 1 : 0
  zone_id = var.dnsZoneId
  name    = var.dnsRecordName
  type    = "CNAME"
  ttl     = "300"
  records = [aws_transfer_server.sftp.endpoint]
}
