#!/bin/bash
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m  _____ _   _ _______ ______ _____  _      _____ _____   _____          \e[0m"
echo -e "\e[32m |_   _| \ | |__   __|  ____|  __ \| |    |_   _/ ____| |_   _|   /\    \e[0m"
echo -e "\e[32m   | | |  \| |  | |  | |__  | |__) | |      | || |  __    | |    /  \   \e[0m"
echo -e "\e[32m   | | |     |  | |  |  __| |  _  /| |      | || | |_ |   | |   / /\ \  \e[0m"
echo -e "\e[32m  _| |_| |\  |  | |  | |____| | \ \| |____ _| || |__| |  _| |_ / ____ \ \e[0m"
echo -e "\e[32m |_____|_| \_|  |_|  |______|_|  \_\______|_____\_____| |_____/_/    \_\ \e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"

# Função para mostrar um banner colorido
function show_banner() {
  echo -e "\e[32m==============================================================================\e[0m"
  echo -e "\e[32m=                                                                            =\e[0m"
  echo -e "\e[32m=                 \e[33mPreencha as informações solicitadas abaixo\e[32m                 =\e[0m"
  echo -e "\e[32m=                                                                            =\e[0m"
  echo -e "\e[32m==============================================================================\e[0m"
}

# Função para mostrar uma mensagem de etapa
function show_step() {
  echo -e "\e[32mPasso \e[33m$1/3\e[0m"
}

# Mostrar banner inicial
clear
show_banner
echo ""

# Solicitar informações do usuário
show_step 1
read -p "📧 Endereço de e-mail: " email
echo ""
show_step 2
read -p "🌐 Dominio do Portainer (ex: portainer.seudominio.com): " portainer
echo ""
show_step 3
read -p "🖥️ IP do Manager (ex: 192.168.0.100): " manager_ip
echo ""

# Verificação de dados
clear
echo ""
echo "📧 Seu E-mail: $email"
echo "🌐 Dominio do Portainer: $portainer"
echo "🖥️ IP do Manager: $manager_ip"
echo ""
read -p "As informações estão certas? (y/n): " confirma1
if [ "$confirma1" == "y" ]; then
  clear
  #########################################################
  # INSTALANDO DEPENDENCIAS
  #########################################################
  sudo apt-get update && sudo apt-get upgrade -y
  sudo apt install -y sudo gnupg2 wget ca-certificates apt-transport-https curl gnupg nano htop
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable docker.service
  sudo systemctl enable containerd.service

  sudo docker swarm init --advertise-addr=$manager_ip
  mkdir -p ~/Portainer && cd ~/Portainer
  echo -e "\e[32mAtualizado/Instalado com Sucesso\e[0m"
  sleep 3

  #########################################################
  # CRIANDO REDES DOCKER SWARM
  #########################################################
  sudo docker network create --driver=overlay traefik_public
  sudo docker network create --driver=overlay agent_network
  sudo docker network create --driver=overlay app_network

  #########################################################
  # CRIANDO STACK TRAEFIK
  #########################################################
  cat > traefik-stack.yml <<EOL
version: '3.8'

services:
  traefik:
    image: traefik:v2.11
    command:
      - --providers.docker=true
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --providers.docker.exposedbydefault=false
      - --providers.docker.swarmMode=true
      - --providers.docker.network=traefik_public
      - --providers.docker.endpoint=unix:///var/run/docker.sock
      - --certificatesresolvers.le.acme.httpchallenge.entrypoint=web
      - --certificatesresolvers.le.acme.email=$email
      - --certificatesresolvers.le.acme.storage=/letsencrypt/acme.json
      - --certificatesresolvers.le.acme.tlschallenge=true
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - traefik_certificates:/letsencrypt
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    deploy:
      mode: replicated
      replicas: 1
      resources:
        limits:
          cpus: "0.3"
          memory: 512M
      placement:
        constraints:
          - node.role == manager
    networks:
      - traefik_public

volumes:
  traefik_certificates:
    external: true

networks:
  traefik_public:
    external: true
EOL

  #########################################################
  # CRIANDO STACK PORTAINER
  #########################################################
  cat > portainer-stack.yml <<EOL
version: "3.8"

services:
  agent:
    image: portainer/agent:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    networks:
      - agent_network
    deploy:
      mode: global
      placement:
        constraints: [ node.platform.os == linux ]

  portainer:
    image: portainer/portainer-ce:latest
    command: -H tcp://tasks.agent:9001 --tlsskipverify
    ports:
      - 9000:9000
    volumes:
      - portainer_data:/data
    networks:
      - agent_network
      - traefik_public
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [ node.role == manager ]
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=traefik_public"
        - "traefik.http.routers.portainer.rule=Host(\`$portainer\`)"
        - "traefik.http.routers.portainer.entrypoints=websecure"
        - "traefik.http.routers.portainer.priority=1"
        - "traefik.http.routers.portainer.tls.certresolver=le"
        - "traefik.http.routers.portainer.service=portainer"
        - "traefik.http.services.portainer.loadbalancer.server.port=9000"

networks:
  traefik_public:
    external: true
    attachable: true
  agent_network:
    external: true

volumes:
  portainer_data:
    external: true
EOL

  #########################################################
  # INICIANDO STACKS
  #########################################################
  echo -e "\e[32mDeploying stacks...\e[0m"
  sudo docker stack deploy -c traefik-stack.yml traefik
  sudo docker stack deploy -c portainer-stack.yml portainer
  
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m  _____ _   _ _______ ______ _____  _      _____ _____   _____          \e[0m"
echo -e "\e[32m |_   _| \ | |__   __|  ____|  __ \| |    |_   _/ ____| |_   _|   /\    \e[0m"
echo -e "\e[32m   | | |  \| |  | |  | |__  | |__) | |      | || |  __    | |    /  \   \e[0m"
echo -e "\e[32m   | | |     |  | |  |  __| |  _  /| |      | || | |_ |   | |   / /\ \  \e[0m"
echo -e "\e[32m  _| |_| |\  |  | |  | |____| | \ \| |____ _| || |__| |  _| |_ / ____ \ \e[0m"
echo -e "\e[32m |_____|_| \_|  |_|  |______|_|  \_\______|_____\_____| |_____/_/    \_\ \e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
else
  echo "Encerrando a instalação, por favor, inicie a instalação novamente."
  exit 0
fi
