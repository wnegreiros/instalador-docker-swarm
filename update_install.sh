#!/bin/bash

# Atualiza o sistema e instala o Git
echo -e "\e[32mAtualizando o sistema e instalando o Git...\e[0m"
sudo apt update && sudo apt install -y git

# Clona o repositório do GitHub
echo -e "\e[32mClonando o repositório...\e[0m"
git clone https://github.com/wnegreiros/instalador-docker-swarm.git

# Navega para o diretório do repositório
cd instalador-docker-swarm

# Torna o script de instalação executável
echo -e "\e[32mTornando o script de instalação executável...\e[0m"
sudo chmod +x install_docker_swarm.sh

# Executa o script de instalação
echo -e "\e[32mExecutando o script de instalação...\e[0m"
./install_docker_swarm.sh
