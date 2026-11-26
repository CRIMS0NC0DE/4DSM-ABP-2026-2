# Manual de instalação

| Campo | Informação |
|---|---|
| Sistema | Passe — Controle de acesso por QR Code e NFC |
| Finalidade | Instalação e execução local do projeto |
| Sistema principal | Windows com PowerShell |
| Público | Integrantes da equipe, avaliadores e responsáveis pela implantação local |
| Revisão | 11/11/2026 |
| Base do manual | Configurações atuais do repositório |

## 1. Objetivo

Este manual apresenta os procedimentos para instalar e executar o sistema Passe em um computador Windows.

Há dois caminhos principais:

1. **Tudo no Docker**, recomendado para a primeira execução e demonstrações.
2. **Ambiente híbrido**, recomendado para desenvolvimento, com banco e MQTT no Docker, backend no Node.js e aplicativo no Flutter.

O projeto também fornece um console web e um simulador de terminal, que permitem testar o sistema sem instalar Flutter ou conectar um ESP32.

## 2. Componentes do sistema

| Componente | Tecnologia | Função |
|---|---|---|
| Banco de dados | PostgreSQL 16 | Armazena usuários, locais, autorizações e eventos |
| Broker | Mosquitto MQTT | Entrega decisões de acesso aos terminais |
| Backend | Node.js, Express e Prisma | Fornece API, autenticação e regras de acesso |
| Aplicativo | Flutter | Interface de administradores, portaria, moradores e visitantes |
| Terminal | ESP32 e PlatformIO | Exibe QR, lê NFC e aciona a catraca |
| Simulador | Interface web do backend | Simula o terminal sem hardware físico |

## 3. Escolher o tipo de instalação

| Necessidade | Instalação indicada |
|---|---|
| Abrir o projeto pela primeira vez | Tudo no Docker |
| Demonstrar o sistema completo no navegador | Tudo no Docker |
| Trabalhar somente no backend | Docker para banco/MQTT e Node.js local |
| Trabalhar no aplicativo | Docker para serviços, Node.js e Flutter locais |
| Testar sem Flutter e sem ESP32 | Backend, console web e simulador |
| Trabalhar no terminal físico | Serviços do projeto e PlatformIO |

## 4. Requisitos

### 4.1 Instalação mínima com Docker

- Windows com virtualização disponível;
- Git;
- Docker Desktop com WSL 2;
- navegador atualizado;
- conexão com a internet para baixar imagens e dependências;
- espaço livre para imagens, volumes e caches.

Não é necessário instalar PostgreSQL ou Mosquitto diretamente no Windows.

### 4.2 Ferramentas opcionais para desenvolvimento

| Ferramenta | Requisito do projeto | Quando instalar |
|---|---|---|
| Node.js | Versão 22 ou superior; Node 24 recomendado | Backend fora do Docker |
| npm | Versão incluída no Node.js | Backend fora do Docker |
| Flutter | Versão compatível com Flutter 3.47 ou superior | Aplicativo |
| Dart | 3.13.5 ou superior e menor que 4.0 | Fornecido pelo Flutter |
| Chrome | Versão recente | Flutter Web |
| Android Studio e SDK | Configuração aceita pelo `flutter doctor` | Emulador ou build Android |
| Java | Java 17 compatível | Build Android |
| PlatformIO | Extensão do VS Code ou CLI | Firmware ESP32 |

Builds para iOS exigem macOS e Xcode. O Windows não oferece o ambiente nativo completo para desenvolvimento e assinatura iOS.

## 5. Instalar e verificar as ferramentas

Depois de instalar as ferramentas necessárias, abra um novo PowerShell e execute apenas os comandos correspondentes ao seu ambiente:

```powershell
git --version
docker --version
docker compose version
node --version
npm --version
flutter --version
dart --version
flutter doctor -v
pio --version
```

Verifique principalmente:

- o Docker Compose responde com o comando `docker compose`;
- `docker version` mostra cliente e servidor;
- o Node.js atende ao mínimo exigido;
- o Flutter e o Dart são compatíveis;
- o `flutter doctor` reconhece o destino que será utilizado;
- o PlatformIO reconhece `pio`, caso o ESP32 seja necessário.

## 6. Preparar o Docker Desktop no Windows

1. Confirme que a virtualização está habilitada no computador.
2. Instale e configure o WSL 2.
3. Instale o Docker Desktop.
4. Configure o Docker para usar o mecanismo WSL 2.
5. Inicie o Docker Desktop.
6. Aguarde até o mecanismo ficar disponível.

