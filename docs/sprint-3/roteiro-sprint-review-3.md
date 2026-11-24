# Roteiro da Sprint Review 3

São 13 slides, para uns 10 minutos mais a demonstração. Cada slide tem o que vai na tela e o que
falar. Os números e o estado de cada item vêm de [`novidades-sprint-3.md`](novidades-sprint-3.md);
se algo mudar antes da apresentação, atualize lá e aqui.

A linha da apresentação: **a Sprint 2 entregou o software; a Sprint 3 documentou tudo e levou o
terminal para o hardware de verdade.** O que faltou entra como roadmap, com o motivo.

---

## 1. Capa

**Na tela:** Passe · Sprint Review 3. Abaixo: "Controle de acesso por QR Code e NFC". Nomes da
equipe.

**Fala:** Uma frase sobre o produto. Quem não viu as reviews anteriores precisa entender em 10
segundos.

## 2. Onde paramos

**Na tela:** à esquerda, o que a Sprint 2 entregou, em três linhas:

- App nos quatro perfis
- API, banco e broker na nuvem
- Firmware do ESP32

À direita, os cinco cards prometidos para a Sprint 3: #33 GPS, #34 kit, #35 diagramas, #36
eficiência energética e #37 deploy.

**Fala:** "Na última review mostramos o software pronto e prometemos estes cinco itens. Agora
mostramos o que aconteceu com cada um."

## 3. Placar da Sprint 3

**Na tela:** os cinco cards com o estado:

| Card | Estado |
|---|---|
| #35 Diagramas | ✅ Entregue |
| #34 Kit montado | 🔶 Em andamento (LEDs e display ok, leitor NFC em montagem) |
| #37 Deploy | ⏸️ Parado pelo CI |
| #33 GPS no terminal | ⏳ Não começou |
| #36 Eficiência energética | ⏳ Não começou |

Embaixo, em destaque, o que não estava no plano: **9 documentos técnicos**.

**Fala:** Mostre o placar inteiro de uma vez, sem esconder o que não saiu. Cada item tem um slide
adiante.

## 4. Documentação técnica

**Na tela:** uma grade com os 9 documentos, cada um com uma linha do que cobre (a tabela está em
`novidades-sprint-3.md`). No canto: "7,3 mil linhas · rotas conferidas contra o código".

**Fala:** A `instalacao-ambiente.md` explica como rodar tudo do zero, e cada parte do sistema tem o
seu documento. A documentação da API foi conferida rota por rota contra o código.

**Quem apresenta:** Eric.

## 5. Diagramas: casos de uso e classes

**Na tela:** `docs/arquitetura/diagrama-de-caso-de-uso.png` e `diagrama-de-classe.png`, lado a
lado.

**Fala:**

- **Casos de uso:** o morador e o visitante usam o app para entrar; a equipe administra.
- **Classes:** a autorização liga uma pessoa a um ponto de acesso, com período, horário e número
  de usos.

**Quem apresenta:** Vinicius.

## 6. Diagramas: sequência e atividade

**Na tela:** `diagrama-de-sequencia.png` (QR em cima, NFC embaixo) e `diagrama-de-atividade.png`.

**Fala:**

- **QR:** a decisão volta ao terminal pelo MQTT.
- **NFC:** a decisão volta na própria resposta HTTP.
- **Atividade:** mostra cada ponto em que o acesso é negado.

**Antes de apresentar:** troque "Acionar relé" por "Indicar liberação" nos dois diagramas.

## 7. O hardware mudou

**Na tela:** uma tabela Antes × Agora.

| | Sprint 2 | Sprint 3 |
|---|---|---|
| Display | TFT 1,54" colorido (SPI) | OLED 0,96" (I2C) |
| Abertura | Relé | Tela e LEDs |
| Som | Buzzer | Sem som |
| Fios | 23 | 17 |

**Fala:** "Montamos com as peças do kit. O OLED usa só dois fios de sinal, e a montagem ficou mais
simples. O terminal continua recebendo `ABRIR`: numa catraca de verdade, basta ligar o atuador."

## 8. Montagem do kit

**Na tela:** a foto `kit-montado.jpg` e, ao lado, o estado de cada etapa do guia:

| Etapa | Estado |
|---|---|
| ESP32 | ✅ |
| LEDs | ✅ |
| Display | ✅ |
| Leitor NFC | 🔶 |

Embaixo: "Guia passo a passo, com teste em cada etapa".

