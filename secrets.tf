resource "aws_secretsmanager_secret" "default_users_config" {
  for_each    = var.secretsBackend == "secretsmanager" ? toset(var.defaultSftpUsers) : []
  name        = "${aws_transfer_server.sftp.id}/${each.key}"
  description = "Default User Config for Transfer access."
}
resource "aws_secretsmanager_secret_version" "default_users_config" {
  for_each  = var.secretsBackend == "secretsmanager" ? toset(var.defaultSftpUsers) : []
  secret_id = "${aws_transfer_server.sftp.id}/${each.key}"
  secret_string = jsonencode({
    "Password" : "",
    "Role" : "${local.storage_role}",
    "PublicKeys" : "",
    "HomeDirectoryDetails" : "[{\"Entry\": \"/\", \"Target\": \"/${local.storage_id}/$${Transfer:UserName}\"}]"
  })
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
  depends_on = [
    aws_secretsmanager_secret.default_users_config,
  ]
}
resource "aws_ssm_parameter" "default_users_config" {
  for_each    = var.secretsBackend == "ssm" ? toset(var.defaultSftpUsers) : []
  name        = "${trimsuffix(var.parameterStorePathPrefix, "/")}/${aws_transfer_server.sftp.id}/${each.key}"
  description = "Default user config for Transfer access."
  type        = "SecureString"
  overwrite   = true
  value = jsonencode({
    "Password" : "",
    "Role" : "${local.storage_role}",
    "PublicKeys" : "",
    "HomeDirectoryDetails" : "[{\"Entry\": \"/\", \"Target\": \"/${local.storage_id}/$${Transfer:UserName}\"}]"
  })

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
