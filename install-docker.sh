#!/bin/bash

# Optional Repo einrichten (falls nicht vorhanden) 
sudo apt update 
sudo apt install apt-transport-https ca-certificates curl software-properties-common 

KEYRING=/usr/share/keyrings/docker-archive-keyring.gpg

if [ ! -f "$KEYRING" ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o $KEYRING
else
    echo "Docker Keyring existiert bereits, überspringe Download"
fi

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 
sudo apt update 

# Mögliche Versionen anzeigen
echo "Verfügbare Docke-Versionen:"
apt-cache madison docker-ce | awk '{print $3}' | sort -r

# Gewünschte Version installieren 
read -p "Welche Docker-Version willst du installieren? (leer = neueste): " DOCKER_VERSION

if [ -z "$DOCKER_VERSION" ]; then
    DOCKER_VERSION=$(apt-cache madison docker-ce | awk '{print $3}' | sort -r | head -n1)
fi

sudo apt install docker-ce="$DOCKER_VERSION" docker-ce-cli="$DOCKER_VERSION" containerd.io -y


# Docker-Dienst starten & prüfen 
sudo systemctl start docker 
sudo systemctl enable docker 
docker --version 
docker ps
