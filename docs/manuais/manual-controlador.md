# Manual do controlador de acesso

| Campo | Informação |
|---|---|
| Sistema | Passe — Controle de acesso por QR Code e NFC |
| Público | Controladores de acesso e equipe da portaria |
| Aplicação | Aplicativo Flutter |
| Revisão | 11/11/2026 |
| Base do manual | Funcionalidades disponíveis no projeto atual |

## 1. Objetivo

Este manual orienta o controlador de acesso no uso diário do aplicativo Passe. Esse perfil atende a portaria, acompanha entradas, verifica recusas, cadastra moradores e visitantes, administra autorizações e tags NFC e consulta o estado dos terminais.

O controlador possui permissões diferentes do administrador. Operações de infraestrutura, como cadastrar locais, cadastrar terminais e trocar chaves, devem ser solicitadas a um administrador.

## 2. Antes de começar

Para utilizar o aplicativo, é necessário:

- possuir uma conta ativa com perfil **Controlador de acesso**;
- ter acesso à internet ou à rede em que a API do Passe está disponível;
- conhecer o e-mail ou CPF e a senha cadastrados;
- manter as credenciais da portaria em segurança.

Se a conta ainda não existir ou estiver desativada, solicite o atendimento de um administrador.

## 3. Entrar no sistema

1. Abra o aplicativo Passe.
2. No campo **E-mail ou CPF**, informe um dos identificadores cadastrados.
3. No campo **Senha**, informe sua senha.
4. Toque em **Entrar**.
5. Após a autenticação, o aplicativo abrirá o menu **Controlador de acesso**.

Se os dados não conferirem, revise o e-mail, o CPF e a senha antes de tentar novamente.

### 3.1 Esquecimento de senha

O aplicativo ainda não realiza recuperação automática de senha. Ao tocar em **Esqueci minha senha**, a orientação é procurar o responsável pela administração do sistema.

O controlador não pode alterar o próprio cadastro pela tela de usuários. A troca de sua senha deve ser realizada por um administrador.

### 3.2 Entrada por NFC

A opção **Entrar com NFC** ainda está em construção. A tag NFC é usada para passagem nas catracas, não para entrar no aplicativo.

## 4. Menu do controlador

O menu está organizado em três grupos.

| Grupo | Opção | Finalidade |
|---|---|---|
| Portaria | Painel | Consultar o resumo dos acessos de hoje |
| Portaria | Acessos negados | Ver o motivo e atender quem foi barrado |
| Portaria | Visitantes | Cadastrar visitantes e liberar acessos temporários |
| Portaria | Autorizações | Criar, renovar, editar ou cancelar liberações |
| Cadastros | Usuários | Cadastrar e editar moradores e visitantes |
| Cadastros | Tags NFC | Vincular, bloquear, desbloquear ou remover tags |
| Acompanhamento | Histórico de acessos | Consultar entradas liberadas e negadas |
| Acompanhamento | Terminais | Ver catracas e leitores no ar ou fora do ar |

Nas telas que carregam dados, arraste o conteúdo para baixo para atualizar a consulta.

## 5. Painel da portaria

O **Painel** apresenta:

- quantidade de acessos registrados hoje;
- quantidade de acessos negados hoje;
- quantidade de autorizações ativas;
- acessos negados mais recentes.

Os cartões também são atalhos:

- **Ver histórico** abre todos os eventos;
- **Ver motivos** abre somente as recusas;
- **Ver autorizações** abre a lista de autorizações.

Para liberar uma pessoa diretamente pelo painel, toque em **Nova autorização**.

## 6. Atendimento de um acesso negado

Quando alguém for barrado:

1. Abra **Acessos negados**.
2. Localize a tentativa mais recente da pessoa.
3. Confira nome, catraca, horário, método de entrada e motivo da recusa.
4. Consulte o cadastro da pessoa em **Usuários**.
5. Verifique se o cadastro está ativo.
6. Se o acesso foi por NFC, confira se a tag está vinculada e ativa.
7. Abra **Autorizações** e verifique local, período, horário, usos restantes e situação.
8. Corrija somente o dado necessário e peça que a pessoa tente novamente.

Não crie uma autorização sem confirmar a identidade da pessoa e o local ao qual ela pode ter acesso.

### 6.1 Ações comuns por situação

| Situação encontrada | Ação recomendada |
|---|---|
| Cadastro desativado | Confirmar a situação e reativar somente se autorizado |
| Sem autorização | Criar uma autorização válida |
| Autorização expirada | Criar outra autorização ou ajustar uma autorização ainda editável |
| Quantidade de usos esgotada | Aumentar os usos quando permitido ou criar outra autorização |
| Horário ou data incorretos | Corrigir o período da autorização |
| Catraca diferente | Selecionar o local correto na autorização |
| Tag bloqueada | Confirmar a identidade e desbloquear a tag |
| Tag desconhecida | Obter o UID informado pelo leitor e vinculá-lo à pessoa correta |
| Terminal fora do ar | Comunicar o administrador ou responsável técnico |

O motivo mostrado pelo sistema deve orientar o atendimento. Evite liberar acessos por tentativa sem investigar a causa.

## 7. Usuários

O controlador pode consultar todos os perfis, mas só pode criar e administrar cadastros de **Morador** e **Visitante**. Contas de administrador e de controlador de acesso são gerenciadas pelo administrador.

### 7.1 Consultar usuários

1. No menu, toque em **Usuários**.
2. Procure por nome, e-mail ou CPF.
3. Se necessário, filtre por perfil.
4. Toque em um morador ou visitante para editar.

Os cartões exibem o perfil, a situação do cadastro e o estado da tag NFC. Cadastros da equipe podem ser consultados na lista, mas não apresentam opção de edição ao controlador.

### 7.2 Cadastrar um morador ou visitante

1. Na tela **Usuários**, toque em **Novo usuário**.
2. Preencha:
   - nome completo;
   - CPF com 11 números;
   - e-mail válido;
   - senha inicial com pelo menos 6 caracteres;
   - perfil **Morador** ou **Visitante**.
3. Toque em **Criar usuário**.

O e-mail e o CPF não podem estar vinculados a outra conta. Entregue a senha inicial à pessoa por um meio seguro.

### 7.3 Editar um cadastro

1. Localize o morador ou visitante.
2. Toque no cartão da pessoa.
3. Altere os dados necessários.
4. Para trocar a senha, preencha **Nova senha**. Deixe o campo vazio para manter a senha atual.
5. Use **Cadastro ativo** para ativar ou desativar a conta.
6. Toque em **Salvar alterações**.

Uma pessoa com cadastro desativado não consegue passar pela catraca, mesmo que possua tag e autorização.

## 8. Visitantes

O cadastro de visitante é realizado em duas etapas: dados da pessoa e autorização de acesso.

### 8.1 Cadastrar e liberar um novo visitante

1. No menu, toque em **Visitantes**.
2. Toque em **Novo visitante**.
3. Preencha nome, CPF, e-mail e senha inicial.
4. Toque em **Continuar**.
5. Selecione a catraca permitida.
6. Defina as datas, os horários e a quantidade de usos.
7. Toque em **Criar autorização**.

Se a segunda etapa for fechada sem salvar, o visitante continuará cadastrado. Para concluir depois, abra **Visitantes**, toque na pessoa e crie a autorização.

### 8.2 Liberar novo acesso para um visitante existente

1. Abra **Visitantes**.
2. Toque no visitante desejado.
3. Informe local, período, horário e quantidade de usos.
4. Toque em **Criar autorização**.

## 9. Autorizações

Uma autorização determina quem pode entrar, em qual catraca, durante qual período e quantas vezes.

### 9.1 Consultar e filtrar

