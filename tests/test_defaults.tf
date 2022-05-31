variable "route53ZoneId" {
  type = string
}
variable "subnetIds" {
  type = list
}
provider "aws" {
  region = "us-east-1"
}
data "aws_vpc" "primary" {
  default = true
}

module "this" {
  source           = "../"
  storageBackend   = "efs"
  secretsBackend   = "ssm"
  publicAccessible = true
  apiGatewayName   = "BasicAuthSFTP"
  vpcId            = data.aws_vpc.primary.id
  subnetIds        = var.subnetIds
  serviceName      = "transfer"
  teamName         = "clients"
  dnsZoneId        = var.route53ZoneId
  dnsRecordName    = "sftp"
  defaultSftpUsers = ["myname"]
}
