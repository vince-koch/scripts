#/bin/bash

# Uninstall any old versions (Older versions of Docker went by the names of docker, docker.io, or docker-engine)
sudo apt-get remove docker docker-engine docker.io containerd runc

# Install Docker, you can ignore the warning from Docker about using WSL
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to the Docker group
sudo usermod -aG docker $USER

# Install Docker Compose v2
sudo apt-get update && sudo apt-get install docker-compose-plugin

# Sanity check that both tools were installed successfully
docker --version
docker compose version