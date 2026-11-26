# Manual do administrador

| Campo | Informação |
|---|---|
| Sistema | Passe — Controle de acesso por QR Code e NFC |
| Público | Administradores do condomínio ou edifício |
| Aplicação | Aplicativo Flutter |
| Revisão | 11/11/2026 |
| Base do manual | Funcionalidades disponíveis no projeto atual |

## 1. Objetivo

Este manual orienta o administrador no uso do aplicativo Passe. O perfil de administrador pode acompanhar acessos, cadastrar pessoas e locais, administrar autorizações e tags NFC, configurar terminais e consultar relatórios.

As instruções descrevem somente as funções implementadas no aplicativo atual.

## 2. Antes de começar

Para utilizar o aplicativo, é necessário:

- possuir uma conta ativa com perfil **Administrador**;
- ter acesso à internet ou à rede em que a API do Passe está disponível;
- informar o e-mail ou CPF e a senha cadastrados;
- manter os dados de acesso em segurança.

Se a conta ainda não existir, solicite o cadastro a outro administrador responsável pelo sistema. O registro público de uma conta administrativa não está disponível.

## 3. Entrar no sistema

1. Abra o aplicativo Passe.
2. No campo **E-mail ou CPF**, informe um dos identificadores cadastrados.
3. No campo **Senha**, informe sua senha.
4. Toque em **Entrar**.
5. Após a autenticação, o aplicativo abrirá o menu **Administrador**.

Se os dados não conferirem, o aplicativo exibirá uma mensagem de erro. Revise o e-mail, o CPF e a senha antes de tentar novamente.

### 3.1 Esquecimento de senha

O aplicativo ainda não realiza recuperação automática de senha. Ao tocar em **Esqueci minha senha**, a orientação é solicitar uma nova senha à equipe responsável. Outro administrador pode definir uma senha na edição do cadastro do usuário.

### 3.2 Entrada por NFC

A opção **Entrar com NFC** ainda está em construção. A tag NFC é utilizada nas catracas, não no login do aplicativo.

## 4. Menu do administrador

O menu está organizado em três grupos.

| Grupo | Opção | Finalidade |
|---|---|---|
| Controle de acesso | Painel | Consultar o resumo dos acessos do dia |
| Controle de acesso | Autorizações | Definir quem pode entrar, onde e quando |
| Controle de acesso | Histórico de acessos | Consultar entradas liberadas e negadas |
| Controle de acesso | Acessos negados | Consultar somente recusas e seus motivos |
| Cadastros | Usuários | Cadastrar e editar pessoas e perfis |
| Cadastros | Visitantes | Cadastrar visitantes e liberar acessos temporários |
| Cadastros | Locais | Organizar edifícios, portarias, portas e catracas |
| Cadastros | Tags NFC | Vincular, bloquear, desbloquear ou remover tags |
| Gestão | Terminais | Cadastrar os leitores das catracas e acompanhar seu estado |
| Gestão | Relatórios | Consultar totais e agrupamentos de acessos |
| Gestão | Comunicados | Em construção |
| Gestão | Configurações | Em construção |

Nas telas que carregam dados, arraste o conteúdo para baixo para atualizar a consulta.

## 5. Painel

O **Painel** apresenta um resumo do dia:

- quantidade de acessos registrados hoje;
- quantidade de acessos negados hoje;
- quantidade de autorizações ativas;
- lista dos acessos negados mais recentes.

Os cartões funcionam como atalhos:

- toque em **Ver histórico** para abrir todos os eventos;
- toque em **Ver motivos** para consultar somente os acessos negados;
- toque em **Ver autorizações** para abrir a lista de autorizações.

Para liberar um novo acesso diretamente pelo painel, toque em **Nova autorização**.

## 6. Usuários

### 6.1 Consultar usuários

