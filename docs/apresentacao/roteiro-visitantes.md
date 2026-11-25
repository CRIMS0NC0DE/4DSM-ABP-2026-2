# Roteiro para os visitantes

Para a apresentação aberta do Passe (25/11/2026). Serve para quem passa pela mesa, sem
conhecimento técnico: **3 minutos de conversa e 2 de demonstração**, que dá para repetir a cada
grupo. No fim há a versão de 1 minuto, as perguntas mais comuns e o que fazer se algo falhar.

A frase que tem que ficar: **"o celular vira a chave do prédio, e quem decide se a porta abre é
sempre o servidor, nunca o aparelho da porta".**

---

## Antes de abrir a mesa (15 minutos antes)

Na ordem. O passo a passo detalhado de cada item está no `relatorio-modificacoes.md`, seção 6.

1. Backend no ar: `docker compose -f docker-compose.dev.yml up -d database mqtt backend`.
2. Terminal gravado para a rede da sala: `bash scripts/gravar-terminal.sh` (com o ESP32 no USB).
3. App no celular: `bash scripts/app-no-celular.sh` e abra, no celular da demo, o endereço que ele
   mostra (ou leia o QR que ele desenha no terminal).
4. Conferência geral: `node backend/scripts/checar-apresentacao.mjs`. Tem que terminar em
   "✅ Nenhum problema". Os avisos dizem o que fazer.
5. Na mesa: o kit ligado (OLED mostrando o QR), as duas tags, o celular da demo já logado como
   **morador@passe.com**, e o notebook aberto no **Painel** (admin) e no **simulador** numa
   segunda aba (`http://localhost:3000/simulador/`), que é o plano B.

---

## 1. Abertura (20 s)

> "Oi! Esse é o **Passe**, um sistema de controle de acesso para prédios e condomínios. Em vez de
> chave, cartão de papel ou interfone, você entra com o celular. Posso mostrar em dois minutos?"

Aponte para o kit: "Isso aqui faz o papel da catraca da portaria."

## 2. O problema (30 s)

> "Hoje, numa portaria, o porteiro precisa conferir quem é morador, quem é visitante, se o visitante
> pode entrar naquela hora... E cartão de acesso pode ser emprestado ou copiado."

> "No Passe, cada pessoa tem uma **autorização**: em qual catraca pode entrar, em quais dias, em
> qual horário e quantas vezes. O sistema confere tudo isso sozinho, na hora."

## 3. Como funciona (40 s)

Mostre o kit e conte as três formas de entrar:

| Forma | O que a pessoa faz | Por que é seguro |
|---|---|---|
| **QR Code** | Abre o app e aponta a câmera para a tela da catraca | O QR troca a cada 10 segundos, vale uma vez só, e o app manda a localização: quem está longe da portaria não entra |
| **Tag NFC** (chaveiro ou cartão) | Encosta no leitor | Se perder, a própria pessoa bloqueia a tag pelo app, na hora |
| **Celular como chave** (Android com NFC) | Encosta o celular no leitor | O celular assina um desafio com uma chave que nunca sai do aparelho (em fase de teste) |

> "O aparelho da catraca não decide nada: ele só mostra o QR e lê o cartão. **Quem decide é o
> servidor**, e a resposta chega na catraca em menos de um segundo."

## 4. Demonstração (2 min)

| # | O que fazer | O que falar | O que aparece |
|---|---|---|---|
| 1 | Mostre o OLED | "Esse QR muda a cada 10 segundos. Uma foto dele não serve depois." | QR novo a cada 10 s |
| 2 | No celular (morador), toque em **Escanear QR Code** e leia o QR do OLED | "O app manda o QR e a minha localização para o servidor." | No celular: "Acesso liberado"; no kit: "OK / Pode passar" e LED verde |
| 3 | Encoste a tag da Maria (`6EACD706`) | "Com o cartão é a mesma coisa, sem precisar do app." | LED verde, "Acesso liberado" |
| 4 | No app: **Minha tag NFC** → bloquear. Encoste de novo | "Perdi o cartão? Eu mesmo bloqueio, sem ligar para ninguém." | LED vermelho, "Sua tag está bloqueada" |
| 5 | No notebook, abra o **Histórico de acessos** (admin) | "Tudo fica registrado: quem, onde, quando, e por que foi negado." | As tentativas que acabamos de fazer, com o motivo |

Depois do passo 4, desbloqueie a tag para o próximo grupo (admin → **Tags NFC** → desbloquear).

### Se a pessoa quiser mais (1 a 2 min)

