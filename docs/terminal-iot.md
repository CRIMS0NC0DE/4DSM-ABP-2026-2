# Terminal IoT da catraca

Como o terminal (ESP32) funciona, onde o QR é gerado, como provisionar um terminal
e como o broker MQTT está protegido. Hardware em [hardware.md](hardware.md), rede em
[rede-do-prototipo.md](rede-do-prototipo.md).

## Decisão: onde o QR Code é gerado

**O backend gera o conteúdo; o terminal desenha o QR localmente.** Nenhuma imagem
trafega pela rede.

| Opção | Como seria | Por que não / por que sim |
|---|---|---|
| A. Backend gera a **imagem** e manda ao terminal | PNG/bitmap a cada 10 s | Descartada. O ESP32 teria de baixar e decodificar imagem (PNG pede mais RAM que a lib de QR), o tráfego cresce, e não há ganho: transformar texto em QR no ESP32 leva milissegundos. |
| B. Terminal gera **tudo sozinho** (estilo TOTP: HMAC de um segredo + horário) | Funciona sem rede para o QR | Descartada. Exige relógio sincronizado (NTP) no ESP32 e o segredo do QR em texto puro no dispositivo e no servidor. O ganho de funcionar sem rede não existe: sem rede o celular não valida e a decisão não chega à catraca. |
| **C. Backend gera o texto assinado, terminal desenha** | `GET /terminal/qr-token` a cada 10 s; o ESP32 transforma o texto em módulos | **Escolhida.** Mantém "quem decide é sempre o backend", o segredo nunca sai do servidor, o uso único (nonce) continua controlado no banco, e o firmware fica simples. |

### O formato do token

O conteúdo era um JWT de 263 caracteres, que vira um QR versão 10 (57×57 módulos),
grande demais para um display pequeno. Agora é um token compacto assinado com HMAC:

```
P1.AAAAAAAAABAABAAAAAAAAAAAAU.TNBFNK.ZIIJ7VSSEKJGPBSZ.XYZXORKDKZTWKXKNG7CS2OKO
│  │                          │      │                └ assinatura HMAC-SHA256 (120 bits)
│  │                          │      └ nonce de uso único (80 bits) = jti
│  │                          └ vence em (segundos unix, base36)
│  └ Id do terminal (UUID em base32)
└ versão do formato
```

- 78 caracteres, só `A-Z`, `0-9` e `.`: usa o **modo alfanumérico** do QR e cabe na
  **versão 4 (33×33)** com correção M. Num TFT de 240 px, cada módulo fica com 5 px.
- Trocar qualquer campo (terminal, validade) invalida a assinatura → `QR_INVALIDO`.
- Vencido → `QR_EXPIRADO`. Reutilizado → `QR_JA_UTILIZADO` (nonce gravado no banco).
- Código: `backend/src/modules/terminals/qr-token.ts`. O app não muda: continua
  mandando o texto lido em `POST /access/qr {token}`.

## Firmware (`firmware/`)

PlatformIO + Arduino para ESP32 DevKit. O que ele faz, na ordem do `loop()`:

1. Mantém Wi-Fi e MQTT conectados (login no broker: usuário = Id do terminal, senha = chave).
2. Pede o QR (`GET /terminal/qr-token`) e redesenha a cada `trocarEmSegundos`.
3. Recebe `ABRIR`/`NEGAR` em `passe/terminais/{id}/decisoes`; no `ABRIR` liga o relé por 3 s,
   acende o LED verde e bipa; no `NEGAR`, LED vermelho e dois bipes. Depois mostra um QR novo.
4. Sem MQTT, consulta `GET /terminal/decisions?apos=seq` a cada 2 s (mesma lógica do simulador).
5. Lê tag NFC (MFRC522) e manda o UID em `POST /terminal/nfc`; a decisão vem na resposta.
6. Heartbeat (`POST /terminal/heartbeat`) a cada 30 s: o painel mostra o terminal como online.

