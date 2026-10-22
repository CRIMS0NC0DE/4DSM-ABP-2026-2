#!/bin/sh
# Copia a configuração montada (somente leitura) para dentro do contêiner e
# entrega os arquivos de senha e ACL ao usuário mosquitto com permissão 0600.
# O Mosquitto 2.1 avisa (e as próximas versões recusam) arquivos de senha que
# não sejam dele. Depois de mudar passwd ou acl: docker compose restart mqtt.
set -e
mkdir -p /mosquitto/config
cp -R /mosquitto/origem/. /mosquitto/config/
chown -R mosquitto:mosquitto /mosquitto/config
chmod 0600 /mosquitto/config/passwd /mosquitto/config/acl
[ -f /mosquitto/config/certs/servidor.key ] && chmod 0600 /mosquitto/config/certs/servidor.key
exec mosquitto -c /mosquitto/config/mosquitto.conf
