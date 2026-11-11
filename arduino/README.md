# Terminal da catraca (ESP32)

Código do terminal IoT do Passe: o firmware que roda na catraca e o teste de bancada usado na
montagem do kit. É um projeto PlatformIO com framework Arduino, para ESP32 DevKit (`esp32dev`).

```
arduino/
├── platformio.ini           ambientes de build (display e teste)
├── include/
│   ├── config.h             pinagem e tempos
│   ├── credenciais.exemplo.h  modelo do credenciais.h (Wi-Fi, API, broker, Id e chave)
│   ├── credenciais.h        a sua cópia preenchida, fora do git
│   └── ca_digicert_g2.h     CA do broker na nuvem (EMQX), para MQTT com TLS
├── lib/qrcodegen/           geração do QR (nayuki, MIT)
├── src/                     firmware da catraca
│   ├── main.cpp             Wi-Fi, QR da API, decisões por MQTT/HTTP, NFC, relé e heartbeat
│   ├── tela.cpp             telas no display (TFT ou OLED)
│   └── tela.h
└── testes/
    └── bancada/
        └── teste_bancada.cpp  testa LEDs, buzzer, relé, display e NFC pelo Serial
```

## Gravar

Abra a pasta `arduino/` no VS Code com a extensão PlatformIO, ou use o terminal:

```bash
cd arduino
cp include/credenciais.exemplo.h include/credenciais.h   # só na primeira vez; preencha Wi-Fi e IP do PC

pio run -e teste -t upload    # teste de bancada (não usa Wi-Fi nem credenciais.h)
pio run -e tft -t upload      # firmware com display ST7789 (padrão)
pio run -e ili9341 -t upload  # firmware com display ILI9341
pio run -e oled -t upload     # firmware com OLED SSD1306 (QR pequeno, só para teste)
pio device monitor            # Serial a 115200
```

No teste de bancada, digite no monitor serial o número do teste (1 LEDs, 2 buzzer, 3 relé,
4 display, 5 NFC, 0 todos). Encostar uma tag mostra o UID dela a qualquer momento.

O ambiente `teste` compila `testes/bancada/` junto com `src/tela.cpp`, para o display mostrar as
mesmas telas do firmware de verdade. Os outros ambientes compilam só o `src/`.

O CI (job "Firmware ESP32 · build") compila os quatro ambientes a cada push, e também o `tft` com
TLS no MQTT.

## Documentação

| Assunto | Onde |
|---|---|
| Montagem do kit passo a passo, com teste por etapa | [`docs/montagem-terminal.html`](../docs/montagem-terminal.html) |
| Lista de materiais e pinagem | [`docs/hardware.md`](../docs/hardware.md) |
| Como o firmware funciona, provisionamento e segurança do broker | [`docs/terminal-iot.md`](../docs/terminal-iot.md) |
| Rede local do protótipo (hotspot, IP do PC, firewall) | [`docs/rede-do-prototipo.md`](../docs/rede-do-prototipo.md) |
| Apontar o terminal para a nuvem | [`docs/deploy-nuvem.md`](../docs/deploy-nuvem.md) |

## Código do terminal que fica no backend

Estes arquivos também tratam do terminal, mas são Node.js e dependem das bibliotecas do backend,
por isso ficam lá:

| Arquivo | Para quê |
|---|---|
| `backend/scripts/provisionar-terminal.mjs` | Cadastra o terminal e grava `TERMINAL_ID`/`TERMINAL_KEY` em `arduino/include/credenciais.h` |
| `backend/scripts/mqtt-acl.mjs` | Teste do broker: login, ACL e TLS (roda no CI) |
| `backend/scripts/mqtt-senha.mjs` | Gera a senha de um terminal no `docker/mosquitto/passwd` |
| `backend/public/simulador/` | Simulador web do terminal, faz o mesmo que este firmware |
