# Documentação técnica da API

| Campo | Valor |
|---|---|
| Projeto | Passe — Controle de acesso por QR Code e NFC |
| Componente | API REST do backend |
| Revisão | 11/11/2026 |
| Implementação | Node.js, TypeScript e Express 5 |
| Base da documentação | Controladores, serviços, tipos e testes atuais de `backend/` |

## 1. Visão geral

A API do Passe fornece os contratos HTTP utilizados pelo aplicativo Flutter, pelo console web, pelo simulador e pelos terminais de acesso. Ela permite autenticar pessoas e dispositivos, administrar os dados do sistema, consultar históricos e validar acessos por QR Code ou NFC.

No ambiente local, a URL base padrão é:

```text
http://localhost:3000
```

As rotas não possuem prefixo de versão. Por exemplo, o login é realizado em `POST /auth/login`, e não em `/api/v1/auth/login`.

## 2. Convenções do contrato

### 2.1 Formato dos dados

- Requisições com corpo utilizam `Content-Type: application/json`.
- Respostas da API utilizam JSON, exceto `DELETE /users/:id/tags/:tagId`, que responde sem corpo.
- Identificadores são UUIDs.
- Datas de autorização usam `AAAA-MM-DD`.
- Horários usam `HH:MM`, no formato de 24 horas.
- Instantes completos são devolvidos em ISO 8601.
- O corpo JSON possui limite de 100 KB.
- Campos opcionais sem valor podem não aparecer na resposta JSON.
- A paginação do histórico utiliza `limite` e `pular`, não números de página.

### 2.2 Códigos de sucesso

| Código | Uso |
|---|---|
| `200 OK` | Consulta, atualização ou operação concluída |
| `201 Created` | Usuário, tag, local, autorização ou terminal criado |
| `204 No Content` | Tag removida com sucesso |

### 2.3 Níveis de acesso

| Nome usado neste documento | Regra |
|---|---|
| Público | Não exige autenticação |
| Autenticado | Aceita qualquer perfil com JWT válido e cadastro ativo |
| Equipe | Exige `ADMIN` ou `CONTROLADOR_ACESSO` |
| Administrador | Exige `ADMIN` |
| Terminal | Exige identificador e chave válidos do dispositivo |

## 3. Autenticação

### 3.1 Autenticação de usuário

Após o login, as rotas protegidas recebem o token no cabeçalho:

```http
Authorization: Bearer <token-jwt>
```

O servidor verifica a assinatura e a expiração do JWT e consulta o usuário atual no banco. Por isso, desativar a conta ou alterar o perfil tem efeito imediato mesmo que o token ainda não tenha expirado.

### 3.2 Autenticação de terminal

As rotas iniciadas por `/terminal` exigem:

```http
X-Terminal-Id: 11111111-1111-4111-8111-111111111111
X-Terminal-Key: <chave-do-terminal>
```

A chave aparece somente na resposta de cadastro ou rotação e deve ser armazenada com segurança no terminal.

## 4. Resumo dos endpoints

| Método | Endpoint | Acesso | Sucesso |
|---|---|---|---|
| `GET` | `/health` | Público | `200` |
| `POST` | `/auth/login` | Público | `200` |
| `GET` | `/auth/me` | Autenticado | `200` |
| `GET` | `/me/authorizations` | Autenticado | `200` |
| `GET` | `/me/access-events` | Autenticado | `200` |
| `PATCH` | `/me/tags/:tagId` | Autenticado | `200` |
| `POST` | `/access/qr` | Autenticado | `200` |
| `GET` | `/users` | Equipe | `200` |
| `POST` | `/users` | Equipe | `201` |
| `GET` | `/users/:id` | Equipe | `200` |
| `PATCH` | `/users/:id` | Equipe | `200` |
| `POST` | `/users/:id/tags` | Equipe | `201` |
| `PATCH` | `/users/:id/tags/:tagId` | Equipe | `200` |
| `DELETE` | `/users/:id/tags/:tagId` | Equipe | `204` |
| `GET` | `/locations` | Equipe | `200` |
| `POST` | `/locations/buildings` | Administrador | `201` |
| `POST` | `/locations/gates` | Administrador | `201` |
| `POST` | `/locations/doors` | Administrador | `201` |
| `POST` | `/locations/access-points` | Administrador | `201` |
| `GET` | `/locations/access-points/:id` | Equipe | `200` |
| `PATCH` | `/locations/access-points/:id` | Administrador | `200` |
| `GET` | `/authorizations` | Equipe | `200` |
| `POST` | `/authorizations` | Equipe | `201` |
| `GET` | `/authorizations/:id` | Equipe | `200` |
| `PATCH` | `/authorizations/:id` | Equipe | `200` |
| `POST` | `/authorizations/:id/cancel` | Equipe | `200` |
| `GET` | `/access-events` | Equipe | `200` |
| `GET` | `/dashboard` | Equipe | `200` |
| `GET` | `/terminals` | Equipe | `200` |
| `POST` | `/terminals` | Administrador | `201` |
| `POST` | `/terminals/:id/rotate-key` | Administrador | `200` |
| `GET` | `/terminal/qr-token` | Terminal | `200` |
| `POST` | `/terminal/heartbeat` | Terminal | `200` |
| `POST` | `/terminal/nfc` | Terminal | `200` |
| `GET` | `/terminal/decisions` | Terminal | `200` |
| `GET` | `/simulador/config.json` | Público | `200` |