Validação:

```powershell
wsl --status
docker version
docker info
docker compose version
```

Se `docker version` mostrar somente o cliente, o Docker Desktop ainda não iniciou corretamente.

## 7. Clonar o repositório

No PowerShell, escolha uma pasta de trabalho e execute:

```powershell
git clone <url-do-repositorio>
Set-Location .\4DSM-ABP-2026-2
```

Confirme que o terminal está na raiz do clone:

```powershell
git status
Test-Path -LiteralPath .git
Test-Path -LiteralPath docker-compose.dev.yml
```

Os dois testes devem retornar `True`.

Se aparecer `fatal: not a git repository`, o terminal está na pasta externa ao clone. Entre na subpasta `4DSM-ABP-2026-2` e tente novamente.

## 8. Estrutura esperada

Na raiz do projeto devem estar presentes:

```text
4DSM-ABP-2026-2/
├── .github/
├── arduino/
├── backend/
├── docker/
├── docs/
├── frontend/
├── scripts/
├── docker-compose.dev.yml
└── README.md
```

Os comandos Docker e Git deste manual partem dessa raiz, salvo quando for indicado entrar em `backend`, `frontend` ou `arduino`.

## 9. Instalação recomendada — tudo no Docker

Essa opção inicia banco, broker MQTT, backend e Flutter Web.

### 9.1 Iniciar o ambiente

Na raiz do repositório:

```powershell
docker compose -f docker-compose.dev.yml up --build
```

Na primeira execução, o Docker precisa baixar imagens e instalar dependências. O processo pode demorar conforme a conexão e o desempenho do computador.

Para executar em segundo plano:

```powershell
docker compose -f docker-compose.dev.yml up -d --build
```

### 9.2 O que acontece automaticamente

O Compose:

1. inicia o PostgreSQL;
2. inicia o Mosquitto;
3. gera o Prisma Client;
4. aplica as migrations do banco;
5. carrega os dados de demonstração;
6. inicia a API;
7. inicia o Flutter Web.

Não execute migrations ou seed manualmente quando estiver usando o backend do Compose, pois essas etapas já fazem parte da inicialização.

### 9.3 Endereços locais

| Recurso | Endereço |
|---|---|
| Aplicativo Flutter Web | `http://localhost:8080` |
| API | `http://localhost:3000` |
| Verificação da API | `http://localhost:3000/health` |
| Console web | `http://localhost:3000/console/` |
| Simulador do terminal | `http://localhost:3000/simulador/` |

### 9.4 Verificar a instalação

Em outro PowerShell:

```powershell
docker compose -f docker-compose.dev.yml ps
Invoke-RestMethod -Uri http://localhost:3000/health
```

A API deve responder com o estado `ok`. No `docker compose ps`, os serviços devem aparecer em execução e o banco deve ficar saudável.

Abra o aplicativo, o console ou o simulador pelo navegador. Para entrar com contas locais de demonstração, consulte os dados de teste mantidos pela equipe no `README.md`. Não reutilize credenciais de demonstração em produção.

### 9.5 Consultar os logs

Todos os serviços:

```powershell
docker compose -f docker-compose.dev.yml logs -f
```

Somente o backend:

```powershell
docker compose -f docker-compose.dev.yml logs -f backend
```

Use `Ctrl+C` para sair da visualização dos logs. Se os serviços estiverem em segundo plano, eles continuarão funcionando.

## 10. Instalação híbrida para desenvolvimento

Nesse modo:

- PostgreSQL e Mosquitto rodam no Docker;
- backend roda diretamente no Node.js;
- aplicativo roda diretamente no Flutter.

Não inicie o serviço `backend` do Compose ao mesmo tempo que `npm run dev`, porque os dois tentarão usar a porta 3000.

### 10.1 Iniciar banco e MQTT

Na raiz do projeto:

```powershell
docker compose -f docker-compose.dev.yml up -d database mqtt
```

Confira os serviços:

```powershell
docker compose -f docker-compose.dev.yml ps
docker compose -f docker-compose.dev.yml logs database
docker compose -f docker-compose.dev.yml logs mqtt
```

### 10.2 Preparar o backend

Entre na pasta do backend:

```powershell
Set-Location .\backend
Copy-Item -LiteralPath .env.example -Destination .env
npm ci
npx prisma generate
npx prisma migrate deploy
npm run db:seed
npm run dev
```

O último comando mantém a API em execução e reinicia o servidor quando o código muda. Deixe esse PowerShell aberto.