- **"Meus visitantes"** (é a novidade de hoje). No celular do morador: **Meus visitantes** → **Novo
  visitante**. Preencha com dados **fictícios** (ex.: "Visitante Teste", `teste1@exemplo.com`,
  CPF `123.456.789-01`), a catraca e o horário de agora. O app mostra uma **senha provisória**.
  > "O morador avisa quem vai chegar, sem passar pela portaria. O visitante só entra naquela
  > catraca, naquele dia e naquele horário, e no máximo 2 vezes."
  Se o visitante quiser testar no próprio celular, mostre o QR do endereço do app (o
  `app-no-celular.sh` imprime) para ele entrar com o e-mail fictício e a senha provisória.
  **Não use o CPF nem o e-mail de verdade de ninguém.**
- **Painel e Relatórios** (admin): acessos de hoje, negados, gráfico por dia e os motivos mais
  comuns de recusa.
- **Comunicados**: o admin publica um aviso e ele aparece no início do app do morador.
- **Simulador**: mostra o "QR já usado" e o "celular longe da catraca" (botões do celular de teste).

## 5. Fechamento (10 s)

> "É um projeto do 4º semestre de DSM da FATEC: app em Flutter, servidor em Node com banco
> Postgres, e o terminal com ESP32, que a gente montou e programou. Obrigado!"

---

## Versão de 1 minuto (mesa cheia)

1. "O Passe troca a chave do prédio pelo celular." (aponta o kit)
2. Lê o QR do OLED com o app → LED verde. "O QR muda a cada 10 s e só vale uma vez."
3. Encosta a tag → LED verde. "Cartão também funciona, e dá para bloquear pelo app."
4. "Quem decide é sempre o servidor, e tudo fica registrado." (mostra o Histórico)

---

## Perguntas comuns

**E se alguém tirar foto do QR e mandar para outra pessoa?**
O QR vale 30 segundos e uma vez só. E o app manda a localização: quem não está perto da catraca
recebe "Você está longe da catraca".

**E se a internet cair?**
O terminal recebe as decisões por MQTT; se o broker cair, ele pergunta ao servidor a cada 2
segundos. Sem Wi-Fi, a tela mostra "Sem Wi-Fi" e ele tenta de novo sozinho. A tag NFC continua
dependendo do servidor, que é quem decide.

**Dá para enganar a catraca e mandar um "abrir" falso?**
Não. O broker exige usuário e senha, e só o servidor pode publicar decisões. Cada terminal só lê
o próprio canal. Se a chave do terminal vazar, o admin troca pelo app e a antiga para na hora.

**Por que não tem uma catraca de verdade?**
O terminal recebe o comando "ABRIR" e acende o LED verde. Numa catraca real, é só ligar o atuador
no pino que já está reservado para isso.

**Por que a tela é tão pequena?**
É o display do kit (0,96"). O QR foi ajustado para ele: o código ficou 1 caractere menor, o que
deixou cada quadradinho do QR com o dobro do tamanho.

**Meus dados ficam guardados?**
A senha é guardada só como hash (não dá para ler de volta). A localização só é usada na hora de
entrar, para saber se a pessoa está perto da catraca.

**Funciona no iPhone?**
Pelo navegador, sim (o app web). O "celular como chave" por NFC é só no Android.

---

## Se algo der errado na hora

| O que aparece | Provável causa | O que fazer |
|---|---|---|
| OLED: "Sem Wi-Fi" | O ESP32 está gravado para outra rede | `bash scripts/gravar-terminal.sh` com `WIFI_SSID` e `WIFI_SENHA` da rede da sala |
| OLED: "Sem servidor" | API fora do ar, IP do PC mudou ou a chave não bate | `node backend/scripts/checar-apresentacao.mjs` e seguir o que ele disser |
| App: "Você está longe da catraca" | A coordenada da Catraca 1 não é a da sala | Admin → **Locais** → Catraca 1 → corrigir latitude/longitude (raio 300 m) |
| App: "Fora do horário permitido" | A autorização vale das 06:00 às 23:00 | Admin → **Autorizações** → editar o horário |
| App: "Não foi possível falar com o servidor" | O celular saiu da rede do PC | Conferir o Wi-Fi do celular; recarregar a página |
| Celular não abre a câmera | Página aberta por `http://` | Abrir o endereço `https://...:8443` que o `app-no-celular.sh` mostrou |
| Tag não faz nada | Fio do leitor solto (MISO, D19) | Apertar os fios do leitor; seguir pelo simulador |
| Nada funciona no kit | — | **Plano B:** tudo pelo simulador (`/simulador/`), com o kit desligado na mesa |
