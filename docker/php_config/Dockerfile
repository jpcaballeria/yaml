# 1. Use a imagem oficial do PHP 8.3-FPM como base
FROM php:8.3-fpm

# 2. Atualizar o sistema e instalar dependências necessárias
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# 3. Instale as extensões MySQL do PHP
RUN docker-php-ext-install mysqli pdo pdo_mysql

# 4. Configurar timezone
RUN echo "date.timezone = America/Sao_Paulo" > /usr/local/etc/php/conf.d/timezone.ini

# 5. ADICIONE ESTA LINHA: Copiar a configuração corrigida do PHP-FPM
COPY www.conf /usr/local/etc/php-fpm.d/www.conf

# 6. Verificar extensões instaladas (para debug)
RUN php -m | grep -E "(pdo|mysql)" || echo "Extensões MySQL não encontradas"
