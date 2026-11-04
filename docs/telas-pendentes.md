# Telas pendentes do app Passe

Atualizado em 04/11/2026, no merge da `dev-thiago` com a `main`.

O levantamento de 02/11 vinha com um código-base para copiar e colar. Esse código já está no projeto, então o código-base saiu do repositório e esta lista ficou só com o que falta.

## 1. O que já foi feito

- **Telas:** todas as que tinham código-base, nos quatro perfis: Histórico e Acessos negados, Autorizações, Usuários, Visitantes, Locais, Tags NFC, Terminais, Relatórios, Painel, Ajuda, Perfil, Minha tag NFC e Início.
- **Backend:**
  - B2: os eventos trazem o texto do motivo.
  - B3: quem é desativado perde o acesso na hora.
  - B4: "Ativa" é a autorização que vale hoje. Agendadas e sem usos têm filtro próprio.
  - B6: a pessoa bloqueia a própria tag.

## 2. Opções de menu sem tela

Ao tocar, mostram "tela em construção".

| Opção | Perfil | Depende de |
| --- | --- | --- |
| Meus visitantes | Morador | **B8:** rotas em `/me` e a regra de negócio (decisão D4) |
| Comunicados | Admin | **B10:** modelo, migration e rotas (decisão D3) |
| Configurações | Admin | **B10:** tabela e rotas (decisão D3) |

O terminal no Flutter (telas T1 a T3) também não existe: `lib/views/terminal/` está vazia (decisão D5).

## 3. Backend que falta

| # | Mudança | O que acontece sem ela |
| --- | --- | --- |
| B5 | `PATCH` e `DELETE` de edifício, portaria e porta; `DELETE` de catraca | A tela Locais cria tudo e edita a catraca, mas não edita nem apaga o resto |
| B12 | Rota agregada para relatórios | A tela Relatórios soma só os 200 acessos mais recentes |

## 4. Ajustes em telas que já existem

| Onde | Ajuste |
| --- | --- |
| Login | "Entrar com NFC" ainda diz "em construção", e o design não tem esse botão |
| Login | "Registrar" abre uma tela que só avisa que não está disponível (decisão D1) |
| Android | O nome do app aparece como "public" (`android:label`). Trocar para "Passe" |
| API | Latitude, longitude e raio fora da faixa respondem com a mensagem em inglês do zod (ex.: "Too small: expected number to be >=10"). O app valida antes, mas o console web mostra a mensagem crua |
| API | `GET /access-events?ate=2026-11-02` lê a data como meia-noite em UTC e corta o dia. O app contorna mandando data e hora |
| Seed | A autorização do seed só vale das 06:00 às 23:00. Cuidado ao demonstrar à noite |

## 5. Decisões do grupo ainda abertas

As mesmas do `backlog-sprint.md`. A D2 (o Início abre depois do login do morador e do visitante) e a D6 (o que conta como ativa) já foram aplicadas.

| # | Decisão | Recomendação |
| --- | --- | --- |
| D1 | Cadastro pelo app: criar rota ou seguir o design? | Seguir o design: tirar "Registrar" e mostrar "Peça seu cadastro na portaria" |
| D3 | Comunicados e Configurações ficam no menu? | Tirar. Exigem modelo, migration e rotas, e nenhum RF pede |
| D4 | Meus visitantes: qual a regra? | Tirar do menu nesta entrega. A portaria já cobre com a tela Visitantes |
| D5 | O terminal (T1 a T3) precisa existir no Flutter? | Só se a disciplina exigir. O simulador web e o ESP32 já fazem esse papel |
