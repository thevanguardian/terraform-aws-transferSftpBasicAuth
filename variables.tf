locals {
  common_name  = "${lower(var.teamName)}-${var.serviceName}"
  storage_role = lower(var.storageBackend) == "s3" ? module.S3BucketAccess-IAM[0].iamRoleArn : module.EFSAccess-IAM[0].iamRoleArn
  storage_id   = lower(var.storageBackend) == "s3" ? aws_s3_bucket.default_storage[0].id : aws_efs_file_system.efs_storage[0].id
}
variable "defaultSftpUsers" {
  type        = list(string)
  default     = []
  description = "defaultSftpUsers (list): Defaults to empty, populate with list of usernames. These will be setup for basic authentication by default, refer to the README for alternative authentication methods."
}
variable "parameterStorePathPrefix" {
  type        = string
  default     = "/transfer/application/"
  description = "parameterStorePathPrefix (string): Default path to populate into Lambda and IAM for permissions / resource pathing."
  validation {
    condition     = can(regex("^/.*/$", var.parameterStorePathPrefix))
    error_message = "Variable parameterStorePathPrefix must begin and end with '/'."
  }
}

variable "enableXrayTracing" {
  type        = bool
  default     = false
  description = "enableXrayTracing (bool): Whether to enable Xray Tracing for supported services."
}

variable "xrayTracingMode" {
  type        = string
  default     = "PassThrough"
  description = "xrayTracingMode (string): Defaults to 'PassThrough', valid options are 'PassThrough' & 'Active'."
  validation {
    condition     = contains(["PassThrough", "Active"], var.xrayTracingMode)
    error_message = "Variable xrayTracingMode supported values: PassThrough / Active"
  }
}

variable "storageBackend" {
  type        = string
  default     = "s3"
  description = "storageBackend (string): Defaults to 's3', valid options are 's3' & 'efs'."
  validation {
    condition     = contains(["efs", "s3"], lower(var.storageBackend))
    error_message = "Variable storageBackend supports values of either 's3' or 'efs'."
  }
}

variable "secretsBackend" {
  type        = string
  default     = "ssm"
  description = "secretsBackend (string): Defaults to 'ssm', valid options are 'ssm' & 'secretsmanager'."
  validation {
    condition     = contains(["ssm", "secretsmanager"], lower(var.secretsBackend))
    error_message = "Variable secretsBackend supports values of either 'ssm' or 'secretsmanager'."
  }
}

variable "publicAccessible" {
  type        = bool
  description = "publicAccessible (bool): Defaults 'true'."
  default     = true
}

variable "apiGatewayName" {
  type        = string
  description = "apiGatewayName (string): Name for the API Gateway."
}

variable "vpcId" {
  type        = string
  description = "vpcId (string): ID of the VPC to be used for resources."
  validation {
    condition     = can(regex("^vpc-", var.vpcId))
    error_message = "Variable vpcId requires a valid VPC id, starting with 'vpc-'."
  }
}

variable "subnetIds" {
  type        = list(any)
  description = "subnetIds (list): List of subnet id's to be used."
  validation {
    condition     = can([for subnet in var.subnetIds : regex("^subnet-[[:alnum:]]*", subnet)])
    error_message = "Variable subnetIds requires a list of valid subnet id's."
  }
}

variable "serviceName" {
  type        = string
  default     = "transfer"
  description = "serviceName (string): Defaults to 'transfer', needs set with an identifiable overall service name for tagging and resource naming."
}

variable "teamName" {
  type        = string
  description = "teamName (string): Defaults to empty, needs populated with the team owning the associated resources."
}

variable "dnsZoneId" {
  type        = string
  description = "dnsZoneId (string): ID of the Route53 zone for DNS entries to be created."
  default     = ""
}

variable "dnsRecordName" {
  type        = string
  description = "dnsRecordName (string): DNS Record name to be created in var.dnsZoneId."
  default     = ""
}
