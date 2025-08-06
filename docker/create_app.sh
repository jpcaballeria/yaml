#!/bin/bash

# --- Validação Inicial ---
if [ -z "$1" ]; then
  echo "❌ Erro: Forneça um nome para o novo aplicativo."
  echo "   Uso: ./create_app.sh <nome_do_app>"
  exit 1
fi

APP_NAME=$1
COMPOSE_DIR="/home/compose/$APP_NAME"
SAAS_DIR="/home/saas/$APP_NAME"
NGINX_TEMPLATE="/home/saas/app1/nginx.conf" # Usando um template existente como base

if [ -d "$COMPOSE_DIR" ] || [ -d "$SAAS_DIR" ]; then
  echo "❌ Erro: O diretório '$APP_NAME' já existe em '/home/compose' ou '/home/saas'. Escolha outro nome."
  exit 1
fi

echo "🚀 Criando estrutura para o aplicativo: $APP_NAME"

# --- 1. Criação de Diretórios e Arquivos de Configuração ---
mkdir -p "$COMPOSE_DIR"
echo "-> Diretório '$COMPOSE_DIR' criado."

mkdir -p "$SAAS_DIR/app"
echo "-> Diretório '$SAAS_DIR/app' criado."

# Substitui a referência ao serviço PHP no template do Nginx
sed "s/app1_php/${APP_NAME}_php/g" "$NGINX_TEMPLATE" > "$SAAS_DIR/nginx.conf"
echo "-> Arquivo de configuração '$SAAS_DIR/nginx.conf' criado."

touch "$SAAS_DIR/app/index.php"
echo "-> Arquivo inicial '$SAAS_DIR/app/index.php' criado."

# --- 2. Geração de Senha Segura para o Banco de Dados ---
DB_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 20)
echo "-> Senha segura gerada para o banco de dados."

# --- 3. Geração do Arquivo docker-compose.yml ---
cat <<EOF > "${COMPOSE_DIR}/docker-compose.yml"
version: '3.8'

services:
  ${APP_NAME}_nginx:
    image: nginx:latest
    container_name: ${APP_NAME}_nginx
    restart: unless-stopped
    volumes:
      - ${SAAS_DIR}/app:/var/www/html
      - ${SAAS_DIR}/nginx.conf:/etc/nginx/conf.d/default.conf
    networks:
      - saas_net

  ${APP_NAME}_php:
    build: /home/compose/php_config
    container_name: ${APP_NAME}_php
    restart: unless-stopped
    volumes:
      - ${SAAS_DIR}/app:/var/www/html
    networks:
      - saas_net

  ${APP_NAME}_db:
    image: mysql:8.0
    container_name: ${APP_NAME}_db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: "${DB_PASSWORD}"
      MYSQL_DATABASE: "saas_${APP_NAME}"
      MYSQL_USER: "${APP_NAME}"
      MYSQL_PASSWORD: "${DB_PASSWORD}"
    volumes:
      - ${APP_NAME}_db_data:/var/lib/mysql
    networks:
      - saas_net

networks:
  saas_net:
    name: saas_net
    external: true

volumes:
  ${APP_NAME}_db_data:

EOF

echo "-> Arquivo '${COMPOSE_DIR}/docker-compose.yml' criado com sucesso."

# --- 4. Mensagem Final com Próximos Passos ---
echo ""
echo "✅ Estrutura para '$APP_NAME' criada com sucesso!"
echo ""
echo "💡 Próximos Passos:"
echo "1. (Opcional) Verifique o arquivo: '${COMPOSE_DIR}/docker-compose.yml'"
echo "2. Coloque os arquivos da sua aplicação no diretório: '${SAAS_DIR}/app/'"
echo "3. Suba o novo ambiente com:"
echo "   cd ${COMPOSE_DIR}"
echo "   docker-compose up -d --build"
echo ""
echo "   Lembre-se que a rede 'saas_net' e o túnel são gerenciados em '/home/compose/shared/'"
echo ""
echo "🔑 Senha gerada para o banco de dados de '$APP_NAME': $DB_PASSWORD"
echo "   (Esta senha foi adicionada automaticamente ao docker-compose.yml)"