Use `npm ci`, e não `npm install`, para respeitar as versões registradas no `package-lock.json`.

### 10.3 Arquivo de ambiente

O arquivo local é `backend/.env`. Ele contém configurações de:

- porta da API;
- banco PostgreSQL;
- autenticação JWT;
- QR Code;
- fuso horário;
- CORS;
- conexão MQTT.

Cuidados:

- não envie `.env` ao Git;
- não publique seus valores em mensagens ou capturas de tela;
- use segredos diferentes em produção;
- confirme a `DATABASE_URL` antes de migrations e seed;
- use `localhost` na conexão do backend executado no Windows;
- use o nome `database` somente para serviços executados dentro do Compose.

### 10.4 Validar o backend local

Abra outro PowerShell:

```powershell
Invoke-RestMethod -Uri http://localhost:3000/health
```

Se a API não responder, consulte o terminal em que `npm run dev` está em execução.

## 11. Instalar e executar o aplicativo Flutter

### 11.1 Preparar o Flutter

Instale o SDK Flutter, adicione `flutter\bin` ao `PATH` e execute:

```powershell
flutter --version
dart --version
flutter doctor -v
```

Para Android, aceite as licenças quando solicitado:

```powershell
flutter doctor --android-licenses
```

No Windows, avisos relacionados ao Xcode são esperados e não impedem a execução no Chrome ou Android.

### 11.2 Instalar as dependências do aplicativo

Em um novo PowerShell, a partir da raiz:

```powershell
Set-Location .\frontend
flutter pub get
flutter analyze
flutter test
flutter devices
```

### 11.3 Executar no Chrome

Com a API funcionando na porta 3000:

```powershell
flutter run -d chrome --dart-define=API_URL=http://localhost:3000
```

O navegador pode solicitar permissão de câmera e localização.

### 11.4 Executar no emulador Android

1. Instale Android Studio e os componentes solicitados pelo `flutter doctor`.
2. Crie ou inicie um emulador.
3. Consulte o identificador com `flutter devices`.
4. Execute:

```powershell
flutter run -d <id-do-emulador> --dart-define=API_URL=http://10.0.2.2:3000
```

No emulador Android, `localhost` aponta para o próprio emulador. O endereço `10.0.2.2` representa o computador host.

### 11.5 Executar em celular Android

1. Ative o modo desenvolvedor e a depuração USB.
2. Conecte o celular com um cabo que transmita dados.
3. Autorize o computador no celular.
4. Mantenha celular e computador na mesma rede.
5. Descubra o IPv4 do computador:

```powershell
Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object AddressState -eq Preferred |
  Select-Object InterfaceAlias,IPAddress
```

6. No navegador do celular, teste `http://<ip-do-computador>:3000/health`.
7. Consulte o ID com `flutter devices`.
8. Execute:

```powershell
flutter run -d <id-do-celular> --dart-define=API_URL=http://<ip-do-computador>:3000
```

Se o celular não alcançar a API, confira a rede e a permissão do firewall para a porta 3000 em rede privada.

## 12. Endereço da API por destino

| Destino | `API_URL` |
|---|---|
| Chrome no computador | `http://localhost:3000` |
| Aplicativo Windows no computador | `http://localhost:3000` |
| Emulador Android padrão | `http://10.0.2.2:3000` |
| Celular físico | `http://<ip-do-computador>:3000` |
| Produção | Endereço HTTPS do ambiente implantado |

Usar o endereço errado é uma das causas mais comuns de falha de conexão do aplicativo.

## 13. Testar sem instalar Flutter

Com `database`, `mqtt` e `backend` em execução, abra:

- console web: `http://localhost:3000/console/`;
- simulador de terminal: `http://localhost:3000/simulador/`.

O console permite testar telas e operações da API pelo navegador. O simulador permite testar QR Code, NFC simulado, decisões de acesso, heartbeat e comunicação MQTT sem um ESP32 físico.

Para iniciar somente os serviços necessários:

```powershell
docker compose -f docker-compose.dev.yml up --build database mqtt backend
```

## 14. Instalar o firmware ESP32 — opcional

Essa etapa é necessária apenas para utilizar o terminal físico.

### 14.1 Preparar o PlatformIO

1. Instale o VS Code.
2. Instale a extensão PlatformIO IDE.
3. Abra a pasta `arduino` como projeto PlatformIO.
4. Conecte o ESP32 por USB.
5. Aguarde o download da plataforma e das bibliotecas.
6. Confirme a porta serial.

Pelo terminal:

```powershell
pio --version
pio device list
```

### 14.2 Executar o teste de bancada