1. Abra **Autorizações**.
2. Toque em **Filtrar**.
3. Selecione um ou mais critérios:
   - pessoa;
   - local;
   - status;
   - início do período;
   - fim do período.
4. Toque em **Mostrar resultados**.

Os status disponíveis são **Ativa**, **Agendada**, **Sem usos**, **Expirada** e **Cancelada**. Use **Limpar filtros** para voltar à lista completa.

### 9.2 Criar uma autorização

1. Toque em **Nova autorização**.
2. Selecione uma pessoa ativa.
3. Selecione a catraca permitida.
4. Defina a data inicial e a data final.
5. Defina o horário inicial e o horário final.
6. Informe de 1 a 10.000 usos.
7. Toque em **Criar autorização**.

A data final não pode ser anterior à inicial. O horário inicial e o final não podem ser iguais.

### 9.3 Editar uma autorização

1. Toque na autorização desejada.
2. Altere o local, as datas, os horários ou a quantidade de usos.
3. Toque em **Salvar alterações**.

A pessoa vinculada não pode ser substituída. Se a autorização estiver cancelada, será necessário criar uma nova.

### 9.4 Cancelar uma autorização

1. Abra a autorização.
2. Toque em **Cancelar autorização**.
3. Confira a pessoa e a catraca apresentadas no aviso.
4. Toque em **Sim, cancelar**.

O cancelamento não pode ser desfeito. Para liberar novamente, crie outra autorização.

## 10. Tags NFC

O controlador pode administrar tags de moradores e visitantes. Tags vinculadas a administradores ou a outros controladores são somente para consulta.

### 10.1 Localizar uma tag

1. Abra **Tags NFC**.
2. Pesquise pelo nome da pessoa ou pelo UID da tag.

A tela informa o UID e a situação **Ativa** ou **Bloqueada**.

### 10.2 Vincular uma tag

1. Toque em **Vincular tag**.
2. Selecione um morador ou visitante ativo.
3. Digite o UID apresentado pelo leitor, por exemplo `04:A1:B2:C3`.
4. Toque em **Vincular**.

O UID aceita de 4 a 40 caracteres hexadecimais, com espaços, dois-pontos ou hífens. O aplicativo não lê fisicamente a tag pelo celular; o código deve ser digitado.

Se o UID já estiver vinculado a outra pessoa, confirme a identidade e o cadastro correto antes de realizar qualquer alteração.

### 10.3 Bloquear ou desbloquear

Use o seletor ao lado da tag:

- desligado: tag bloqueada;
- ligado: tag ativa.

Bloqueie imediatamente uma tag comunicada como perdida ou furtada. Antes de desbloquear, confirme a identidade da pessoa.

### 10.4 Remover uma tag

1. Toque no ícone de lixeira ao lado da tag.
2. Leia a confirmação.
3. Toque em **Remover**.

Se a pessoa apenas perdeu temporariamente a tag, prefira bloquear. A remoção desfaz o vínculo com o usuário.

## 11. Histórico de acessos

1. No menu, toque em **Histórico de acessos**.
2. Consulte os eventos liberados e negados.
3. Toque em **Filtrar** para selecionar:
   - período: tudo, hoje, 7 dias ou 30 dias;
   - resultado: todos, liberados ou negados;
   - método: QR Code ou tag NFC;
   - local.
4. Toque em **Mostrar resultados**.

A tela apresenta pessoa, catraca, data, horário, método e resultado. Nos eventos negados, também mostra o motivo da recusa.

São carregados 50 registros por vez. Toque em **Carregar mais** para consultar os próximos eventos.

## 12. Terminais

O controlador possui acesso de consulta aos terminais das catracas.

1. No menu, toque em **Terminais**.
2. Confira o nome e a catraca associada.
3. Observe a situação:
   - **No ar**: o terminal está enviando sinais;
   - **Fora do ar**: o terminal não apresenta comunicação recente.
