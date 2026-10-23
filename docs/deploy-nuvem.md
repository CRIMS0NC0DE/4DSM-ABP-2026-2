# Deploy na nuvem

Produção = branch `main`. Cada merge passa pelo CI e, com tudo verde, o job
**Deploy (main)** publica a imagem no GHCR e chama o Deploy Hook do Render.

| Peça | Serviço | Endereço |
|---|---|---|
| API (Docker, `backend/Dockerfile`) | Render, Web Service grátis, Oregon | https://passe-api-vlzh.onrender.com |
| Postgres | Neon, grátis, São Paulo | connection string do *pooler* |
| Broker MQTT | EMQX Cloud Serverless, grátis, Frankfurt | `re211f91.ala.eu-central-1.emqxsl.com` |

O Render não aceita conexão MQTT de fora (só HTTP), por isso o broker fica no EMQX.
O HiveMQ Cloud Serverless foi descontinuado e não aceita clusters novos.

## Render

- Root Directory `backend`, runtime Docker, branch `main`, Health Check `/health`.
- **Auto-Deploy: Off.** Quem dispara é o CI pelo hook: copie a URL em
  Settings → Deploy Hook e cadastre como secret `RENDER_DEPLOY_HOOK_URL` dentro do
  environment **`producao`** do GitHub (Settings → Environments). Sem o secret o
  job só avisa e não falha, e o deploy precisa ser manual.
- Variáveis (sem aspas e sem espaço no fim):

```
DATABASE_URL=postgresql://...neon.tech/neondb?sslmode=require
JWT_SECRET=<aleatório>
QR_SECRET=<aleatório>
APP_TIMEZONE=America/Sao_Paulo
CORS_ORIGIN=*
MQTT_URL=mqtts://re211f91.ala.eu-central-1.emqxsl.com:8883
MQTT_USERNAME=passe-api
MQTT_PASSWORD=<senha do passe-api no EMQX>
MQTT_WS_URL=wss://re211f91.ala.eu-central-1.emqxsl.com:8084/mqtt
```

Segredos: `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`.
`NODE_ENV` e `PORT` não entram: o Dockerfile já define `production` e o Render
define a porta.

## EMQX

- Access Control → Authentication: `passe-api` (o backend) e um usuário por
  terminal, com **usuário = Id do terminal** e **senha = chave do terminal**.
- 8883 é MQTT com TLS (API e ESP32); 8084 é WebSocket com TLS (simulador). O
  Serverless não tem porta sem TLS.
- O ESP32 confere o certificado com a CA DigiCert Global Root G2, que está em
  `firmware/include/ca_digicert_g2.h`.

## Dados e terminal em produção

O seed não roda no Render (usa `tsx`, que não vai para a imagem). Rode do PC, na
pasta `backend` (PowerShell):

```powershell
$env:DATABASE_URL = "<connection string do Neon>"
npm run db:seed
Remove-Item Env:DATABASE_URL
```

Depois do seed, troque a senha do admin e a chave do terminal de demonstração, que
estão no repositório:

```powershell
$env:API_URL = "https://passe-api-vlzh.onrender.com"
$env:ADMIN_SENHA = "<senha atual do admin>"
node scripts/provisionar-terminal.mjs --trocar-chave 00000000-0000-4000-8000-000000000005
Remove-Item Env:API_URL, Env:ADMIN_SENHA
```

O script grava a chave em `firmware/include/credenciais.h` e em
`docker/mosquitto/passwd`. Esse segundo arquivo é do Mosquitto local: desfaça com
`git restore docker/mosquitto/passwd`. Cadastre a chave nova no EMQX.

## Armadilhas que já aconteceram

| Sintoma no log do Render | Causa |
|---|---|
| `Invalid option ... at NODE_ENV` | valor com espaço, aspas ou maiúscula; apague a variável |
| `Error: Missing protocol` (mqtt) | `MQTT_URL` sem `mqtts://` ou com aspas |
| `MQTT: connack timeout` | `MQTT_URL` na porta 8084 (WebSocket); o certo é 8883 |
| `P1010 User was denied access` no login, mas as migrations passam | `DATABASE_URL` sem `?sslmode=require`: o driver `pg` conecta sem TLS e o Neon recusa (código 28000) |
| `ECONNRESET` no seed, do PC | Neon acordando ou rede bloqueando o 5432; rode de novo |

O Render grátis dorme depois de 15 min sem acesso e leva uns 50 s para acordar. Com
o ESP32 ligado (heartbeat a cada 30 s) ele fica acordado; antes de uma demo, abra o
`/health`.

## Pendente

- ACL no EMQX (Access Control → Authorization): hoje um terminal consegue assinar o
  tópico de outro. Regras: `passe-api` publica em `passe/terminais/+/decisoes`;
  cada terminal só assina `passe/terminais/<id dele>/decisoes`; o resto em
  `passe/terminais/#` negado.
- Trocar as senhas `passe123` das contas de demonstração antes da entrega.