**Fala:** O guia de montagem (`docs/montagem-terminal.html`) tem desenho das ligações, um teste em
cada etapa e uma conferência fio a fio. Mostre-o aberto por 10 segundos.

**Quem apresenta:** Thiago.

## 9. Firmware no OLED

**Na tela:** a foto `oled-liberado.jpg` e dois itens:

- Os avisos "Conectando" e "Sem servidor" não apareciam no OLED: corrigido.
- "Pode passar" e "Acesso negado" se sobrepunham ao texto de baixo: corrigido.

E uma linha: "Teste de bancada para o OLED: `pio run -e teste-oled`".

**Fala:** O firmware já tinha a opção do OLED, mas com essas duas falhas. Elas apareceram no teste
com o display e foram corrigidas. O firmware do TFT ficou igual.

## 10. Risco: o tamanho do QR

**Na tela:** dois quadrados em escala:

- **QR atual no OLED:** 33×33 módulos, 1 ponto por módulo, uns 6 mm.
- **QR com o token 1 caractere menor:** 29×29 módulos, 2 pontos por módulo, uns 10 mm.

**Fala:** É o maior risco técnico da sprint. O plano é testar com o app; se não ler bem, encurtamos
o token, o que muda uma linha no backend. Mostrar o risco com o plano passa segurança.

## 11. Qualidade e CI

**Na tela:** o CI com os jobs e uma frase: "Vermelho desde 11/11 por uma atualização do Flutter
(3.50.1), sem mudança no nosso código."

Depois a correção ("versão do Flutter fixa no workflow") e o `ci-verde.png`, se já estiver
corrigido.

**Fala:** Mostra que o CI cumpre o papel dele: avisou na hora. Explique por que fixar versões no CI
evita esse tipo de quebra.

## 12. Demonstração

**Na tela:** uma lista curta de passos. Apresente ao vivo, no kit:

| Passo | O que fazer | Resultado esperado |
|---|---|---|
| 1 | Ligar o kit | "Conectando" e depois o QR no OLED |
| 2 | Ler o QR com o app | "OK / Pode passar" e LED verde |
| 3 | Encostar uma tag cadastrada | Liberado |
| 4 | Encostar uma tag sem cadastro | "X / Acesso negado" e LED vermelho |

Depois de um acesso, o kit já mostra um QR novo. Por isso o "QR reutilizado" e o "celular longe da
catraca" ficam para o simulador (`/simulador/`), que tem o celular de teste.

**Plano B:** se o kit não estiver pronto ou o QR não ler, faça tudo no simulador e mostre o kit
desligado na mesa.

## 13. Próximos passos (Sprint 4)

**Na tela:** a tabela "Para a Sprint 4" de `novidades-sprint-3.md`, com as 6 prioridades.

**Fala:** Feche com o que vem e com a pergunta ao professor: o GPS no terminal (#33) e a
eficiência energética (#36) continuam no escopo?

---

## Perguntas que o professor pode fazer

**Sem relé, como a catraca abre?** O terminal recebe `ABRIR` e liga o LED verde. O código do relé
continua no firmware (pino D26), então numa catraca de verdade é só ligar o atuador.

**Por que o código da `main` não mudou nesta sprint?** A sprint foi de documentação, diagramas e
hardware. Os ajustes do firmware para o OLED estão no PR do kit.

**Por que o OLED, se o QR fica pequeno?** Foi o display do kit. O risco é conhecido e tem plano:
encurtar o token deixa cada módulo com o dobro do tamanho.

**E o GPS?** Hoje a checagem de distância usa o GPS do celular, e a posição da catraca é cadastrada
pelo script de provisionamento. O GPS no terminal faria a catraca informar a própria posição, e não
começou.

**O CI vermelho não é um problema?** Foi uma atualização externa do Flutter. O CI avisou, a causa
foi achada e a correção é fixar a versão. A falha está na análise estática; o código do app não
mudou desde 11/11.

## Antes da apresentação

- [ ] Consertar o CI e tirar a foto dele verde.
- [ ] Terminar o leitor NFC, gravar o firmware com o OLED e **testar o QR do OLED com o app**.
- [ ] Cadastrar uma tag para o morador de demonstração e separar outra sem cadastro.
- [ ] Trocar "Acionar relé" por "Indicar liberação" nos diagramas de sequência e de atividade.
- [ ] Tirar as fotos da lista em `novidades-sprint-3.md`.
- [ ] Abrir o PR do guia e do firmware do OLED.
- [ ] Ensaiar a demonstração uma vez, com o plano B aberto no navegador.