1. No menu, toque em **Usuários**.
2. Utilize o campo de busca para procurar por nome, e-mail ou CPF.
3. Se necessário, filtre a lista por perfil:
   - Administrador;
   - Controlador de acesso;
   - Morador;
   - Visitante.
4. Toque em um cadastro para abrir a edição.

Cada cartão informa o perfil, a situação do cadastro e o estado da tag NFC, quando existir.

### 6.2 Cadastrar um usuário

1. Na tela **Usuários**, toque em **Novo usuário**.
2. Preencha:
   - nome completo;
   - CPF com 11 números;
   - e-mail válido;
   - senha inicial com pelo menos 6 caracteres;
   - perfil da pessoa.
3. Toque em **Criar usuário**.

O CPF e o e-mail devem ser únicos. Informe a senha inicial à pessoa por um meio seguro.

### 6.3 Editar um usuário

1. Localize a pessoa na lista.
2. Toque no cartão do usuário.
3. Altere os dados necessários.
4. Para trocar a senha, preencha **Nova senha**. Deixe o campo vazio para manter a senha atual.
5. Use **Cadastro ativo** para ativar ou desativar a conta.
6. Toque em **Salvar alterações**.

Um cadastro desativado não consegue passar pela catraca. O administrador não pode desativar a própria conta nem alterar o próprio perfil nessa tela.

## 7. Visitantes

O cadastro de um visitante acontece em duas etapas.

### 7.1 Cadastrar e autorizar um novo visitante

1. No menu, toque em **Visitantes**.
2. Toque em **Novo visitante**.
3. Preencha nome, CPF, e-mail e senha inicial.
4. Toque em **Continuar**.
5. Na segunda etapa, selecione o local de acesso.
6. Defina as datas, os horários e a quantidade de usos.
7. Toque em **Criar autorização**.

Se a segunda etapa for fechada sem salvar, o visitante continuará cadastrado. Para concluir depois, volte à lista **Visitantes**, toque na pessoa e crie a autorização.

### 7.2 Liberar novo acesso para um visitante existente

1. Abra **Visitantes**.
2. Toque no visitante desejado.
3. Informe o local, o período, o horário e a quantidade de usos.
4. Toque em **Criar autorização**.

## 8. Autorizações

Uma autorização determina a pessoa, a catraca, o período, o horário e o número máximo de usos permitidos.

### 8.1 Consultar e filtrar

1. No menu, toque em **Autorizações**.
2. Toque em **Filtrar**.
3. Selecione um ou mais critérios:
   - pessoa;
   - local;
   - status;
   - início do período;
   - fim do período.
4. Toque em **Mostrar resultados**.

Os status exibidos são **Ativa**, **Agendada**, **Sem usos**, **Expirada** e **Cancelada**. Use **Limpar filtros** para voltar à lista completa.

### 8.2 Criar uma autorização

1. Toque em **Nova autorização**.
2. Selecione uma pessoa ativa.
3. Selecione a catraca permitida.
4. Defina a data de início e a data de fim.
5. Defina o horário inicial e o horário final.
6. Informe a quantidade de usos, de 1 a 10.000.
7. Toque em **Criar autorização**.

O horário inicial e o final não podem ser iguais. A data final não pode ser anterior à data inicial.

### 8.3 Editar uma autorização

1. Na lista, toque na autorização.
2. Altere o local, as datas, os horários ou a quantidade de usos.
3. Toque em **Salvar alterações**.

A pessoa vinculada não pode ser trocada. Se a autorização estiver cancelada, ela não poderá ser editada; será necessário criar outra.

### 8.4 Cancelar uma autorização

1. Abra a autorização.
2. Toque em **Cancelar autorização**.
3. Leia o aviso de impacto.
4. Toque em **Sim, cancelar** para confirmar.

O cancelamento impede novos acessos por aquela autorização e não pode ser desfeito. Para liberar novamente, crie uma nova autorização.

## 9. Histórico de acessos

### 9.1 Consultar todos os eventos

