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
  echo -e "\e[32mPasso \e[33m$1/7\e[0m"
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
read -p "🌐 Dominio do Traefik (ex: traefik.seudominio.com): " traefik
echo ""
show_step 3
read -s -p "🔑 Senha do Traefik: " senha
echo ""
echo ""
show_step 4
read -p "🌐 Dominio do Portainer (ex: portainer.seudominio.com): " portainer
echo ""
show_step 5
read -p "🌐 Dominio do Edge (ex: edge.seudominio.com): " edge
echo ""
show_step 6
read -p "🖥️ IP do Manager (ex: 192.168.0.100): " manager_ip
echo ""
# Verificação de dados
clear
echo ""
echo "📧 Seu E-mail: $email"
echo "🌐 Dominio do Traefik: $traefik"
echo "🔑 Senha do Traefik: ********"
echo "🌐 Dominio do Portainer: $portainer"
echo "🌐 Dominio do Edge: $edge"
echo "🖥️ IP do Manager: $manager_ip"
echo ""
read -p "As informações estão certas? (y/n): " confirma1
if [ "$confirma1" == "y" ]; then
  clear
  #########################################################
  # INSTALANDO DEPENDENCIAS
  #########################################################
  sudo apt update -y && sudo apt upgrade -y
  sudo apt install -y curl
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo docker swarm init --advertise-addr=$manager_ip
  mkdir -p ~/Portainer && cd ~/Portainer
  echo -e "\e[32mAtualizado/Instalado com Sucesso\e[0m"
  sleep 3
  #########################################################
  # CRIANDO REDES DOCKER SWARM
  #########################################################
  sudo docker network create --driver=overlay interlig_network
  sudo docker network create --driver=overlay interlig_traefik
  #########################################################
  # CRIANDO DOCKER-COMPOSE.YML
  #########################################################
  cat > docker-compose.yml <<EOL
version: '3.8'

services:
  traefik:
    image: "traefik:latest"
    command:
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --api.insecure=true
      - --api.dashboard=true
      - --providers.docker.swarmmode=true
      - --log.level=ERROR
      - --certificatesresolvers.lets.acme.httpchallenge=true
      - --certificatesresolvers.lets.acme.email=$email
      - --certificatesresolvers.lets.acme.storage=acme.json
      - --certificatesresolvers.lets.acme.httpchallenge.entrypoint=web
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "traefik_acme:/acme.json"
    networks:
      - interlig_traefik
    deploy:
      mode: replicated
      replicas: 1
      labels:
        - "traefik.http.routers.http-catchall.rule=hostregexp(\`{host:.+}\`)"
        - "traefik.http.routers.http-catchall.entrypoints=web"
        - "traefik.http.routers.http-catchall.middlewares=redirect-to-https"
        - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
        - "traefik.http.routers.traefik-dashboard.rule=Host(\`$traefik\`)"
        - "traefik.http.routers.traefik-dashboard.entrypoints=websecure"
        - "traefik.http.routers.traefik-dashboard.service=api@internal"
        - "traefik.http.routers.traefik-dashboard.tls.certresolver=lets"
        - "traefik.http.middlewares.traefik-auth.basicauth.users=$senha"
        - "traefik.http.routers.traefik-dashboard.middlewares=traefik-auth"
      restart_policy:
        condition: on-failure

  portainer:
    image: portainer/portainer-ce:latest
    command: -H unix:///var/run/docker.sock
    networks:
      - interlig_network
      - interlig_traefik
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    deploy:
      mode: replicated
      replicas: 1
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.frontend.rule=Host(\`$portainer\`)"
        - "traefik.http.routers.frontend.entrypoints=websecure"
        - "traefik.http.services.frontend.loadbalancer.server.port=9000"
        - "traefik.http.routers.frontend.service=frontend"
        - "traefik.http.routers.frontend.tls.certresolver=lets"
        - "traefik.http.routers.edge.rule=Host(\`$edge\`)"
        - "traefik.http.routers.edge.entrypoints=websecure"
        - "traefik.http.services.edge.loadbalancer.server.port=8000"
        - "traefik.http.routers.edge.service=edge"
        - "traefik.http.routers.edge.tls.certresolver=lets"
      restart_policy:
        condition: on-failure

volumes:
  traefik_acme:
  portainer_data:

networks:
  interlig_network:
    external: true
  interlig_traefik:
    external: true
EOL
  #########################################################
  # CERTIFICADOS LETSENCRYPT
  #########################################################
  echo -e "\e[32mInstalando certificado LetsEncrypt\e[0m"
  touch acme.json
  sudo chmod 600 acme.json
  #########################################################
  # INICIANDO STACK
  #########################################################
  sudo docker stack deploy -c docker-compose.yml my_stack
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
