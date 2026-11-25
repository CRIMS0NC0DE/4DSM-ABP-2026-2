#!/usr/bin/env bash
# Abre o app Passe no celular, pelo navegador, sem instalar nada.
#
#   bash scripts/app-no-celular.sh            usa o build do app que já existe (faz um se não houver)
#   bash scripts/app-no-celular.sh --build    refaz o build (depois de mudar o código do app)
#   IP=192.168.0.10 bash scripts/app-no-celular.sh   força o IP, se o detectado não for o da rede certa
#
# O que faz: build web do Flutter com a API em /api, certificado HTTPS para o IP do PC,
# backend no Docker e um nginx na porta 8443 que serve o app e repassa /api para a API.
# A câmera (QR) e o GPS do navegador só funcionam em HTTPS. O certificado é do próprio PC:
# o celular avisa uma vez, e é só tocar em "Avançado" e "Continuar".
set -euo pipefail
cd "$(dirname "$0")/.."

COMPOSE=(docker compose -f docker-compose.dev.yml)
PORTA=${APP_HTTPS_PORT:-8443}

IP=${IP:-$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "src") print $(i + 1)}')}
if [ -z "$IP" ]; then
  echo "Não achei o IP do PC na rede. Rode de novo com IP=<ip do PC> $0" >&2
  exit 1
fi

# Certificado: refaz quando o IP muda (outra rede, outro dia).
CERTS=docker/app-https/certs
mkdir -p "$CERTS"
if [ ! -f "$CERTS/app.crt" ] || ! openssl x509 -in "$CERTS/app.crt" -noout -ext subjectAltName 2>/dev/null | grep -q "IP Address:$IP\b"; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 30 -sha256 \
    -keyout "$CERTS/app.key" -out "$CERTS/app.crt" \
    -subj "/CN=Passe ($IP)" -addext "subjectAltName=IP:$IP,IP:127.0.0.1,DNS:localhost" 2>/dev/null
  echo "Certificado HTTPS novo para $IP."
fi

if [ "${1:-}" = "--build" ] || [ ! -f frontend/build/web/index.html ]; then
  echo "Fazendo o build do app (uns 2 minutos)..."
  (cd frontend && flutter build web --release --dart-define=API_URL=/api)
fi

"${COMPOSE[@]}" up -d database mqtt backend
"${COMPOSE[@]}" --profile celular up -d app-https
# Recarrega o nginx: pega o certificado novo, se houver.
"${COMPOSE[@]}" --profile celular exec -T app-https nginx -s reload >/dev/null 2>&1 || true

URL="https://$IP:$PORTA"
echo -n "Esperando a API responder pelo HTTPS"
for _ in $(seq 1 90); do
  if curl -ksf "$URL/api/health" >/dev/null; then
    echo " ok."
    break
  fi
  echo -n "."
  sleep 1
done
curl -ksf "$URL/api/health" >/dev/null || { echo; echo "A API não respondeu em $URL/api/health. Veja: docker compose -f docker-compose.dev.yml logs backend" >&2; exit 1; }

# QR no terminal com o endereço do app, para o celular abrir pela câmera.
node -e '
const qrcode = require("./backend/node_modules/qrcode-generator");
const q = qrcode(0, "L"); q.addData(process.argv[1]); q.make();
const n = q.getModuleCount(), m = 2;
const claro = (x, y) => x < 0 || y < 0 || x >= n || y >= n || !q.isDark(y, x);
let s = "";
for (let y = -m; y < n + m; y += 2) {
  for (let x = -m; x < n + m; x++) {
    const a = claro(x, y), b = claro(x, y + 1);
    s += a && b ? "█" : a ? "▀" : b ? "▄" : " ";
  }
  s += "\n";
}
process.stdout.write(s);
' "$URL" || true

cat <<EOF

App no celular: $URL
  1. Celular na mesma rede do PC (o Wi-Fi da sala ou o roteador do celular).
  2. Abra o endereço (ou leia o QR acima). No aviso de segurança: "Avançado" e "Continuar".
  3. Entre com uma conta de demonstração (senha passe123):
       morador@passe.com · visitante@passe.com · portaria@passe.com · admin@passe.com
  4. Permita a câmera e a localização quando o app pedir.

No PC: simulador do terminal em http://localhost:3000/simulador/
Para parar só o app HTTPS: docker compose -f docker-compose.dev.yml --profile celular stop app-https
EOF
