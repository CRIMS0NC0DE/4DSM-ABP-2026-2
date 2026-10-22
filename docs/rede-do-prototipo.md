# Rede do protótipo (issue #7)

## Decisão: rede local para o protótipo

O ESP32 fala com a API e o broker rodando no PC, na mesma rede Wi-Fi. A nuvem fica
para depois porque:

- O Render hospeda a API (HTTP), mas **não expõe TCP puro** para um Mosquitto: o
  broker teria de ir para outro serviço (HiveMQ Cloud, EMQX Cloud ou uma VM).
- Na demonstração, rede local não depende da internet da faculdade nem do plano gratuito
  "dormindo" (o Render gratuito desliga a API depois de 15 min parada).
- O firmware só precisa trocar `API_URL` e `MQTT_HOST` para ir para a nuvem depois.

| Serviço | Porta no PC | Quem usa |
|---|---|---|
| API | 3000 | app e ESP32 (`API_URL=http://<IP do PC>:3000`) |
| MQTT | 1883 | ESP32 |
| MQTT com TLS | 8883 | ESP32 e API, depois de gerar os certificados |
| MQTT WebSocket | 9001 | simulador no navegador |

## Passo a passo no Windows

1. **Firewall e portas** (PowerShell como administrador, uma vez):
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\preparar-rede-windows.ps1
   ```
   Ele libera 3000, 1883, 8883 e 9001 para redes privadas e mostra o IP do PC.
   Se o Wi-Fi estiver como rede "Pública", troque para "Privada".

2. **Porta 1883 bloqueada?** Se o `docker compose` disser
   `bind: An attempt was made to access a socket in a way forbidden`, o Windows
   reservou a porta para o Hyper-V/WSL. Veja com
   `netsh interface ipv4 show excludedportrange protocol=tcp`. Isso acontece quando a
   faixa de portas dinâmicas começa em 1024 em vez de 49152. Duas saídas:
   - definitiva: rodar o script com `-CorrigirPortas` e reiniciar o PC;
   - rápida: usar outra porta no host, `MQTT_PORT=11883 docker compose ... up` e
     `MQTT_PORT 11883` no firmware.

3. **IP fixo.** Reserve o IP do PC no roteador (DHCP estático) ou anote o IP antes de
   gravar o firmware; se ele mudar, o ESP32 perde a API.

4. **Subir tudo:**
   ```bash
   docker compose -f docker-compose.dev.yml up -d database mqtt
   cd backend && npm run dev
   ```

5. **Testar de outro aparelho** (celular no mesmo Wi-Fi): abrir `http://<IP do PC>:3000/health`.
   Para conferir o que o ESP32 vai fazer, de outro PC na rede:
   ```bash
   curl http://<IP>:3000/terminal/qr-token -H "X-Terminal-Id: <id>" -H "X-Terminal-Key: <chave>"
   MQTT_URL=mqtt://<IP>:1883 node backend/scripts/mqtt-acl.mjs
   ```

Rede da faculdade com isolamento de clientes (um aparelho não enxerga o outro) não
serve: use o roteador de celular (hotspot) para o PC e o ESP32.

## Indo para a nuvem depois

1. Render: Web Service com a imagem do GHCR (o CI já publica) + Postgres do Render;
   secret `RENDER_DEPLOY_HOOK_URL` no GitHub.
2. Broker gerenciado com TLS (HiveMQ Cloud ou EMQX Cloud, plano gratuito): criar os
   usuários `passe-api` e um por terminal, com a mesma ACL de `docker/mosquitto/acl`.
3. API: `MQTT_URL=mqtts://...:8883`, `MQTT_USERNAME`, `MQTT_PASSWORD`.
4. Firmware: `API_URL "https://..."`, `MQTT_HOST`, `MQTT_PORT 8883` e as CAs.