O ambiente de teste não exige Wi-Fi nem credenciais:

```powershell
Set-Location .\arduino
pio run -e teste -t upload
pio device monitor
```

Use esse teste para validar LEDs, buzzer, relé, display e leitor NFC antes da integração.

### 14.3 Criar o arquivo local de credenciais

```powershell
Copy-Item -LiteralPath include\credenciais.exemplo.h -Destination include\credenciais.h
```

Edite `include/credenciais.h` com os dados do ambiente:

- Wi-Fi;
- endereço da API;
- host e porta MQTT;
- ID e chave do terminal;
- certificados, quando houver TLS.

Esse arquivo é privado e ignorado pelo Git. Nunca o inclua em commits, documentação ou capturas de tela.

### 14.4 Compilar e gravar

Para o display padrão ST7789:

```powershell
pio run -e tft
pio run -e tft -t upload
pio device monitor
```

Escolha outro ambiente do `platformio.ini` se o hardware utilizar um display diferente.

No ESP32, não use `localhost` como endereço da API. Informe o IP do computador ou o endereço do servidor acessível pela rede.

## 15. Testes do projeto

### 15.1 Backend

Com as dependências instaladas:

```powershell
Set-Location .\backend
npm run lint
npm run typecheck
npm test
npm run build
```

### 15.2 Aplicativo

```powershell
Set-Location .\frontend
flutter analyze
flutter test
```

### 15.3 Integração do aplicativo com a API real

Com backend e banco de desenvolvimento em execução:

```powershell
flutter test test\integracao --dart-define=API_REAL=http://localhost:3000
```

Use a integração e o seed somente no banco local de desenvolvimento ou teste.

## 16. Parar e reiniciar o ambiente

### 16.1 Interromper processos locais

Nos terminais em que Node.js ou Flutter estão executando, pressione:

```text
Ctrl+C
```

### 16.2 Parar os contêineres sem apagar dados

Na raiz do projeto:

```powershell
docker compose -f docker-compose.dev.yml stop
```

Para iniciar novamente:

```powershell
docker compose -f docker-compose.dev.yml start
```

### 16.3 Remover os contêineres preservando os volumes

```powershell
docker compose -f docker-compose.dev.yml down
```

Não acrescente `-v` sem intenção explícita. A opção `down -v` remove volumes e pode apagar o banco PostgreSQL local e caches do projeto.

## 17. Atualizar o projeto

Antes de atualizar, confira se existem alterações locais:

```powershell
git status
git branch --show-current
```

Se não houver trabalho pendente que possa entrar em conflito:

```powershell
git pull
```

Depois da atualização:

### Backend alterado

```powershell
Set-Location .\backend
npm ci
npx prisma generate
npx prisma migrate deploy
```

### Flutter alterado

```powershell
Set-Location .\frontend
flutter pub get
```

### Docker alterado

Volte à raiz e reconstrua:

```powershell
docker compose -f docker-compose.dev.yml up -d --build
```

Não descarte alterações locais automaticamente. Em caso de dúvida, pare e revise `git status` e `git diff` com a equipe.

## 18. Portas utilizadas

| Porta | Serviço |
|---:|---|
| 3000 | API |
| 5432 | PostgreSQL |
| 1883 | MQTT sem TLS |
| 8883 | MQTT com TLS |
| 9001 | MQTT por WebSocket |
| 8080 | Flutter Web no Docker |

Para verificar portas ocupadas:

```powershell
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
  Where-Object LocalPort -In 3000,5432,1883,8883,9001,8080 |
  Select-Object LocalAddress,LocalPort,OwningProcess
```

Evite executar ao mesmo tempo dois serviços que utilizem a mesma porta.

## 19. Solução de problemas

### 19.1 `fatal: not a git repository`

O PowerShell não está dentro do clone. Entre na pasta que contém `.git`:

```powershell
Set-Location .\4DSM-ABP-2026-2
git status
```

### 19.2 Docker não responde

- abra o Docker Desktop;
- aguarde o mecanismo iniciar;
- confira `wsl --status`;
- execute `docker info`;
- reinicie o Docker Desktop se necessário.

### 19.3 Porta em uso

- identifique o processo com `Get-NetTCPConnection`;
- verifique se outro backend, banco, broker ou Flutter Web já está aberto;
- encerre somente o processo conhecido;
- não execute backend Docker e backend Node simultaneamente na porta 3000.

### 19.4 Banco não conecta ou Prisma mostra `P1001`