## 5. Disponibilidade

### `GET /health`

Verifica se o processo da API está respondendo.

Resposta `200`:

```json
{
  "status": "ok",
  "em": "2026-11-11T20:00:00.000Z"
}
```

Essa rota confirma o funcionamento do servidor HTTP, mas não executa uma consulta explícita ao banco nem ao broker MQTT.

## 6. Autenticação e sessão

### `POST /auth/login`

Autentica por e-mail ou CPF. O CPF pode ser enviado com ou sem pontuação.

Corpo:

```json
{
  "login": "usuario@exemplo.com",
  "senha": "senha-informada-pelo-usuario"
}
```

Resposta `200`:

```json
{
  "token": "<jwt>",
  "usuario": {
    "id": "11111111-1111-4111-8111-111111111111",
    "nome": "Usuário Exemplo",
    "email": "usuario@exemplo.com",
    "cpf": "12345678901",
    "perfil": "CONDOMINO",
    "ativo": true,
    "createdAt": "2026-11-11T12:00:00.000Z",
    "updatedAt": "2026-11-11T12:00:00.000Z"
  }
}
```

Credenciais incorretas respondem `401` sem revelar se o e-mail ou CPF existe.

### `GET /auth/me`

Retorna os dados públicos do usuário da sessão, incluindo suas tags quando disponíveis. O hash da senha nunca é devolvido.

## 7. Recursos pessoais

### `GET /me/authorizations`

Lista somente as autorizações do usuário autenticado. A resposta é um array de autorizações no formato descrito na seção 11.

### `GET /me/access-events`

Lista somente os eventos do usuário autenticado.

Parâmetros opcionais:

| Parâmetro | Valores |
|---|---|
| `de` | Data/hora aceita pelo JavaScript, preferencialmente ISO 8601 |
| `ate` | Data/hora aceita pelo JavaScript, preferencialmente ISO 8601 |
| `resultado` | `LIBERADO` ou `NEGADO` |
| `metodo` | `QR` ou `NFC` |
| `accessPointId` | UUID do ponto de acesso |
| `limite` | De 1 a 200; padrão 50 |
| `pular` | Inteiro a partir de 0; padrão 0 |

O parâmetro `userId` não é aceito nessa rota; o usuário é obtido do JWT.

### `PATCH /me/tags/:tagId`

Permite ao usuário bloquear uma tag própria.

Corpo aceito:

```json
{
  "ativa": false
}
```

O próprio usuário não pode usar essa rota para reativar a tag. O desbloqueio é realizado pela equipe em `PATCH /users/:id/tags/:tagId`.

## 8. Validação de acesso por QR

### `POST /access/qr`

Valida o QR mostrado por um terminal e registra a tentativa. A rota exige JWT, mas permite que o serviço receba o pedido de um usuário que acabou de ser desativado para registrar e explicar a negação.

Corpo:

```json
{
  "token": "P1.CONTEUDO-DO-QR",
  "latitude": -23.000000,
  "longitude": -45.000000
}
```

`latitude` e `longitude` são opcionais no contrato de entrada, mas a ausência de uma delas causa uma decisão negada por falta de localização.

Resposta de acesso liberado:

```json
{
  "liberado": true,
  "titulo": "Acesso liberado",
  "catraca": {
    "id": "22222222-2222-4222-8222-222222222222",
    "nome": "Catraca 1",
    "caminho": "Edifício › Portaria › Porta"
  },
  "usosRestantes": 4,
  "distanciaMetros": 12,
  "eventoId": "33333333-3333-4333-8333-333333333333",
  "em": "2026-11-11T20:00:00.000Z"
}
```

Resposta de acesso negado:

```json
{
  "liberado": false,
  "motivo": "LONGE_DO_TERMINAL",
  "titulo": "Você está longe da catraca",
  "oQueFazer": "Chegue mais perto da catraca e tente de novo.",
  "catraca": {
    "id": "22222222-2222-4222-8222-222222222222",
    "nome": "Catraca 1",
    "caminho": "Edifício › Portaria › Porta"
  },
  "distanciaMetros": 950,
  "eventoId": "33333333-3333-4333-8333-333333333333",
  "em": "2026-11-11T20:00:00.000Z"
}
```

Uma negação válida da regra de acesso responde `200`, pois a API processou a tentativa corretamente. Falhas no contrato HTTP, na autenticação ou na permissão utilizam códigos `4xx`.

Motivos possíveis:

| Código | Significado |
|---|---|
| `QR_INVALIDO` | Formato ou assinatura do QR inválidos |
| `QR_EXPIRADO` | Prazo do QR encerrado |
| `QR_JA_UTILIZADO` | QR já consumido anteriormente |
| `TERMINAL_DESCONHECIDO` | Terminal ou ponto de acesso não encontrado |
| `USUARIO_INATIVO` | Cadastro do usuário desativado |
| `SEM_AUTORIZACAO` | Nenhuma autorização para o ponto de acesso |
| `AUTORIZACAO_CANCELADA` | Autorização cancelada |
| `AUTORIZACAO_EXPIRADA` | Data final já passou |
| `AUTORIZACAO_NAO_INICIADA` | Data inicial ainda não chegou |
| `FORA_DO_HORARIO` | Tentativa fora da janela permitida |
| `SEM_USOS` | Limite de utilizações atingido |
| `LOCALIZACAO_AUSENTE` | Coordenadas do celular não informadas |
| `LONGE_DO_TERMINAL` | Distância maior que o raio do ponto de acesso |

## 9. Usuários e tags NFC

As operações exigem equipe. O controlador de acesso pode criar ou alterar apenas `CONDOMINO` e `VISITANTE`; o administrador pode gerenciar todos os perfis.

### `GET /users`

Filtros opcionais:

| Parâmetro | Descrição |
|---|---|
| `busca` | Pesquisa por nome, e-mail ou CPF |
| `perfil` | `ADMIN`, `CONTROLADOR_ACESSO`, `CONDOMINO` ou `VISITANTE` |

Resposta: array de usuários com tags, sem `senhaHash`.

### `POST /users`

Corpo:

```json
{
  "nome": "Pessoa Exemplo",
  "email": "pessoa@exemplo.com",
  "cpf": "12345678901",
  "senha": "senha-com-6-ou-mais-caracteres",
  "perfil": "VISITANTE"
}
```

Regras principais:

- `nome` deve ter pelo menos 3 caracteres após remoção de espaços externos.
- `email` precisa ser válido e único.
- `cpf` precisa conter 11 números e ser único.
- `senha` precisa ter pelo menos 6 caracteres.
- `perfil` deve ser um dos quatro perfis definidos pela API.

### `GET /users/:id`

Retorna um usuário e suas tags. Responde `404` quando o UUID não corresponde a um usuário existente.

### `PATCH /users/:id`

Aceita qualquer subconjunto dos campos de criação e também:

```json
{
  "ativo": false
}
```

O usuário autenticado não pode desativar a própria conta nem trocar o próprio perfil. E-mail e CPF continuam sujeitos à unicidade.

### `POST /users/:id/tags`

Corpo:

```json
{
  "uid": "04:A1:B2:C3"
}
```

O UID aceita caracteres hexadecimais e separadores. A resposta apresenta o UID normalizado, por exemplo `04A1B2C3`. A mesma tag não pode ser vinculada a duas pessoas.

### `PATCH /users/:id/tags/:tagId`