4. Consulte a data e o horário do último sinal, quando disponíveis.

O controlador não pode cadastrar terminais nem trocar chaves. Se um equipamento estiver fora do ar, registre qual terminal e catraca foram afetados e encaminhe o atendimento ao administrador ou à equipe técnica.

## 13. Funções exclusivas do administrador

As seguintes operações não aparecem no menu do controlador:

- cadastrar ou editar edifícios, portarias, portas e catracas;
- cadastrar terminais;
- trocar chaves de terminais;
- consultar a tela de relatórios;
- administrar contas de administradores e controladores;
- visualizar as opções **Comunicados** e **Configurações**, que ainda estão em construção.

Quando uma dessas ações for necessária, encaminhe ao administrador as informações já verificadas, como pessoa, local, terminal, data, horário e motivo apresentado pelo sistema.

## 14. Passagem de turno

Antes de encerrar o turno, informe à próxima equipe:

- terminais que aparecem fora do ar;
- tags bloqueadas ou pendentes de identificação;
- visitantes aguardados;
- autorizações criadas ou alteradas durante o turno;
- recusas que ainda precisam de atendimento;
- ocorrências encaminhadas ao administrador.

Não compartilhe a senha da sua conta para realizar a passagem de turno.

## 15. Sair do sistema

1. Volte ao menu principal.
2. Toque em **Sair da conta**.
3. Aguarde o retorno à tela de login.

O logout remove do dispositivo o token e os dados locais da sessão. Sempre encerre a sessão ao deixar uma estação ou dispositivo compartilhado.

## 16. Solução de problemas

| Situação | O que fazer |
|---|---|
| E-mail, CPF ou senha não conferem | Revise os dados e tente novamente |
| Conta do controlador desativada | Solicite a reativação a um administrador |
| Aplicativo não carrega dados | Verifique a rede e arraste a tela para baixo para atualizar |
| Pessoa não aparece na busca | Limpe os filtros e pesquise por nome, e-mail ou CPF |
| Não é possível editar uma conta da equipe | A edição de administradores e controladores é exclusiva do administrador |
| Usuário continua sem acesso | Confira cadastro, tag, autorização, local, data, horário e usos |
| UID não é aceito | Use caracteres hexadecimais e os separadores permitidos |
| Tag já está vinculada | Localize o UID e confirme a pessoa correta antes de alterar |
| Autorização não pode ser editada | Verifique se ela foi cancelada; nesse caso, crie outra |
| Terminal aparece fora do ar | Registre terminal, catraca e último sinal e acione o responsável técnico |
| Não aparece opção para cadastrar terminal | Essa ação é exclusiva do administrador |
| Sessão voltou ao login | Entre novamente; a sessão pode ter expirado ou deixado de ser válida |

## 17. Boas práticas de segurança

- Use somente sua própria conta.
- Confirme a identidade antes de alterar cadastro, senha, tag ou autorização.
- Não informe dados pessoais em voz alta ou para pessoas não autorizadas.
- Não crie liberações mais amplas do que o necessário.
- Confira pessoa, catraca, período, horário e usos antes de salvar.
- Bloqueie rapidamente tags perdidas ou furtadas.
- Não remova uma tag quando um bloqueio temporário for suficiente.
- Não compartilhe senhas, tokens ou chaves de terminais.
- Registre e encaminhe comportamentos incomuns ao administrador.
- Saia da conta ao terminar o atendimento ou o turno.

## 18. Checklist rápido da portaria

- [ ] Conferir o painel no início do turno.
- [ ] Verificar acessos negados recentes.
- [ ] Conferir visitantes esperados e suas autorizações.
- [ ] Verificar terminais fora do ar.
- [ ] Resolver tags bloqueadas ou desconhecidas com identificação confirmada.
- [ ] Registrar pendências para a passagem de turno.
- [ ] Sair da conta ao encerrar o trabalho.
