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

# Добавляем конфигурацию Redis, если она еще не добавлена
REDIS_CONFIG="\n  'memcache.local' => '\\OC\\Memcache\\Redis',\n  'redis' => array(\n    'host' => 'redis',\n    'port' => 6379,\n  ),"

# Проверяем, есть ли конфигурация Redis
if ! docker exec -u www-data app-server grep -q "'redis'" /var/www/html/config/config.php; then
    docker exec -u www-data app-server bash -c "sed -i \"s|);|$REDIS_CONFIG\n);|\" /var/www/html/config/config.php"
fi