Corpo:

```json
{
  "ativa": true
}
```

Ativa ou bloqueia a tag indicada.

### `DELETE /users/:id/tags/:tagId`

Remove a associação da tag. Em caso de sucesso, responde `204` sem conteúdo.

## 10. Locais

A hierarquia é `edifício → portaria → porta → ponto de acesso`.

### `GET /locations`

Retorna a árvore completa:

```json
[
  {
    "id": "11111111-1111-4111-8111-111111111111",
    "nome": "Edifício Exemplo",
    "endereco": "Rua Exemplo, 100",
    "portarias": [
      {
        "id": "22222222-2222-4222-8222-222222222222",
        "nome": "Portaria Principal",
        "buildingId": "11111111-1111-4111-8111-111111111111",
        "portas": []
      }
    ]
  }
]
```

### `POST /locations/buildings`

```json
{
  "nome": "Edifício Exemplo",
  "endereco": "Rua Exemplo, 100"
}
```

### `POST /locations/gates`

```json
{
  "nome": "Portaria Principal",
  "buildingId": "11111111-1111-4111-8111-111111111111"
}
```

### `POST /locations/doors`

```json
{
  "nome": "Porta A",
  "gateId": "22222222-2222-4222-8222-222222222222"
}
```

### `POST /locations/access-points`

```json
{
  "nome": "Catraca 1",
  "doorId": "33333333-3333-4333-8333-333333333333",
  "latitude": -23.000000,
  "longitude": -45.000000,
  "raioMetros": 100
}
```

O raio é opcional na criação, com padrão de 100 metros, e deve ficar entre 10 e 1.000 metros.

### `GET /locations/access-points/:id`

Retorna o ponto de acesso com os nomes do edifício, da portaria e da porta.

### `PATCH /locations/access-points/:id`

Aceita qualquer subconjunto de `nome`, `doorId`, `latitude`, `longitude` e `raioMetros`.

## 11. Autorizações

### Formato de resposta

