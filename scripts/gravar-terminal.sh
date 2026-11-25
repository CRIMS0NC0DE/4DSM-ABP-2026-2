#!/usr/bin/env bash
# Grava o firmware do terminal (ESP32 com OLED) apontando para este PC.
#
#   bash scripts/gravar-terminal.sh
#       troca API_URL e MQTT_HOST do credenciais.h pelo IP atual do PC e grava
#   WIFI_SSID="Rede" WIFI_SENHA="senha" bash scripts/gravar-terminal.sh
#       também troca o Wi-Fi (ex.: o roteador do celular)
#   AMBIENTE=tft bash scripts/gravar-terminal.sh      outro display (padrão: oled)
#   IP=192.168.0.10 bash scripts/gravar-terminal.sh   força o IP
#
# O ESP32 precisa estar no USB (/dev/ttyUSB0). A chave do terminal não muda aqui:
# ela continua a do credenciais.h, que é a mesma do broker e do TERMINAL_DEMO_KEY.
set -euo pipefail
cd "$(dirname "$0")/.."

CRED=arduino/include/credenciais.h
AMBIENTE=${AMBIENTE:-oled}
PORTA=${PORTA:-/dev/ttyUSB0}

[ -f "$CRED" ] || cp arduino/include/credenciais.exemplo.h "$CRED"

IP=${IP:-$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "src") print $(i + 1)}')}
if [ -z "$IP" ]; then
  echo "Não achei o IP do PC na rede. Rode de novo com IP=<ip do PC> $0" >&2
  exit 1
fi

# Troca só o valor entre aspas de cada #define (o resto do arquivo fica igual).
definir() {
  local nome=$1 valor=$2
  python3 - "$CRED" "$nome" "$valor" <<'EOF'
import re, sys
arquivo, nome, valor = sys.argv[1:]
texto = open(arquivo, encoding='utf8').read()
valor = valor.replace('\\', '\\\\').replace('"', '\\"')  # string C
novo, n = re.subn(rf'^(#define {nome} )"(?:[^"\\]|\\.)*"', lambda m: f'{m.group(1)}"{valor}"', texto, flags=re.M)
if n != 1:
    sys.exit(f'{nome} não encontrado em {arquivo}')
open(arquivo, 'w', encoding='utf8').write(novo)
EOF
}

definir API_URL "http://$IP:3000"
definir MQTT_HOST "$IP"
[ -n "${WIFI_SSID:-}" ] && definir WIFI_SSID "$WIFI_SSID"
[ -n "${WIFI_SENHA:-}" ] && definir WIFI_SENHA "$WIFI_SENHA"

ssid=$(sed -n 's/^#define WIFI_SSID "\(.*\)"/\1/p' "$CRED")
echo "Terminal vai usar: Wi-Fi \"$ssid\", API http://$IP:3000, MQTT $IP:1883 (ambiente $AMBIENTE)"
if command -v nmcli >/dev/null; then
  atual=$(nmcli -t -f active,ssid dev wifi list --rescan no 2>/dev/null | sed -n 's/^\(sim\|yes\)://p' | head -1)
  if [ -n "$atual" ] && [ "$atual" != "$ssid" ]; then
    echo "Atenção: o PC está no Wi-Fi \"$atual\". O ESP32 e o PC precisam estar na mesma rede." >&2
  fi
fi

if [ ! -e "$PORTA" ]; then
  echo "O ESP32 não está em $PORTA. Ligue o cabo USB de dados (o outro só carrega) e rode de novo." >&2
  exit 1
fi
if command -v fuser >/dev/null && fuser "$PORTA" >/dev/null 2>&1; then
  echo "Outro programa está usando $PORTA (monitor serial aberto?). Feche e rode de novo." >&2
  exit 1
fi

(cd arduino && pio run -e "$AMBIENTE" -t upload --upload-port "$PORTA")
echo
echo "Gravado. Em uns 10 s o OLED mostra \"Conectando\" e depois o QR."
echo "Para ver o que ele faz: cd arduino && pio device monitor -p $PORTA"
echo "Para conferir tudo: node backend/scripts/checar-apresentacao.mjs"