1. No menu, toque em **Histórico de acessos**.
2. Consulte os registros liberados e negados.
3. Toque em **Filtrar** para selecionar:
   - período: tudo, hoje, 7 dias ou 30 dias;
   - resultado: todos, liberados ou negados;
   - método: QR Code ou tag NFC;
   - local.
4. Toque em **Mostrar resultados**.

A tela carrega 50 registros por vez. Quando houver mais resultados, toque em **Carregar mais**.

### 9.2 Consultar somente recusas

Abra **Acessos negados**. Essa tela mantém o resultado fixado em negado e mostra o motivo de cada recusa. Use os demais filtros para investigar período, método e local.

O histórico pode ajudar a identificar situações como autorização expirada, falta de usos, local incorreto, tag desconhecida, QR inválido ou ausência de localização.

## 10. Locais

Os locais seguem esta hierarquia:

```text
Edifício
└── Portaria
    └── Porta
        └── Catraca
```

### 10.1 Cadastrar a estrutura

1. No menu, toque em **Locais**.
2. Toque em **Novo edifício** e informe nome e endereço.
3. No edifício, toque no ícone **+** para criar uma portaria.
4. Na portaria, toque no ícone **+** para criar uma porta.
5. Na porta, toque no ícone **+** para criar uma catraca.

Cadastre os níveis na ordem apresentada, porque cada item depende do nível anterior.

### 10.2 Cadastrar ou editar uma catraca

No formulário da catraca, informe:

- nome;
- latitude, entre -90 e 90;
- longitude, entre -180 e 180;
- raio permitido, entre 10 e 1.000 metros.

Se estiver fisicamente ao lado da catraca, toque em **Usar minha localização** para preencher as coordenadas. O recurso depende da permissão de localização do dispositivo.

Toque em **Salvar local**. Para editar uma catraca existente, toque nela na árvore de locais.

No estado atual, edifícios, portarias e portas podem ser criados, mas não possuem edição ou exclusão pela interface. Apenas a catraca pode ser editada.

## 11. Tags NFC

### 11.1 Consultar tags

1. No menu, toque em **Tags NFC**.
2. Pesquise pelo nome da pessoa ou pelo UID da tag.

A lista informa o UID e se a tag está **Ativa** ou **Bloqueada**.

### 11.2 Vincular uma tag

1. Toque em **Vincular tag**.
2. Selecione uma pessoa ativa.
3. Digite o UID apresentado pelo leitor da catraca, por exemplo `04:A1:B2:C3`.
4. Toque em **Vincular**.

O UID aceita de 4 a 40 caracteres hexadecimais, com espaços, dois-pontos ou hífens. O aplicativo não lê a tag diretamente pelo celular; o UID deve ser informado no formulário.

### 11.3 Bloquear ou desbloquear

Use o seletor ao lado da tag:

- desligado: tag bloqueada;
- ligado: tag ativa.

Bloqueie imediatamente uma tag perdida ou furtada. O bloqueio preserva o vínculo e permite a reativação posterior.

### 11.4 Remover uma tag

1. Toque no ícone de lixeira ao lado da tag.
2. Revise a confirmação.
3. Toque em **Remover**.

Se a pessoa apenas perdeu temporariamente a tag, prefira bloquear em vez de remover.

## 12. Terminais

Cada catraca pode possuir um terminal responsável pelo QR Code, pela leitura NFC e pelo acionamento do acesso.

### 12.1 Consultar o estado

Abra **Terminais**. Cada cartão informa:

- nome do terminal;
- catraca associada;
- situação **No ar** ou **Fora do ar**;
- data e hora do último sinal, quando existir.

### 12.2 Cadastrar um terminal

1. Toque em **Novo terminal**.
2. Informe um nome.
3. Selecione uma catraca que ainda não possua terminal.
4. Toque em **Cadastrar**.
5. Copie a chave exibida e guarde-a em local seguro.
6. Somente depois de salvar a chave, toque em **Já guardei**.

