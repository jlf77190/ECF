variable "ADRESS_VAULT" {}
variable "BDD_IDENTIFIER" {}
variable "BDD_ENGINE" {}
variable "ENGINE_VERSION" {}
variable "INSTANCE" {}
variable "ALLOCATE_STORAGE" {}
variable "STORAGE_TYPE" {}
variable "PUBLIC_ACCESS" {}
variable "SKIPP" {}
variable "TAG_NAME" {}
variable "TAG_ENVIRONNEMENT" {}
variable "DB_NAME" {}
variable "OG_PARAMETER" {}
variable "KEY_NAME" {}
variable "AWS_REGION" {
    default = "eu-west-3"
}
variable "MOUNT_VAULT_AWS" {
  type = string
}

variable "NAME_VAULT_AWS" {
  type = string
}

variable "MOUNT_VAULT_BDD" {
  type = string
}

variable "NAME_VAULT_BDD" {
  type = string
}