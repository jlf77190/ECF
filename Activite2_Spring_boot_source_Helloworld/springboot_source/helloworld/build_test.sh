#!/bin/bash

# Variables
PROJECT_NAME="helloworld"  
JAR_FILE="target/${PROJECT_NAME}-0.0.1-SNAPSHOT.jar" # Nom du package  
VM_USER="jarod" # Utilisateur sur la VM
VM_HOST="10.0.2.25"  # Adresse IP de la VM
VM_DEPLOY_DIR="/home/${VM_USER}/workdir_bis"  # Répertoire de déploiement sur la VM

# Build du projet avec Maven
echo "Build du projet..."
mvn clean package

# Test du build
if [ $? -ne 0 ]; then
  echo "Echec du Build"S
  exit 1
fi

# Test avec Maven
echo "Execution du test..."
mvn test

# Vérification de la réussite des test
if [ $? -ne 0 ]; then
  echo "Test en echec."
  exit 1
fi

# Copie du fichier JAR sur la VM
echo "Deploiement sur la VM..."
scp ${JAR_FILE} ${VM_USER}@${VM_HOST}:${VM_DEPLOY_DIR}

# Vérification de la copie
if [ $? -ne 0 ]; then
  echo "Echec de la copie du fichier ${JAR_FILE} sur VM."
  exit 1
fi

# Execution de l'application sur la VM
echo "Démarrage de l'application sur la VM..."
ssh ${VM_USER}@${VM_HOST} << EOF
  cd ${VM_DEPLOY_DIR}
  # Arret de l'application si déjà en cours d'exécution
  pkill -f ${JAR_FILE} || true
  # Démarrage de l'application
  nohup java -jar ${VM_DEPLOY_DIR}/${PROJECT_NAME}-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
  echo "Application started."
EOF

# Vérification de la reussite du déploiement
if [ $? -ne 0 ]; then
  echo "Echec du démarrage de l'application sur la VM."
  exit 1
fi

echo "Déploiement réussi"
