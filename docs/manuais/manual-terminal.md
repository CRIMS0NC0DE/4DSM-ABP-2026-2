# Manual do terminal de acesso

| Campo | Informação |
|---|---|
| Sistema | Passe — Controle de acesso por QR Code e NFC |
| Componente | Terminal físico ESP32 e simulador web |
| Público | Administradores, instaladores e responsáveis pela manutenção |
| Revisão | 11/11/2026 |
| Base do manual | Firmware, backend e hardware atuais do projeto |

## 1. Objetivo

Este manual orienta a montagem, o provisionamento, a gravação, a operação e a manutenção do terminal de acesso do Passe.

O terminal:

- exibe um QR Code rotativo;
- lê tags NFC;
- recebe a decisão de liberar ou negar;
- aciona o relé da catraca;
- sinaliza o resultado com display, LEDs e buzzer;
- envia sinais periódicos para aparecer como online no sistema.

O terminal não decide quem pode entrar. Toda decisão é realizada pelo backend a partir do cadastro, da autorização, do local, do horário e dos usos disponíveis.

## 2. Visão geral do funcionamento

```text
Usuário ──QR/NFC──> Terminal ESP32 ──HTTP──> API
                              ▲               │
                              └──MQTT/HTTP────┘
                                  decisão
```

### Acesso por QR Code

1. O terminal solicita um token à API.
2. O ESP32 transforma o texto em QR Code e o desenha no display.
3. O usuário lê o QR pelo aplicativo Passe.
4. O aplicativo envia o token e a localização à API.
5. A API valida o acesso.
6. A decisão chega ao terminal por MQTT ou pela consulta HTTP de reserva.
7. O terminal abre o relé ou sinaliza a recusa.

### Acesso por NFC

1. O usuário aproxima a tag do leitor MFRC522.
2. O terminal lê e envia o UID à API.
3. A API identifica a tag e verifica a autorização.
4. A decisão retorna na própria resposta HTTP.
5. O terminal abre o relé ou sinaliza a recusa.

## 3. Hardware utilizado

| Item | Modelo ou característica |
|---|---|
| Microcontrolador | ESP32 DevKit, ESP32-WROOM-32 |
| Display recomendado | TFT ST7789 240 × 240 com pino CS |
| Display alternativo | ILI9341 240 × 320 |
| Display de teste | OLED SSD1306 128 × 64 |
| Leitor NFC | MFRC522/RC522 de 13,56 MHz |
| Acionamento | Módulo relé de 1 canal |
| Sinalização | LED verde, LED vermelho e buzzer ativo |
| Montagem | Protoboard e jumpers |
| Alimentação | Fonte USB 5 V adequada ao ESP32 |

O OLED é adequado somente a testes, pois o QR fica pequeno para uso normal. O ST7789 precisa possuir pino CS para compartilhar o barramento SPI com o leitor NFC.

## 4. Cuidados elétricos

- Desligue a alimentação antes de alterar a fiação.
- Alimente o MFRC522 em **3,3 V**; não conecte esse leitor em 5 V.
- Alimente o display conforme a especificação do módulo utilizado.
- O módulo relé do protótipo utiliza 5 V pelo pino VIN.
- Mantenha o GND comum entre ESP32, display, leitor e relé.
- Use resistores de 220 Ω nos LEDs externos.
- Não ligue uma trava ou solenoide diretamente ao GPIO do ESP32.
- Uma trava de 12 V precisa de fonte própria, contato do relé e proteção adequada.
- Não trabalhe com tensão de rede elétrica na protoboard.
- Confirme se o relé é ativo em nível baixo ou alto antes da operação.

No projeto atual, o relé é configurado como ativo em nível baixo: `RELE_LIGADO` é `LOW` e `RELE_DESLIGADO` é `HIGH`.

## 5. Pinagem do protótipo

O display TFT e o leitor NFC compartilham o barramento SPI, mas usam seletores CS diferentes.