As respostas de autorização acrescentam `situacao` e `usosRestantes` aos dados persistidos:

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "userId": "22222222-2222-4222-8222-222222222222",
  "accessPointId": "33333333-3333-4333-8333-333333333333",
  "dataInicio": "2026-11-11",
  "dataFim": "2026-11-30",
  "horaInicio": "08:00",
  "horaFim": "18:00",
  "maxUsos": 10,
  "usosRealizados": 2,
  "status": "ATIVA",
  "canceladaEm": null,
  "createdAt": "2026-11-11T12:00:00.000Z",
  "user": {
    "id": "22222222-2222-4222-8222-222222222222",
    "nome": "Pessoa Exemplo",
    "perfil": "VISITANTE"
  },
  "catraca": {
    "id": "33333333-3333-4333-8333-333333333333",
    "nome": "Catraca 1",
    "edificio": "Edifício Exemplo",
    "portaria": "Portaria Principal",
    "porta": "Porta A"
  },
  "situacao": "ATIVA",
  "usosRestantes": 8
}
```

`status` representa o valor persistido (`ATIVA` ou `CANCELADA`). `situacao` é calculada e pode ser `ATIVA`, `AGENDADA`, `EXPIRADA`, `ESGOTADA` ou `CANCELADA`.

### `GET /authorizations`

Filtros opcionais:

| Parâmetro | Valores |
|---|---|
| `userId` | UUID do usuário |
| `accessPointId` | UUID do ponto de acesso |
| `situacao` | `ATIVA`, `AGENDADA`, `EXPIRADA`, `ESGOTADA` ou `CANCELADA` |
| `de` | Data `AAAA-MM-DD` |
| `ate` | Data `AAAA-MM-DD` |

### `POST /authorizations`

```json
{
  "userId": "22222222-2222-4222-8222-222222222222",
  "accessPointId": "33333333-3333-4333-8333-333333333333",
  "dataInicio": "2026-11-11",
  "dataFim": "2026-11-30",
  "horaInicio": "08:00",
  "horaFim": "18:00",
  "maxUsos": 10
}
```

`maxUsos` deve estar entre 1 e 10.000. A data final não pode ser anterior à inicial, e os horários inicial e final não podem ser iguais. Janelas que atravessam a meia-noite são aceitas pelas regras de acesso.

### `GET /authorizations/:id`

Retorna uma autorização no formato completo.

### `PATCH /authorizations/:id`

Aceita qualquer subconjunto de `accessPointId`, `dataInicio`, `dataFim`, `horaInicio`, `horaFim` e `maxUsos`. `userId` não pode ser alterado. Uma autorização cancelada não pode ser editada, e `maxUsos` não pode ficar abaixo dos usos já realizados.

### `POST /authorizations/:id/cancel`

Cancela a autorização. A operação é idempotente: cancelar novamente uma autorização já cancelada devolve o estado atual.

## 12. Histórico e painel

### `GET /access-events`

Filtros opcionais:

| Parâmetro | Valores |
|---|---|
| `de` | Data/hora inicial |
| `ate` | Data/hora final |
| `resultado` | `LIBERADO` ou `NEGADO` |
| `metodo` | `QR` ou `NFC` |
| `userId` | UUID do usuário |
| `accessPointId` | UUID do ponto de acesso |
| `limite` | 1 a 200; padrão 50 |
| `pular` | 0 ou maior; padrão 0 |

Resposta:

```json
{
  "itens": [
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "metodo": "NFC",
      "resultado": "NEGADO",
      "motivo": "TAG_DESCONHECIDA",
      "userId": null,
      "accessPointId": "22222222-2222-4222-8222-222222222222",
      "terminalId": "33333333-3333-4333-8333-333333333333",
      "authorizationId": null,
      "credencial": "AABBCCDD",
      "latitude": null,
      "longitude": null,
      "distanciaMetros": null,
      "createdAt": "2026-11-11T20:00:00.000Z",
      "user": null,
      "catraca": {
        "id": "22222222-2222-4222-8222-222222222222",
        "nome": "Catraca 1"
      },
      "titulo": "Tag não cadastrada",
      "oQueFazer": "Peça para a portaria vincular sua tag."
    }
  ],
  "total": 1,
  "liberados": 0,
  "negados": 1
}
```

### `GET /dashboard`

Retorna o resumo desde a meia-noite no fuso configurado pela aplicação:

```json
{
  "acessosHoje": 12,
  "negadosHoje": 3,
  "negadosRecentes": [],
  "autorizacoesAtivas": 8
}
```

`negadosRecentes` contém no máximo cinco eventos no mesmo formato enriquecido do histórico.

## 13. Terminais

### `GET /terminals`

Retorna os terminais sem `chave` e sem `chaveHash`. O campo `online` é verdadeiro quando o último heartbeat ocorreu há menos de 90 segundos.

### `POST /terminals`

```json
{
  "nome": "Terminal Catraca 1",
  "accessPointId": "11111111-1111-4111-8111-111111111111"
}
```

Resposta `201`:

```json
{
  "id": "22222222-2222-4222-8222-222222222222",
  "nome": "Terminal Catraca 1",
  "accessPointId": "11111111-1111-4111-8111-111111111111",
  "ultimoSinal": null,
  "latitude": null,
  "longitude": null,
  "online": false,
  "chave": "<chave-exibida-uma-unica-vez>"
}
```

Um ponto de acesso pode possuir apenas um terminal.

### `POST /terminals/:id/rotate-key`

Gera uma nova chave e invalida imediatamente a anterior. A resposta tem o mesmo formato do terminal e inclui a nova `chave` uma única vez.

## 14. API do dispositivo

### `GET /terminal/qr-token`

Resposta:

```json
{
  "token": "P1.CONTEUDO-ASSINADO",
  "expiraEm": "2026-11-11T20:00:30.000Z",
  "trocarEmSegundos": 10
}
```

O token é assinado pelo backend, expira por padrão em 30 segundos e possui identificador de uso único.

### `POST /terminal/heartbeat`

O corpo pode ser vazio:

```json
{}
```

Ou conter a localização do terminal:

```json
{
  "latitude": -23.000000,
  "longitude": -45.000000
}
```

Quando ambas as coordenadas são fornecidas, elas passam a ser a referência de distância do acesso por QR. A resposta retorna o terminal atualizado, sem a chave, e `online: true`.

### `POST /terminal/nfc`

Corpo:

```json
{
  "uid": "04:A1:B2:C3"
}
```

A resposta utiliza o mesmo formato de decisão de `POST /access/qr`. Além dos motivos gerais de autorização, o NFC pode responder:

| Motivo | Significado |
|---|---|
| `TAG_DESCONHECIDA` | UID não vinculado a um usuário |
| `TAG_BLOQUEADA` | Tag encontrada, mas inativa |

### `GET /terminal/decisions`

Consulta as decisões armazenadas em memória para fallback quando o MQTT não estiver disponível.

Parâmetro:

| Parâmetro | Regra |
|---|---|
| `apos` | Sequência mínima exclusiva; inteiro a partir de 0, padrão 0 |

Resposta:

```json
[
  {
    "seq": 15,
    "decisao": {
      "acao": "ABRIR",
      "metodo": "QR",
      "mensagem": "Acesso liberado",
      "nome": "Pessoa",
      "em": "2026-11-11T20:00:00.000Z"
    }
  }
]
```

São mantidas em memória, no máximo, as 20 decisões mais recentes de cada terminal. Essa fila não é persistida entre reinicializações do backend.

## 15. Simulador

### `GET /simulador/config.json`

Retorna o endereço MQTT WebSocket e, somente no ambiente de desenvolvimento, os dados de preenchimento da demonstração.

Em produção ou sem configuração:

```json
{
  "mqttWsUrl": null,
  "demo": null
}
```

As páginas estáticas ficam disponíveis em `/simulador/` e `/console/`.

## 16. Erros

### 16.1 Formato padrão

```json
{
  "erro": {
    "codigo": "DADOS_INVALIDOS",
    "mensagem": "Dados inválidos.",
    "detalhes": {
      "campo": [
        "Mensagem de validação"
      ]
    }
  }
}
```

`detalhes` aparece quando há informações adicionais, como os campos rejeitados pelo Zod.

### 16.2 Códigos HTTP

| Status | Código de exemplo | Causa |
|---|---|---|
| `400` | `DADOS_INVALIDOS` | Corpo, parâmetros ou consulta fora do contrato |
| `400` | `JSON_INVALIDO` | Corpo não é um JSON válido |
| `401` | `NAO_AUTENTICADO` | JWT ausente, inválido ou expirado; terminal não identificado |
| `401` | `CADASTRO_DESATIVADO` | Usuário com cadastro desativado |
| `403` | `SEM_PERMISSAO` | Perfil sem acesso à operação |
| `404` | `NAO_ENCONTRADO` | Recurso não localizado |
| `404` | `ROTA_NAO_ENCONTRADA` | Método e caminho não registrados |
| `409` | `CONFLITO` | Duplicidade ou regra incompatível com o estado atual |
| `413` | `CORPO_GRANDE_DEMAIS` | Corpo acima de 100 KB |
| `415` | `CORPO_NAO_SUPORTADO` | Formato de corpo não aceito |
| `500` | `ERRO_INTERNO` | Falha inesperada do servidor |

### 16.3 Exemplo de rota inexistente

```json
{
  "erro": {
    "codigo": "ROTA_NAO_ENCONTRADA",
    "mensagem": "GET /rota-inexistente não existe."
  }
}
```

## 17. Exemplos de consumo

### Login com PowerShell

```powershell
$corpo = @{
    login = "usuario@exemplo.com"
    senha = "senha-do-usuario"
} | ConvertTo-Json

$sessao = Invoke-RestMethod `
    -Method Post `
    -Uri "http://localhost:3000/auth/login" `
    -ContentType "application/json" `
    -Body $corpo
```

### Requisição autenticada

```powershell
$cabecalhos = @{
    Authorization = "Bearer $($sessao.token)"
}

Invoke-RestMethod `
    -Method Get `
    -Uri "http://localhost:3000/me/authorizations" `
    -Headers $cabecalhos
```

### Verificação rápida com curl

```powershell
curl.exe -sS http://localhost:3000/health
```

## 18. Referências no projeto

- `backend/src/app.ts`: montagem das rotas e middlewares.
- `backend/src/modules/*/*.controller.ts`: contratos de entrada dos endpoints.
- `backend/src/modules/*/*.service.ts`: regras e formatos das respostas.
- `backend/src/shared/http/`: autenticação, validação e erros HTTP.
- `backend/tests/api/`: comportamento esperado dos endpoints.
- `backend/.env.example`: configuração do ambiente.
- `docs/documentacao-tecnica/backend.md`: arquitetura e implementação interna do backend.

