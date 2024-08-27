# Instalador Docker Swarm, Traefik e Portainer

Este repositório contém um script de instalação automatizado para configurar um ambiente Docker Swarm com o Traefik como proxy reverso e Portainer para gerenciamento de containers.

## Requisitos

- Um servidor com sistema operacional baseado em Debian.
- Acesso root ou permissão sudo no servidor.

## Funcionalidades

- **Instalação e configuração automática do Docker Swarm**.
- **Criação de redes Docker Swarm**: `traefik_public` e `agent_network`.
- **Implantação automática de stacks**:
  - Traefik: Configurado como proxy reverso com suporte a TLS via Let's Encrypt.
  - Portainer: Ferramenta de gerenciamento de containers Docker com integração ao Traefik.

## Como usar

### 1. Clone o repositório

```bash
git clone https://github.com/wnegreiros/instalador-docker-swarm.git
cd instalador-docker-swarm
```

### 2. Torne o script executável

```bash
chmod +x install_docker_swarm.sh
```

### 3. Execute o script

```bash
./install_docker_swarm.sh
```

### 4. Preencha as informações solicitadas

O script solicitará as seguintes informações:

- 📧 **Endereço de e-mail**: Usado para o gerenciamento de certificados TLS com Let's Encrypt.
- 🌐 **Domínio do Portainer**: O domínio onde o Portainer estará acessível.
- 🖥️ **IP do Manager**: IP do servidor que será o manager do Docker Swarm.

### 5. Confirmação de dados

Revise as informações inseridas e confirme para prosseguir com a instalação.

### 6. Acesso

- **Portainer**: Acesse o Portainer via [http://portainer.seudominio.com](http://portainer.seudominio.com) (substitua pelo domínio que você configurou).
- **Traefik**: O painel do Traefik estará disponível na porta 8080 do seu servidor.

## Estrutura do Repositório

- **install_docker_swarm.sh**: Script principal para instalação e configuração.
- **traefik-stack.yml**: Stack YAML para configuração do Traefik.
- **portainer-stack.yml**: Stack YAML para configuração do Portainer.

## Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou enviar pull requests.

## Licença

Este projeto é licenciado sob a [MIT License](LICENSE).
```

Este `README.md` fornece uma visão geral clara do projeto, instruções de uso e outras informações relevantes. Você pode personalizá-lo conforme necessário para atender às necessidades específicas do seu repositório.