| Sinal | GPIO do ESP32 | Ligação |
|---|---:|---|
| SPI SCK | 18 | SCK do TFT e do RC522 |
| SPI MOSI | 23 | MOSI do TFT e do RC522 |
| SPI MISO | 19 | MISO do RC522 |
| TFT CS | 5 | CS do display |
| TFT DC | 16 | DC/RS do display |
| TFT RST | 17 | Reset do display |
| NFC SS | 32 | SDA/SS do RC522 |
| NFC RST | 13 | Reset do RC522 |
| Relé | 26 | Entrada IN do módulo relé |
| LED verde | 25 | LED com resistor para GND |
| LED vermelho | 27 | LED com resistor para GND |
| Buzzer | 4 | Entrada positiva do buzzer ativo |
| OLED SDA | 21 | Somente no ambiente OLED |
| OLED SCL | 22 | Somente no ambiente OLED |

O detalhamento completo da montagem está em `docs/hardware.md` e `docs/montagem-terminal.html`.

## 6. Ferramentas necessárias

- VS Code;
- extensão PlatformIO IDE ou PlatformIO Core;
- driver USB correspondente à placa;
- cabo USB com transmissão de dados;
- backend, banco e broker MQTT em execução;
- acesso de administrador para cadastrar ou provisionar o terminal.

Verifique o PlatformIO:

```powershell
pio --version
pio device list
```

## 7. Ambientes de compilação

| Ambiente | Display | Uso |
|---|---|---|
| `tft` | ST7789 | Ambiente padrão e recomendado |
| `ili9341` | ILI9341 | Alternativa com display 240 × 320 |
| `oled` | SSD1306 | Teste; QR pequeno |
| `teste` | ST7789 por padrão | Teste de bancada sem rede ou credenciais |

O projeto usa ESP32 DevKit com framework Arduino e a plataforma `espressif32@6.9.0`.

## 8. Teste de bancada

Execute o teste antes de configurar Wi-Fi, API e terminal. Ele valida a montagem sem usar credenciais.

### 8.1 Gravar o teste

Na raiz do repositório:

```powershell
Set-Location .\arduino
pio run -e teste -t upload
pio device monitor
```

O monitor serial utiliza 115200 baud.

### 8.2 Opções do teste

Digite no monitor serial:

| Opção | Teste | Resultado esperado |
|---:|---|---|
| `1` | LEDs | Verde e vermelho piscam três vezes |
| `2` | Buzzer | Três bipes curtos |
| `3` | Relé | Liga e desliga três vezes com clique |
| `4` | Display | Tela verde, tela vermelha e QR de teste |
| `5` | NFC | Detecta o MFRC522 e aguarda uma tag |
| `0` | Todos | Executa os testes em sequência |

Uma tag pode ser aproximada a qualquer momento. O UID aparecerá no monitor serial e poderá ser usado no cadastro da tag no sistema.

Corrija qualquer falha de hardware antes de gravar o firmware integrado.

## 9. Preparar o ambiente do sistema

O terminal precisa alcançar:

- API HTTP ou HTTPS;
- broker MQTT;
- rede Wi-Fi configurada.

No ambiente local, inicie os serviços na raiz do projeto:

```powershell
docker compose -f docker-compose.dev.yml up -d database mqtt backend
```

Valide a API:

```powershell
Invoke-RestMethod -Uri http://localhost:3000/health
```

O ESP32 não pode usar `localhost` para alcançar o computador. Use o IPv4 do computador na rede local.

Para descobrir o endereço:

```powershell
Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object AddressState -eq Preferred |
  Select-Object InterfaceAlias,IPAddress
```

Teste o endereço da API a partir de outro dispositivo na mesma rede antes de gravar o ESP32.

## 10. Criar o arquivo de configuração privada

Na pasta `arduino`:

```powershell
Copy-Item -LiteralPath include\credenciais.exemplo.h -Destination include\credenciais.h
```

Preencha `include/credenciais.h` com:

- nome e senha da rede Wi-Fi;
- endereço da API, sem barra no final;
- host e porta do MQTT;
- ID do terminal;
- chave do terminal;
- certificados de autoridade, quando houver TLS.

O arquivo `credenciais.h` é ignorado pelo Git. Nunca publique seu conteúdo, envie-o por mensagens ou inclua-o em capturas de tela.

## 11. Cadastrar e provisionar o terminal

Cada catraca pode possuir somente um terminal. A chave é exibida apenas no cadastro ou na troca de chave.

