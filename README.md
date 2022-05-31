- [Details](#details)
  - [Available Inputs](#available-inputs)
- [Example Usage](#example-usage)

Deploys and configures a Transfer and API Gateway system that enables username/password authenticated logins.

## Details

Sets up a Transfer SFTP system with a custom identity provider run through API Gateway, which validates authentication through Lambda and Secrets/SSM. User configurations are stored as JSON objects in either Secrets Manager or SSM Parameter Store. For backend storage, it supports either S3 (default) or EFS, and will setup the appropriate services to support the backend.

### Available Inputs

- defaultSftpUsers (list(string)): Defaults to empty, populate with list of default SFTP usernames to create into the designated secrets backend.
  - Secrets Manager: Stored as '${transferserver_id}/${username}'
  - Parameter Store: Stored as '${parameterstorepathprefix}/${transferserver_id}/${username}'
  - Since ${username} is stored in the name of the object, be mindful of naming constraints for the respective services.
- parameterStorePathPrefix (string): Defaults to "/transfer/application/". Designates the path that parameter store secrets are stored in, for organizational purposes.
- storageBackend (string): Defaults to "s3". Valid options are 's3' & 'efs'.
- secretsBackend (string): Defaults to "ssm". Valid options are 'ssm' & 'secretsmanager'.
- publicAccessible (bool): Defaults to true. When true, will create a public Transfer server.
- vpcId (string): VPC for the resources to be created in.
- subnetIds (list): List of subnet ID's to be used, must be configured to reside within vpcId.
- serviceName (string): Defaults to 'transfer'. Name that will be used in resource naming, to assist in identifying what the resources are tied to.
- teamName (string): Team responsible for managing and maintaining the deployment.
- dnsZoneId (string): Route53 zone for the required DNS entries to be created.
- dnsRecordName (string): Record name to be created in dnsZoneId.

## Example Usage

```hcl
module "this" {
  source           = "thevanguardian/transferSftpBasicAuth/aws"
  version          = "1.0.2"
  storageBackend   = "efs"
  secretsBackend   = "ssm"
  publicAccessible = true
  apiGatewayName   = "BasicAuthSFTP"
  vpcId            = data.aws_vpc.primary.id
  subnetIds        = data.aws_subnet_ids.primary.*.ids
  serviceName      = "transfer"
  teamName         = "clients"
  dnsZoneId        = var.route53ZoneId == "" ? data.aws_route53_zone.default[0].zone_id : var.route53ZoneId
  dnsRecordName    = "sftp"
  defaultSftpUsers = ["myname"]
}
```
