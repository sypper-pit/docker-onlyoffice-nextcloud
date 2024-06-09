#!/bin/bash

set -x

# Проверяем, добавлен ли уже сервер nginx в trusted_domains
docker exec -u www-data app-server php occ --no-warnings config:system:get trusted_domains >> trusted_domain.tmp

if ! grep -q "nginx-server" trusted_domain.tmp; then
    TRUSTED_INDEX=$(cat trusted_domain.tmp | wc -l)
    docker exec -u www-data app-server php occ --no-warnings config:system:set trusted_domains $TRUSTED_INDEX --value="nginx-server"
fi

rm trusted_domain.tmp

# Устанавливаем OnlyOffice и настраиваем его
docker exec -u www-data app-server php occ --no-warnings app:install onlyoffice

docker exec -u www-data app-server php occ --no-warnings config:system:set onlyoffice DocumentServerUrl --value="/ds-vpath/"
docker exec -u www-data app-server php occ --no-warnings config:system:set onlyoffice DocumentServerInternalUrl --value="http://onlyoffice-document-server/"
docker exec -u www-data app-server php occ --no-warnings config:system:set onlyoffice StorageUrl --value="http://nginx-server/"
docker exec -u www-data app-server php occ --no-warnings config:system:set onlyoffice jwt_secret --value="secret"

# Добавляем конфигурацию Redis
REDIS_CONFIG="\\\$CONFIG = array (
  'memcache.local' => '\\\\OC\\\\Memcache\\\\Redis',
  'redis' => array(
    'host' => 'redis',
    'port' => 6379,
  ),
);"

docker exec -u www-data app-server bash -c "echo \"$REDIS_CONFIG\" >> /var/www/html/config/config.php"