### 11.1 Cadastro pelo aplicativo

1. Entre com uma conta de administrador.
2. Confirme que o edifício, a portaria, a porta e a catraca já existem.
3. Abra **Terminais**.
4. Toque em **Novo terminal**.
5. Informe o nome.
6. Selecione uma catraca sem terminal.
7. Toque em **Cadastrar**.
8. Copie o ID e a chave exibidos.
9. Guarde a chave em local seguro.
10. Configure a chave no firmware e no broker MQTT.

O cadastro pelo aplicativo não altera automaticamente o arquivo do firmware nem a senha do broker.

### 11.2 Provisionamento local pelo script

No ambiente de desenvolvimento, o script pode cadastrar o terminal e gravar a credencial nos arquivos locais utilizados pelo firmware e pelo Mosquitto.

Entre em `backend` e informe uma conta administrativa no PowerShell atual:

```powershell
Set-Location .\backend
$env:ADMIN_LOGIN = "<login-do-administrador>"
$env:ADMIN_SENHA = "<senha-do-administrador>"
node scripts\provisionar-terminal.mjs
```

Sem argumentos, o script lista catracas, terminais, estado online e último sinal.

Para cadastrar:

```powershell
node scripts\provisionar-terminal.mjs --catraca <id-da-catraca> --nome "Terminal da entrada"
```

O script:

- cadastra o terminal na API;
- grava o ID e a chave em `arduino/include/credenciais.h`;
- grava a credencial correspondente em `docker/mosquitto/passwd`.

Depois, volte à raiz e reinicie o broker:

```powershell
Set-Location ..
docker compose -f docker-compose.dev.yml restart mqtt
```

Remova as variáveis administrativas do PowerShell quando terminar:

```powershell
Remove-Item Env:ADMIN_LOGIN
Remove-Item Env:ADMIN_SENHA
```

Não registre login, senha, ID ou chave do terminal em commits e documentos.

## 12. Configurar Wi-Fi, API e MQTT

Revise em `credenciais.h`:

### Wi-Fi

- SSID correto;
- senha correta;
- rede de 2,4 GHz compatível com o ESP32;
- sinal suficiente no local da catraca.

### API

- ambiente local: IP do computador e porta 3000;
- ambiente implantado: endereço HTTPS;
- sem barra no final;
- firewall liberado para a rede utilizada.

### MQTT

- host acessível pelo ESP32;
- porta 1883 em desenvolvimento sem TLS;
- porta 8883 e CA configurada quando houver TLS;
- usuário igual ao ID do terminal;
- senha igual à chave do terminal.

O terminal só pode ler o próprio tópico de decisões. A API é a única autorizada a publicar comandos de abertura.

## 13. Compilar e gravar o firmware

### ST7789 — padrão

```powershell
Set-Location .\arduino
pio run -e tft
pio run -e tft -t upload
pio device monitor
```

### ILI9341

```powershell
pio run -e ili9341
pio run -e ili9341 -t upload
pio device monitor
```

### OLED de teste

```powershell
pio run -e oled
pio run -e oled -t upload
pio device monitor
```

Se o upload falhar, confira o cabo, o driver, a porta serial e se outro monitor está usando a mesma porta.

## 14. Inicialização do terminal

Ao ligar, o firmware executa esta sequência:

1. configura o relé como desligado;
2. inicializa LEDs e buzzer;
3. inicializa SPI, display e leitor NFC;
4. carrega as configurações de API e MQTT;
5. conecta ao Wi-Fi;
6. envia o primeiro heartbeat;
7. consulta decisões pendentes sem executar decisões antigas;
8. tenta conectar ao MQTT;
9. solicita e exibe o primeiro QR Code.

Durante a conexão, o display mostra **Conectando** e o nome da rede. Se o Wi-Fi cair, mostra **Sem Wi-Fi — Reconectando**.

## 15. Estados e sinalizações

