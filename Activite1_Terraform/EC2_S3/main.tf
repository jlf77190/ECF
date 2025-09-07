terraform {
  backend "s3" {
    bucket         = "ecf-2025-backend-bucket"              
    key            = "ec2/terraform.tfstate"  
    region         = "eu-west-3"            
    encrypt        = true                    
    acl            = "private"               
  }
}

provider "vault" {
  address = "https://127.0.0.1:8200"
}

# Récupérer les credentials AWS depuis Vault
data "vault_kv_secret_v2" "aws" {
  mount = "aws-creds"
  name  = "aws"
}

# Récupérer les informations du mot de passe ubuntu depuis Vault
data "vault_kv_secret_v2" "user" {
  mount = "user-creds"
  name  = "user"
}

# Fournisseur AWS avec les secrets Vault pour l'accès
provider "aws" {
  region     = "eu-west-3"
  access_key = data.vault_kv_secret_v2.aws.data["access_key"]
  secret_key = data.vault_kv_secret_v2.aws.data["secret_key"]
}

# 🔹 Security Group pour l'EC2 avec accès SSH
resource "aws_security_group" "ec2_sg" {
  name_prefix = "ec2-sg-"

  # Autoriser SSH depuis n'importe quelle IP 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 🔹 Création de l'EC2 avec IP publique et clé SSH
resource "aws_instance" "ec2ecf" {
  ami                    = "ami-06e02ae7bdac6b938"
  instance_type          = "t2.micro"
  security_groups        = [aws_security_group.ec2_sg.name]
  associate_public_ip_address = true  
  key_name               = var.KEY_NAME  

  tags = {
    Name          = "EC2ECF"
    Environnement = "Prod"
  }

    user_data = <<-EOF
     #!/bin/bash
     set -e  # Arrêter le script si une commande échoue

     echo "ubuntu:${data.vault_kv_secret_v2.user.data["password"]}" | chpasswd || { echo "Failed to set ubuntu password"; exit 1; }

     # Mise à jour et installation des paquets nécessaires
     sudo apt update
     sleep 30  # Attendre un peu pour éviter les conflits de lock
     sudo apt install -y default-jdk mysql-client tomcat10 || { echo "Package installation failed"; exit 1; }

     # Vérifier que Tomcat est bien installé
     sudo systemctl enable tomcat10
     sudo systemctl start tomcat10 || { echo "Tomcat failed to start"; exit 1; }

     echo "Installation terminée avec succès"
  EOF


}

# 🔹 Bucket S3
resource "aws_s3_bucket" "ecf-2025" {
  bucket = "ecf-2025"
  tags = {
    Name          = "ecf-2025"
    Environnement = "Prod"
  }
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.ecf-2025.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# 🔹 Outputs pour voir l'IP publique et privée après Terraform Apply
output "ec2_public_ip" {
  value = aws_instance.ec2ecf.public_ip
}

output "ec2_private_ip" {
  value = aws_instance.ec2ecf.private_ip
}

