#!/bin/sh
# Liga o TLS do broker (porta 8883). Cria uma CA própria e o certificado do
# servidor, e escreve conf.d/tls.conf. Nada disso vai para o git.
#
#   sh docker/mosquitto/gerar-certificados.sh 192.168.0.10 meu-pc.local
#
# Passe o IP do PC na rede (e nomes, se houver): o ESP32 confere se o endereço
# que ele usa está no certificado. Grave certs/ca.crt no firmware (MQTT_CA_CERT)
# e use MQTT_CA_FILE=docker/mosquitto/certs/ca.crt na API (mqtts://...:8883).
set -e
cd "$(dirname "$0")"
mkdir -p certs conf.d

SAN="DNS:localhost,DNS:mqtt,IP:127.0.0.1"
for host in "$@"; do
  case "$host" in
    *[!0-9.]*) SAN="$SAN,DNS:$host" ;;
    *) SAN="$SAN,IP:$host" ;;
  esac
done

# MSYS_NO_PATHCONV: no Git Bash do Windows, "/CN=..." não vira caminho.
export MSYS_NO_PATHCONV=1

if [ ! -f certs/ca.key ]; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -sha256 \
    -keyout certs/ca.key -out certs/ca.crt -subj "/CN=Passe CA"
fi

openssl req -newkey rsa:2048 -nodes -sha256 \
  -keyout certs/servidor.key -out certs/servidor.csr -subj "/CN=passe-mqtt"
printf 'subjectAltName=%s\nextendedKeyUsage=serverAuth\n' "$SAN" > certs/servidor.ext
openssl x509 -req -in certs/servidor.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial \
  -days 825 -sha256 -extfile certs/servidor.ext -out certs/servidor.crt
rm -f certs/servidor.csr certs/servidor.ext

cat > conf.d/tls.conf <<'CONF'
# Gerado por gerar-certificados.sh
listener 8883
protocol mqtt
cafile /mosquitto/config/certs/ca.crt
certfile /mosquitto/config/certs/servidor.crt
keyfile /mosquitto/config/certs/servidor.key
tls_version tlsv1.2
CONF

echo "TLS pronto ($SAN). Reinicie o broker: docker compose -f docker-compose.dev.yml restart mqtt"