| Situação | Display | LED | Buzzer | Relé |
|---|---|---|---|---|
| Pronto | QR Code atual | Apagados | Sem som | Desligado |
| Acesso liberado | “Pode passar” | Verde | Um bipe | Ligado por 3 segundos |
| Acesso negado | “Acesso negado” e motivo | Vermelho | Dois bipes | Desligado |
| Sem Wi-Fi | Aviso de reconexão | Sem decisão | Sem decisão | Desligado |
| API indisponível ao buscar QR | “Sem servidor” | Apagados | Sem som | Desligado |
| Chave recusada | “Chave do terminal recusada” | Sem decisão | Sem decisão | Desligado |

A tela de decisão permanece visível por aproximadamente 4 segundos. Depois, os LEDs são apagados e um novo QR é solicitado.

Se a API falhar durante uma leitura NFC, o terminal trata a tentativa como negada: mostra **Sem servidor**, acende o LED vermelho, emite dois bipes e mantém o relé desligado.

## 16. QR Code

- O backend gera o texto assinado.
- O ESP32 desenha o QR localmente; nenhuma imagem é baixada.
- O QR é renovado normalmente a cada 10 segundos.
- O token possui validade curta e é aceito uma única vez.
- Depois de uma decisão, o terminal solicita um novo QR imediatamente.

Se o QR estiver difícil de ler:

- limpe a superfície do display;
- evite reflexos e luz direta;
- confira o contraste e a orientação;
- use um TFT de 240 pixels;
- confirme largura e altura configuradas em `config.h`;
- evite o OLED pequeno para operação normal.

## 17. NFC

- O MFRC522 lê o UID da tag.
- O UID é normalizado antes da consulta.
- A mesma tag é ignorada por 3 segundos para evitar leituras duplicadas.
- A decisão NFC retorna diretamente pela API.
- MQTT não é necessário para receber a decisão NFC.

Quando uma tag não for reconhecida, use o teste de bancada ou o monitor serial para obter o UID e vincule-o à pessoa correta pela tela **Tags NFC**.

Se o leitor não responder, confira principalmente alimentação em 3,3 V, GND, SCK, MOSI, MISO, SS e RST.

## 18. Comunicação MQTT e reserva HTTP

O terminal assina o tópico:

```text
passe/terminais/<id-do-terminal>/decisoes
```

As decisões são entregues com QoS 1.

Se o MQTT ficar indisponível:

- o terminal tenta reconectar periodicamente;
- registra a falha no monitor serial;
- consulta a fila de decisões por HTTP a cada 2 segundos;
- continua recebendo decisões de QR enquanto a API estiver disponível.

O fallback HTTP não elimina a necessidade de corrigir o broker, mas mantém o protótipo operacional durante uma falha de MQTT.

## 19. Heartbeat e estado online

O terminal envia heartbeat a cada 30 segundos.

No aplicativo:

1. abra **Terminais**;
2. localize o equipamento;
3. confira **No ar** ou **Fora do ar**;
4. consulte a data e a hora do último sinal.

O backend considera o terminal fora do ar quando não recebe sinal por aproximadamente 90 segundos.

O controlador de acesso pode consultar o estado. Somente o administrador pode cadastrar terminais e trocar chaves.

## 20. Operação diária

### Antes de iniciar o atendimento

- confira a alimentação do terminal;
- confirme que o QR está visível;
- teste a leitura com uma autorização de desenvolvimento válida;
- aproxime uma tag de teste autorizada;
- confira se o relé volta a desligar;
- verifique no aplicativo se o terminal aparece **No ar**.

### Durante a operação

- mantenha o display visível e limpo;
- não exponha o equipamento a umidade;
- observe avisos de Wi-Fi ou servidor;
- não force o relé manualmente;
- não altere a fiação com o equipamento ligado;
- registre o horário de falhas recorrentes para consultar os logs.

### Ao encerrar ou fazer manutenção

- desligue a alimentação antes de abrir a montagem;
- preserve o arquivo privado de credenciais;
- confirme a conexão de todos os terminais após mudanças no broker;
- teste QR, NFC, relé e heartbeat antes de devolver o equipamento à operação.

## 21. Trocar a chave do terminal

Troque a chave quando:

- houver suspeita de exposição;
- o terminal for substituído;
- as credenciais forem compartilhadas indevidamente;
- a política de segurança exigir rotação.

Pelo script local:

