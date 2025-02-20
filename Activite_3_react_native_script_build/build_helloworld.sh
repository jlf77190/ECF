#!/bin/bash

echo " Début du build de l'application HelloWorld..."

# Vérification des prérequis
if ! command -v node &> /dev/null; then
    echo "La présence de Node.js est nécessaire"
    exit 1
fi

# Vérification de la présence de npm
if ! command -v npm &> /dev/null; then
    echo "La présence de npm est nécessaire"
    exit 1
fi

# Vérifier si npx est installé
if ! command -v npx &> /dev/null; then
    echo "La présence de npx est nécessaire"
    exit 1
fi

# Installer les dépendances
echo "Installation des dépendances..."
npm install

# Vérifier si Expo est installé
if ! npm list expo &> /dev/null; then
    echo "Le module Expo n'est pas installé, installation en cours..."
    npm install expo
fi

# Démarrer Expo en mode tunnel en arrière-plan
echo "Démarrage d'Expo..."
npx expo start --tunnel &

# Attendre quelques secondes pour que Expo démarre
sleep 10

# Vérifier si le build a réussi
if [ $? -ne 0 ]; then
    echo "Échec du démarrage de l'application Expo."
    exit 1
fi

echo "Build Android terminé avec succès !"