```bash
cd firmware
cp include/credenciais.exemplo.h include/credenciais.h   # Wi-Fi, IP do PC, Id e chave
pio run -e tft -t upload        # ST7789 (recomendado); ou -e ili9341 / -e oled
pio device monitor              # log serial a 115200
```

Pinos e tempos ficam em `firmware/include/config.h`. Bibliotecas: PubSubClient,
ArduinoJson, MFRC522, Adafruit GFX + driver do display, e a
[qrcodegen](https://www.nayuki.io/page/qr-code-generator-library) (MIT) em `lib/`.

## Provisionar um terminal (issue #8)

Cada catraca tem um terminal; a chave dele aparece **uma única vez**. O script faz o
cadastro e já grava a chave onde ela é usada:

```bash
cd backend
node scripts/provisionar-terminal.mjs                       # lista catracas e terminais (online/offline)
node scripts/provisionar-terminal.mjs --catraca <id> --nome "Terminal Catraca 2" \
     --lat -23.3053 --lng -45.9658 --raio 100                # cadastra (e corrige a posição da catraca)
node scripts/provisionar-terminal.mjs --trocar-chave <terminalId>   # chave nova; a antiga para na hora
```

O script grava `TERMINAL_ID`/`TERMINAL_KEY` em `firmware/include/credenciais.h` e o
login do terminal em `docker/mosquitto/passwd`. Depois:

1. `docker compose -f docker-compose.dev.yml restart mqtt`
2. Grave o firmware.
3. Rode o script sem argumentos: o terminal aparece **online** depois do primeiro heartbeat.

A posição da catraca importa: a API nega quem estiver a mais de `raioMetros` dela.
Pegue a coordenada no Google Maps (botão direito no ponto → copiar coordenadas).

Para a demonstração com a Catraca 1 do seed, que já tem o terminal demo, basta
`--trocar-chave 00000000-0000-4000-8000-000000000005` (o `npm run db:seed` volta a chave demo).

## Broker MQTT protegido (issue #10)

| Camada | Como |
|---|---|
| Autenticação | `allow_anonymous false`; senhas em `docker/mosquitto/passwd` (PBKDF2-SHA512). A API entra como `passe-api`; cada terminal com usuário = Id e senha = chave. |
| ACL (`docker/mosquitto/acl`) | Só `passe-api` publica em `passe/terminais/+/decisoes`. Cada terminal só lê `passe/terminais/<seu Id>/decisoes`. Ninguém consegue publicar um `ABRIR` falso. |
| TLS | `sh docker/mosquitto/gerar-certificados.sh <IP do PC>` cria uma CA própria, o certificado do servidor e liga a porta **8883**. API: `MQTT_URL=mqtts://...:8883` + `MQTT_CA_FILE`. Firmware: `MQTT_PORT 8883` + `MQTT_CA_CERT` com o conteúdo de `certs/ca.crt`. |

Senhas novas sem Docker: `node backend/scripts/mqtt-senha.mjs <usuario> <senha> docker/mosquitto/passwd`.
O `passwd` versionado tem só as credenciais de desenvolvimento (API `passe-api-dev` e o
terminal demo); em produção gere outro e não versione.

Teste (também roda no CI, job "Broker MQTT"):

```bash
cd backend
MQTT_URL=mqtt://localhost:1883 node scripts/mqtt-acl.mjs
MQTT_URL=mqtts://localhost:8883 MQTT_CA_FILE=../docker/mosquitto/certs/ca.crt node scripts/mqtt-acl.mjs
```

Ele confere: anônimo recusado, senha errada recusada, terminal recebe a decisão da API,
não recebe a de outro terminal e não consegue publicar `ABRIR`.

Para produção: deixe só o listener 8883 (remova 1883 e 9001 do `mosquitto.conf`) e
troque a senha do `passe-api`.
