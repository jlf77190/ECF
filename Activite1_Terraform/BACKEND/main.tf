provider "vault" {
  address = "https://127.0.0.1:8200"
}

# Récupérer les credentials AWS depuis Vault
data "vault_kv_secret_v2" "aws" {
  mount = "aws-creds"
  name  = "aws"
}

# Fournisseur AWS avec les secrets Vault pour l'accès
provider "aws" {
  region     = "eu-west-3"
  access_key = data.vault_kv_secret_v2.aws.data["access_key"]
  secret_key = data.vault_kv_secret_v2.aws.data["secret_key"]
}

resource "aws_s3_bucket" "ecf-2025" {
  bucket = "ecf-2025-backend-bucket"
  tags = {
    Name          = "backend-ecf-2025"
    Environnement = "Prod"
  }
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.ecf-2025.bucket  # Référence correcte ici
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}