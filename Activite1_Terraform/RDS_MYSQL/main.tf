terraform {
  backend "s3" {
    bucket         = "ecf-2025-backend-bucket"
    key            = "rds/terraform.tfstate"
    region         = "eu-west-3"
    encrypt        = true
  }
}

provider "vault" {
  address = var.ADRESS_VAULT
}

data "vault_kv_secret_v2" "aws" {
  mount = var.MOUNT_VAULT_AWS
  name  = var.NAME_VAULT_AWS
}

data "vault_kv_secret_v2" "bdd" {
  mount = var.MOUNT_VAULT_BDD
  name  = var.NAME_VAULT_BDD
}

provider "aws" {
  region     = var.AWS_REGION
  access_key = data.vault_kv_secret_v2.aws.data["access_key"]
  secret_key = data.vault_kv_secret_v2.aws.data["secret_key"]
}

# 🔹 Récupération de l'IP privée de l'EC2 via Terraform Remote State
data "terraform_remote_state" "ec2" {
  backend = "s3"

  config = {
    bucket = "ecf-2025-backend-bucket"
    key    = "ec2/terraform.tfstate"
    region = "eu-west-3"
  }
}

locals {
  ec2_private_ip = data.terraform_remote_state.ec2.outputs.ec2_private_ip
}

resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-sg-"

  # Autoriser uniquement l'EC2 à accéder au port MySQL (3306)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${local.ec2_private_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Création de la base de données MySQL
resource "aws_db_instance" "mysql_rds" {
  identifier             = var.BDD_IDENTIFIER
  engine                 = var.BDD_ENGINE
  engine_version         = var.ENGINE_VERSION
  instance_class         = var.INSTANCE
  allocated_storage      = var.ALLOCATE_STORAGE
  storage_type           = var.STORAGE_TYPE
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  username              = data.vault_kv_secret_v2.bdd.data["user_db"]
  password              = data.vault_kv_secret_v2.bdd.data["password_db"]
  db_name               = var.DB_NAME
  parameter_group_name  = var.OG_PARAMETER
  skip_final_snapshot   = var.SKIPP

  tags = {
    Name        = var.TAG_NAME
    Environment = var.TAG_ENVIRONNEMENT
  }
}

# Output de l'endpoint RDS pour utilisation dans l'EC2
output "rds_endpoint" {
  value = aws_db_instance.mysql_rds.endpoint
}