```powershell
Set-Location .\backend
$env:ADMIN_LOGIN = "<login-do-administrador>"
$env:ADMIN_SENHA = "<senha-do-administrador>"
node scripts\provisionar-terminal.mjs --trocar-chave <id-do-terminal>
```

Depois:

1. reinicie o broker MQTT;
2. grave novamente o firmware;
3. reinicie o terminal;
4. aguarde o primeiro heartbeat;
5. confirme que o terminal aparece **No ar**;
6. teste QR e NFC.

A chave anterior para de funcionar imediatamente. Não troque a chave durante o atendimento sem preparar a atualização do firmware e do broker.

## 22. Monitor serial

Abra o monitor com:

```powershell
Set-Location .\arduino
pio device monitor
```

O firmware registra informações como:

- conexão e IP do Wi-Fi;
- conexão ou falha do MQTT;
- tópico assinado;
- falhas HTTP;
- JSON inválido;
- UID lido;
- decisão de abrir ou negar;
- QR grande demais para o display.

Não publique logs que possam conter ID, UID, endereço interno ou outras informações sensíveis.

## 23. Simulador web do terminal

O simulador executa no navegador os mesmos fluxos principais do firmware.

### 23.1 Iniciar

Na raiz:

```powershell
docker compose -f docker-compose.dev.yml up -d database mqtt backend
```

Abra:

```text
http://localhost:3000/simulador/
```

### 23.2 Utilizar

1. Informe o ID e a chave de um terminal de desenvolvimento.
2. Toque em **Ligar terminal**.
3. Confira o estado da API e do MQTT.
4. Observe o QR rotativo.
5. Para NFC, informe um UID e toque em **Aproximar tag**.
6. No **Celular de teste**, entre com uma conta local.
7. Selecione a localização na catraca, distante ou sem GPS.
8. Toque em **Ler o QR da tela**.
9. Use **Reenviar o último QR lido** para testar reutilização.
10. Consulte o registro apresentado na página.

Use somente credenciais de desenvolvimento no simulador local.

## 24. Solução de problemas

### Terminal não liga

- confira cabo e fonte USB;
- teste outra porta USB;
- verifique se o ESP32 aparece no computador;
- procure curto-circuito ou aquecimento;
- desconecte os periféricos e teste a placa isoladamente.

### Display branco ou preto

- confira alimentação, GND, SCK, MOSI, CS, DC e RST;
- confirme o ambiente de compilação correto;
- verifique largura e altura configuradas;
- execute o teste de display da bancada.

### Leitor NFC não é encontrado

- confirme alimentação em 3,3 V;
- confira SS no GPIO 32 e RST no GPIO 13;
- confira SCK 18, MOSI 23 e MISO 19;
- execute a opção `5` do teste de bancada;
- aproxime outra tag compatível.

### Buzzer apenas estala

O projeto espera um buzzer ativo. Verifique o componente e a ligação no GPIO 4.

### Relé permanece ligado

- desligue a alimentação antes de corrigir;
- confirme se o módulo é ativo em `LOW` ou `HIGH`;
- revise `RELE_LIGADO` e `RELE_DESLIGADO`;
- confira o GPIO 26;
- execute o teste de bancada sem carga conectada.

### Não conecta ao Wi-Fi

- confira SSID e senha;
- use uma rede compatível com 2,4 GHz;
- aproxime o terminal do ponto de acesso;
- verifique se a rede exige portal de autenticação;
- abra o monitor serial.

### Mostra “Sem servidor”

- teste `/health` em outro dispositivo da mesma rede;
- não use `localhost` no ESP32;
- confira IP e porta da API;
- confira o firewall do computador;
- verifique se backend e banco estão em execução.

### Mostra “Chave do terminal recusada”

- confirme ID e chave no `credenciais.h`;
- verifique se a chave foi trocada;
- grave novamente o firmware;
- confirme que o terminal existe no sistema;
- não reutilize a chave de outro terminal.

### MQTT não conecta

- confira host e porta;
- confirme que o Mosquitto está em execução;
- confira a senha do terminal no broker;
- reinicie o broker depois do provisionamento;
- em TLS, confira porta e certificado CA;
- observe o estado retornado no monitor serial.

Enquanto a API estiver acessível, o terminal utiliza a consulta HTTP de reserva para as decisões de QR.