A chave é mostrada apenas uma vez. Ela precisa ser configurada no firmware do terminal e no broker MQTT.

### 12.3 Trocar a chave

1. No cartão do terminal, toque em **Trocar chave**.
2. Leia o aviso.
3. Confirme em **Trocar chave**.
4. Copie e guarde a nova chave.
5. Atualize o firmware e o broker MQTT com a nova credencial.

A chave anterior deixa de funcionar imediatamente. O terminal ficará sem comunicação até receber a nova chave.

## 13. Relatórios

1. No menu, toque em **Relatórios**.
2. Escolha o período: tudo, hoje, 7 dias ou 30 dias.
3. Consulte:
   - total de acessos liberados;
   - total de acessos negados;
   - acessos agrupados por local;
   - recusas agrupadas por motivo.

Os totais representam todos os eventos do filtro. Quando houver mais de 200 eventos, os agrupamentos por local e por motivo consideram apenas os 200 acessos mais recentes, e a própria tela apresenta esse aviso.

Não há exportação para PDF, planilha ou CSV na versão atual.

## 14. Funções ainda não disponíveis

As opções abaixo aparecem no menu, mas ainda exibem a mensagem **tela em construção**:

- **Comunicados**;
- **Configurações**.

Também não estão disponíveis no aplicativo atual:

- login por NFC;
- recuperação automática de senha;
- edição ou exclusão de edifícios, portarias e portas;
- exportação de relatórios.

## 15. Sair do sistema

1. Volte ao menu principal do administrador.
2. Toque em **Sair**.
3. Aguarde o retorno à tela de login.

O logout remove do dispositivo o token e os dados locais da sessão. Sempre saia da conta ao utilizar um dispositivo compartilhado.

## 16. Solução de problemas

| Situação | O que fazer |
|---|---|
| E-mail, CPF ou senha não conferem | Revise os dados e tente novamente |
| Conta desativada | Solicite a reativação a outro administrador |
| Aplicativo não carrega dados | Verifique a internet, a API e arraste a tela para baixo para atualizar |
| A lista está vazia | Limpe os filtros e confirme se há cadastros no sistema |
| Usuário não passa na catraca | Verifique se o cadastro e a tag estão ativos e se existe autorização válida |
| Autorização não funciona | Confira catraca, período, horário, quantidade de usos e status |
| UID da tag não é aceito | Informe somente caracteres hexadecimais e separadores permitidos |
| Localização da catraca não é obtida | Autorize o uso da localização ou digite latitude e longitude |
| Terminal aparece fora do ar | Verifique energia, rede, firmware, broker MQTT, ID e chave do terminal |
| Chave do terminal foi perdida | Use **Trocar chave** e atualize o firmware e o broker |
| Sessão voltou ao login | Entre novamente; a sessão pode ter expirado ou deixado de ser válida |

## 17. Boas práticas de segurança

- Não compartilhe contas administrativas.
- Use senhas fortes e diferentes para cada pessoa.
- Envie senhas iniciais por um meio seguro.
- Desative imediatamente contas que não devem mais acessar o local.
- Bloqueie tags perdidas ou furtadas.
- Revise com atenção pessoa, local e período antes de criar uma autorização.
- Guarde as chaves dos terminais fora de documentos públicos e repositórios Git.
- Troque a chave se houver suspeita de exposição.
- Consulte os acessos negados e os terminais fora do ar regularmente.
- Saia da conta em dispositivos compartilhados.

## 18. Checklist rápido do administrador

- [ ] Conferir o painel e as recusas recentes.
- [ ] Verificar terminais fora do ar.
- [ ] Revisar autorizações ativas e agendadas.
- [ ] Desativar cadastros que não devem mais acessar.
- [ ] Bloquear tags comunicadas como perdidas.
- [ ] Conferir acessos negados incomuns.
- [ ] Revisar os relatórios do período.

