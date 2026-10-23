# Hardware do protótipo da catraca (issue #9)

Proposta de hardware e pinagem usada pelo firmware (`firmware/include/config.h`).
A coluna "Temos?" é para conferir com o kit antes de comprar.

## Lista de materiais

| Item | Modelo sugerido | Para quê | Temos? | Preço aprox. |
|---|---|---|---|---|
| Microcontrolador | ESP32 DevKit (ESP32-WROOM-32, 30 ou 38 pinos) | Wi-Fi, MQTT, HTTP | | R$ 45 |
| Display | **TFT ST7789 240×240 1.54" com pino CS** (ou ILI9341 2.4"/2.8" 240×320) | Mostrar o QR rotativo | | R$ 35–60 |
| Leitor NFC | MFRC522 (RC522) 13,56 MHz + tags/cartões MIFARE | Acesso por tag | | R$ 15 |
| Relé | Módulo relé 1 canal 5 V com optoacoplador | "Abrir" a catraca | | R$ 10 |
| Catraca simulada | Trava solenoide 12 V **ou** LED/servo na demo | Mostrar a abertura | | R$ 0–35 |
| Sinalização | LED verde, LED vermelho, 2× resistor 220 Ω, buzzer ativo 5 V | Feedback visual e sonoro | | R$ 5 |
| Protoboard e jumpers | 830 pontos + jumpers M-M/M-F | Montagem | | R$ 25 |
| Alimentação | Fonte USB 5 V 2 A (cabo micro-USB/USB-C do DevKit); fonte 12 V só se usar trava | | | R$ 20 |

**Sobre o display.** O QR (versão 4, 33×33 módulos) precisa de pelo menos ~4 px por
módulo para o celular ler de uns 20 cm: um TFT de 240 px dá 5 px. O OLED 0,96"
(128×64) dá 1 px por módulo (QR de ~6 mm): serve para teste de bancada, não para a
demonstração. Evite o ST7789 1.3" **sem pino CS**: ele não divide o barramento SPI
com o leitor NFC.

**Sobre o NFC.** O MFRC522 é o mais barato e comum nos kits; funciona em 3,3 V
(**não ligue em 5 V**). O PN532 (I2C/SPI) também serviria, mas exige trocar a biblioteca.

## Pinagem (ESP32 DevKit V1)

O display e o NFC dividem o barramento SPI (VSPI); cada um tem o seu CS.

| Sinal | GPIO | Liga em |
|---|---|---|
| SPI SCK | 18 | TFT SCL/SCK · RC522 SCK |
| SPI MOSI | 23 | TFT SDA/MOSI · RC522 MOSI |
| SPI MISO | 19 | RC522 MISO (o TFT não usa) |
| TFT CS | 5 | TFT CS |
| TFT DC | 16 | TFT DC/RS |
| TFT RST | 17 | TFT RES |
| TFT BL | 3V3 | TFT BLK (luz de fundo sempre ligada) |
| NFC SS | 32 | RC522 SDA/SS |
| NFC RST | 13 | RC522 RST |
| Relé | 26 | IN do módulo relé |
| LED verde | 25 | LED verde + resistor 220 Ω → GND |
| LED vermelho | 27 | LED vermelho + resistor 220 Ω → GND |
| Buzzer | 4 | + do buzzer ativo (− no GND) |
| OLED SDA / SCL | 21 / 22 | só no ambiente `oled` |

Alimentação: TFT e RC522 no **3V3** do DevKit; módulo relé no **VIN (5 V)**, com o
jumper JD-VCC/VCC no lugar. GND comum para tudo. A maioria dos módulos de relé
liga com nível LOW (`RELE_LIGADO LOW` no `config.h`).

Pinos evitados de propósito: 0, 2, 12 e 15 (definem o modo de boot), 6–11 (flash),
34–39 (só entrada).

```
                 ESP32 DevKit V1
             ┌─────────────────────┐
   TFT CS ───┤ 5               3V3 ├─── TFT VCC/BLK, RC522 3.3V
  SPI SCK ───┤ 18              GND ├─── GND comum
 SPI MISO ───┤ 19              VIN ├─── Relé VCC (5 V)
 SPI MOSI ───┤ 23               13 ├─── RC522 RST
   TFT DC ───┤ 16               32 ├─── RC522 SDA/SS
  TFT RST ───┤ 17               26 ├─── Relé IN
   Buzzer ───┤ 4                25 ├─── LED verde
             │                  27 ├─── LED vermelho
             └─────────────────────┘
```

## Ambiente do firmware

PlatformIO (VS Code) com framework Arduino, `platform = espressif32@6.9.0`.
Bibliotecas (instaladas sozinhas pelo `platformio.ini`): PubSubClient (MQTT),
ArduinoJson, MFRC522, Adafruit GFX + driver do display; geração do QR com
`qrcodegen` (nayuki, MIT) em `firmware/lib/`. O CI compila o firmware a cada push.

## Demonstração

Sem trava física, o relé aciona um LED (ou um servo de 9 g girando 90°) que faz o
papel da catraca. O clique do relé + LED verde + bipe já mostram a abertura. Com a
trava solenoide 12 V: fonte 12 V → COM do relé, NO → trava, trava → GND da fonte,
com um diodo 1N4007 em paralelo com a trava (catodo no +).