- confira `docker compose -f docker-compose.dev.yml ps`;
- aguarde o PostgreSQL ficar saudável;
- confira a `DATABASE_URL`;
- use `localhost:5432` para backend no Windows;
- use `database:5432` apenas dentro do Compose.

### 19.5 API não responde

- consulte os logs do backend;
- teste `http://localhost:3000/health`;
- confira se a porta 3000 está livre;
- confirme se migrations foram aplicadas;
- confirme se o banco está disponível.

### 19.6 Flutter não encontra dependências

```powershell
Set-Location .\frontend
flutter pub get
flutter doctor -v
```

Confirme se Flutter e Dart atendem às versões do projeto.

### 19.7 Aplicativo não alcança a API

- Chrome: use `localhost`;
- emulador Android: use `10.0.2.2`;
- celular: use o IP do computador;
- teste `/health` no mesmo dispositivo;
- confira Wi-Fi, firewall e CORS.

### 19.8 Câmera ou localização não funcionam

- conceda as permissões ao aplicativo ou navegador;
- ative a localização do dispositivo;
- confira se o emulador possui câmera e posição configuradas;
- teste em um aparelho físico quando possível.

### 19.9 `pio` não é reconhecido

- abra o terminal integrado do PlatformIO;
- confira a instalação da extensão;
- adicione o PlatformIO Core ao `PATH`, se estiver usando o CLI;
- reabra o terminal.

### 19.10 ESP32 não aparece ou o upload falha

- use um cabo USB com transmissão de dados;
- teste outra porta USB;
- instale o driver da placa;
- feche outros monitores seriais;
- confira a porta no Gerenciador de Dispositivos;
- utilize o botão BOOT da placa quando necessário.

## 20. Segurança da instalação

- Não envie `.env` ao Git.
- Não publique `arduino/include/credenciais.h`.
- Não inclua chaves, senhas ou tokens em documentação e capturas de tela.
- Use dados de demonstração somente no ambiente local.
- Não execute seed no banco de produção.
- Use HTTPS e MQTT com TLS em produção.
- Troque segredos e credenciais antes de publicar o sistema.
- Restrinja CORS e acesso ao banco no ambiente implantado.
- Confirme a conexão de destino antes de executar migrations.
- Não use `docker compose down -v` sem confirmar que os dados locais podem ser apagados.

## 21. Checklist da instalação

### Repositório e Docker

- [ ] `git status` funciona na raiz correta.
- [ ] Docker Desktop está em execução.
- [ ] `docker compose version` responde.
- [ ] PostgreSQL aparece saudável.
- [ ] Mosquitto inicia sem erros.

### Backend

- [ ] Migrations foram aplicadas.
- [ ] Seed foi executado somente no banco local.
- [ ] API responde em `/health`.
- [ ] Console web abre no navegador.
- [ ] Simulador abre no navegador.

### Aplicativo

- [ ] `flutter doctor` aceita o destino escolhido.
- [ ] `flutter pub get` termina sem erros.
- [ ] Aplicativo abre.
- [ ] Aplicativo alcança a API pelo endereço correto.
- [ ] Câmera e localização foram autorizadas.

### Firmware, quando utilizado

- [ ] ESP32 aparece na porta serial.
- [ ] Teste de bancada funciona.
- [ ] `credenciais.h` foi criado somente localmente.
- [ ] Firmware compila e grava.
- [ ] Terminal alcança a API e o broker.

## 22. Resumo da primeira execução

Para a primeira demonstração, o procedimento mínimo é:

```powershell
git clone <url-do-repositorio>
Set-Location .\4DSM-ABP-2026-2
docker compose -f docker-compose.dev.yml up --build
```

Depois, confirme a API:

```powershell
Invoke-RestMethod -Uri http://localhost:3000/health
```

E abra no navegador:

```text
http://localhost:8080
http://localhost:3000/console/
http://localhost:3000/simulador/
```

## 23. Documentos relacionados

- `README.md`: visão geral e execução rápida;
- `docs/documentacao-tecnica/instalacao-ambiente.md`: detalhes técnicos do ambiente;
- `docs/documentacao-tecnica/backend.md`: arquitetura e validações do backend;
- `docs/documentacao-tecnica/aplicativo.md`: aplicativo Flutter;
- `docs/documentacao-tecnica/docker-cicd.md`: contêineres e automação;
- `docs/documentacao-tecnica/firmware-esp32.md`: firmware e PlatformIO;
- `docs/rede-do-prototipo.md`: rede e firewall;
- `docs/deploy-nuvem.md`: preparação do ambiente de produção.