### QR não é lido pelo celular

- aguarde o QR novo;
- limpe o display e a câmera;
- reduza reflexos;
- ajuste a distância;
- confirme que o terminal obteve o token da API;
- teste o QR gerado no modo de bancada;
- use um display TFT adequado.

### NFC lê, mas não libera

- consulte o motivo no histórico;
- confirme que a tag está vinculada e ativa;
- confirme que o usuário está ativo;
- verifique autorização, local, data, horário e usos;
- confira se o terminal está associado à catraca correta.

### Terminal aparece fora do ar

- aguarde até 30 segundos após ligar;
- confira Wi-Fi e API;
- teste o endpoint de heartbeat por meio do firmware;
- abra o monitor serial;
- confirme ID e chave;
- lembre que o estado muda para fora do ar após cerca de 90 segundos sem sinal.

### Decisão aparece, mas a catraca não abre

- confira se a decisão foi realmente liberada;
- observe LED verde, bipe e clique do relé;
- teste o relé no modo de bancada;
- confira a ligação entre relé e mecanismo;
- confira a fonte externa da trava;
- não alimente a trava pelo GPIO do ESP32.

## 25. Segurança

- Mantenha a chave do terminal somente no firmware e nos serviços autorizados.
- Use uma chave diferente para cada terminal.
- Não compartilhe o arquivo `credenciais.h`.
- Troque imediatamente uma chave exposta.
- Não permita MQTT anônimo.
- Preserve a ACL que limita cada terminal ao próprio tópico.
- Use MQTT com TLS e API HTTPS fora do ambiente local.
- Use certificados CA válidos para verificar os servidores.
- Não mantenha credenciais de demonstração em produção.
- Restrinja o acesso físico ao ESP32 e à porta USB.
- Não permita acionamento direto do relé por fontes não autenticadas.
- Revise logs e terminais fora do ar regularmente.

## 26. Limitações atuais

- O terminal depende de Wi-Fi e da API para validar acessos.
- Sem API, QR e NFC não podem ser autorizados.
- O fallback HTTP substitui temporariamente a entrega MQTT, mas não o backend.
- A conexão HTTPS do protótipo pode operar sem validação da CA quando ela não estiver configurada; produção deve fornecer a CA.
- O OLED possui resolução insuficiente para uma experiência normal de QR.
- O firmware utiliza algumas esperas bloqueantes durante conexão, bipes e chamadas HTTP.
- A chave precisa ser atualizada manualmente no equipamento após uma rotação.

## 27. Checklist de instalação

### Hardware

- [ ] ESP32 alimentado e reconhecido.
- [ ] Display testado.
- [ ] MFRC522 alimentado em 3,3 V e testado.
- [ ] LEDs e buzzer testados.
- [ ] Relé inicia desligado e retorna ao estado desligado.
- [ ] GND comum confirmado.

### Configuração

- [ ] Wi-Fi e endereços conferidos.
- [ ] Terminal associado à catraca correta.
- [ ] ID e chave armazenados com segurança.
- [ ] Credencial incluída no broker.
- [ ] `credenciais.h` permanece fora do Git.

### Operação

- [ ] Terminal aparece **No ar**.
- [ ] QR é renovado e pode ser lido.
- [ ] NFC identifica uma tag.
- [ ] Acesso liberado aciona LED, buzzer e relé.
- [ ] Acesso negado não aciona o relé.
- [ ] MQTT funciona ou o fallback HTTP foi confirmado.
- [ ] Histórico registra as tentativas.

## 28. Documentos relacionados

- `arduino/README.md`: comandos rápidos do firmware;
- `docs/hardware.md`: materiais e pinagem;
- `docs/montagem-terminal.html`: montagem passo a passo;
- `docs/terminal-iot.md`: funcionamento e provisionamento;
- `docs/rede-do-prototipo.md`: rede local e firewall;
- `docs/documentacao-tecnica/firmware-esp32.md`: firmware detalhado;
- `docs/documentacao-tecnica/qr-code-nfc.md`: regras de QR e NFC;
- `docs/documentacao-tecnica/mqtt.md`: broker, ACL e TLS;
- `docs/manuais/manual-instalacao.md`: instalação geral do sistema.
