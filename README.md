# Passe — controle de acesso por QR e NFC

ABP do 4º semestre de DSM da FATEC (2026-2). O Passe libera catracas e portas de um condomínio pelo celular (QR dinâmico lido no terminal, com checagem de localização) ou por tag NFC, com perfis de administrador, controlador de acesso, morador e visitante.

## Arquitetura

```
App Flutter ──REST/JWT──▶ API (Express + Prisma) ──▶ Postgres
                              │
                              └──MQTT──▶ Terminal (ESP32 ou simulador web)
                                         ◀──HTTP── QR, NFC, heartbeat
```

| Pasta | O que tem |
|---|---|
| `backend/` | API em Node 24 + TypeScript (Express 5, Prisma 7, zod, vitest) |
| `frontend/` | App Flutter (login, sessão e menus por perfil ligados à API) |
| `docker/` | Configuração do broker Mosquitto |
| `docs/` | Design das telas, fluxo da arquitetura e o estado da integração front × back |

## Como o acesso por QR funciona

1. O terminal busca um QR em `GET /terminal/qr-token`. É um JWT de uso único que vale 30 s e troca a cada 10 s.
2. O morador lê o QR com o app, que manda `POST /access/qr` com o token, a localização do celular e o JWT do usuário.
3. A API confere a assinatura e a validade do QR, se o usuário está ativo e tem autorização para aquele ponto, se está a até 100 m do terminal e se o QR ainda não foi usado.
4. A decisão (`ABRIR` ou `NEGAR`) vai para o terminal pelo tópico MQTT `passe/terminais/{terminalId}/decisoes` (QoS 1). Se o broker cair, o terminal consulta `GET /terminal/decisions?apos={seq}` como reserva.

Pelo NFC o terminal manda o UID da tag em `POST /terminal/nfc` e recebe a decisão pelo mesmo caminho. As rotas do terminal se autenticam pelos cabeçalhos `X-Terminal-Id` e `X-Terminal-Key`.

## Como rodar

Precisa de Docker (com WSL no Windows), Node 24 e Flutter.

```bash
# Tudo no Docker: Postgres, Mosquitto e API (migrations e seed rodam sozinhos)
docker compose -f docker-compose.dev.yml up --build database mqtt backend

# Ou só banco e broker no Docker, com a API direto no Node
docker compose -f docker-compose.dev.yml up -d database mqtt
cd backend && cp .env.example .env
npm ci && npx prisma migrate deploy && npm run db:seed && npm run dev
```

A API sobe em `http://localhost:3000` (`GET /health` responde quando ela está no ar).

```bash
# App
cd frontend
flutter run -d chrome   --dart-define=API_URL=http://localhost:3000
flutter run -d emulator --dart-define=API_URL=http://10.0.2.2:3000      # emulador Android
flutter run -d <celular> --dart-define=API_URL=http://<IP-do-PC>:3000  # celular na mesma rede
```

### Contas de demonstração

Todas com a senha `passe123`.

| E-mail | Perfil |
|---|---|
| admin@passe.com | Administrador |
| portaria@passe.com | Controlador de acesso |
| morador@passe.com | Morador |
| visitante@passe.com | Visitante |

Terminal de demonstração: `X-Terminal-Id=00000000-0000-4000-8000-000000000005` e `X-Terminal-Key=chave-demo-terminal-catraca-1`.

### Simulador do terminal

Com a API rodando, abra `http://localhost:3000/simulador/`. A página faz o papel da catraca: mostra o QR rotativo, recebe as decisões por MQTT (ou por consulta HTTP, se o broker não estiver no ar), lê tag NFC e tem um "celular de teste" para ler o QR de dentro do navegador, de perto da catraca, a 1 km ou sem GPS. Dá para testar acesso liberado, QR reutilizado, pessoa longe do terminal e NFC sem nenhum hardware.

## Testes

```bash
cd backend
npm run lint && npm run typecheck && npm test

cd frontend
flutter analyze && flutter test
flutter test test/integracao --dart-define=API_REAL=http://localhost:3000   # contra a API de verdade
```

## CI/CD

O GitHub Actions roda em todo PR: lint, tipos, testes e build do backend; teste de fumaça com Postgres; `flutter analyze` e `flutter test`; e o build da imagem Docker. Na `main`, a imagem também é publicada no GitHub Container Registry e o deploy no Render é disparado quando o secret `RENDER_DEPLOY_HOOK_URL` estiver configurado.

O fluxo de trabalho é por branch: cada um trabalha na sua (`davi-dev`, `dev-thiago`...) ou numa `feature/`/`fix/`, abre PR para a `main` e só mescla com o CI verde.

## Variáveis de ambiente

Estão todas em `backend/.env.example`. O `.env` de verdade não vai para o git.

| Variável | Para que serve |
|---|---|
| `DATABASE_URL` | Conexão com o Postgres |
| `JWT_SECRET`, `JWT_EXPIRES_IN` | Token de login do app |
| `QR_SECRET`, `QR_ROTATION_SECONDS`, `QR_TOKEN_TTL_SECONDS` | Assinatura e tempo de vida do QR do terminal |
| `MQTT_URL`, `MQTT_USERNAME`, `MQTT_PASSWORD` | Broker para onde a API publica as decisões (opcional) |
| `MQTT_WS_URL` | Endereço WebSocket do broker usado pelo simulador |
| `CORS_ORIGIN`, `APP_TIMEZONE`, `PORT`, `NODE_ENV` | Configurações gerais |

## Próximos passos

- Deploy no Render com Postgres na nuvem
- Firmware do ESP32 (display para o QR, relé da catraca, leitor NFC)
- Restante das telas do app (o andamento está em `docs/integracao-frontend-backend.md`)
- Autenticação, ACL e TLS no broker MQTT de produção
