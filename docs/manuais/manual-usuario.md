# Manual do usuário

| Campo | Informação |
|---|---|
| Sistema | Passe — Controle de acesso por QR Code e NFC |
| Público | Moradores e visitantes |
| Aplicação | Aplicativo Flutter |
| Revisão | 11/11/2026 |
| Base do manual | Funcionalidades disponíveis no projeto atual |

## 1. Objetivo

Este manual explica como moradores e visitantes utilizam o aplicativo Passe para consultar autorizações e entrar em locais permitidos por QR Code ou tag NFC.

Também são apresentados os procedimentos para consultar o histórico, verificar acessos negados, visualizar a tag vinculada, conferir os dados do perfil e solicitar ajuda à portaria.

## 2. Perfis atendidos

O aplicativo possui dois perfis de usuário final.

| Função | Morador | Visitante |
|---|---:|---:|
| Consultar autorizações | Sim | Sim |
| Entrar por QR Code | Sim | Sim |
| Entrar com tag NFC vinculada | Sim | Sim |
| Consultar histórico pessoal | Sim | Sim |
| Consultar acessos negados | Sim | Sim |
| Consultar a própria tag | Sim | Sim |
| Bloquear a própria tag pelo aplicativo | Sim | Não |
| Opção “Meus visitantes” | Aparece, mas está em construção | Não aparece |
| Consultar perfil e ajuda | Sim | Sim |

As autorizações, os dados cadastrais e os vínculos de tags são administrados pela portaria ou por um administrador.

## 3. Antes de começar

Para utilizar o aplicativo, é necessário:

- possuir uma conta ativa cadastrada pela portaria;
- conhecer o e-mail ou CPF e a senha do cadastro;
- ter uma autorização válida para a catraca desejada;
- permitir o uso da câmera e da localização para entrar por QR Code;
- ter conexão no celular durante o acesso por QR Code.

Para entrar por NFC, é necessário possuir uma tag ativa vinculada ao cadastro.

## 4. Primeiro acesso e login

### 4.1 Obter uma conta

O cadastro direto pelo aplicativo ainda não está disponível. Mesmo que a tela apresente a opção **Registrar**, ao tentar concluir o cadastro o aplicativo orientará o usuário a procurar a portaria.

Solicite à portaria:

- criação do cadastro;
- definição da senha inicial;
- perfil correto, como morador ou visitante;
- autorização necessária;
- vínculo de uma tag NFC, quando aplicável.

### 4.2 Entrar no aplicativo

1. Abra o Passe.
2. No campo **E-mail ou CPF**, informe um dos identificadores cadastrados.
3. Digite sua senha.
4. Toque em **Entrar**.
5. Aguarde a abertura da tela inicial.

Se o aplicativo informar que os dados não conferem, revise o e-mail, o CPF e a senha. Após várias tentativas sem sucesso, procure a portaria.

### 4.3 Esquecimento de senha

O aplicativo ainda não recupera a senha automaticamente. Toque em **Esqueci minha senha** para ver a orientação e solicite uma nova senha à portaria. Leve um documento para confirmar sua identidade.

### 4.4 Entrada no aplicativo por NFC

A opção **Entrar com NFC** ainda está em construção. A tag NFC é usada no terminal da catraca, não para fazer login no aplicativo.

## 5. Tela inicial

Depois do login, o aplicativo apresenta:

- uma saudação com o primeiro nome do usuário;
- a data atual;
- um resumo da próxima autorização ativa ou agendada;
- o botão **Escanear QR Code**;
- o botão **Menu**.

Quando existe uma autorização, o cartão mostra a catraca, o edifício, a validade, o horário e os usos disponíveis. Toque em **Ver detalhes** para consultar todas as informações.

Quando nenhuma autorização válida estiver disponível, solicite uma liberação à portaria.

Arraste a tela para baixo para atualizar as informações.

## 6. Menu do usuário

### 6.1 Opções disponíveis para morador e visitante

| Opção | Finalidade |
|---|---|
| Escanear QR Code | Ler o QR exibido no terminal da catraca |
| Minhas autorizações | Consultar locais, períodos, horários e usos |
| Histórico de acessos | Consultar entradas liberadas e negadas |
| Acessos negados | Ver o motivo de cada recusa e o que fazer |
| Minha tag NFC | Consultar a tag vinculada e seu estado |
| Perfil | Conferir nome, perfil, e-mail, CPF e tag |
| Ajuda | Consultar orientações e contato da portaria |

### 6.2 Opção exclusiva do menu do morador

A opção **Meus visitantes** aparece para moradores, mas ainda está em construção. No momento, o cadastro e a autorização de visitantes devem ser solicitados à portaria.

## 7. Minhas autorizações

### 7.1 Consultar a lista

1. Na tela inicial, toque em **Menu**.
2. Abra **Minhas autorizações**.
3. Consulte as seções **Ativas** e **Encerradas**.
4. Toque em uma autorização ou em **Ver detalhes**.

O cartão informa:

- catraca e edifício;
- situação;
- período permitido;
- horário permitido;
- quantidade de usos restantes.

Arraste a tela para baixo para atualizar a lista.

### 7.2 Situações da autorização

| Situação | Significado |
|---|---|
| Ativa | Pode ser utilizada, respeitando horário, local e usos |
| Agendada | Começará a valer na data informada |
| Sem usos | Todos os usos disponíveis já foram utilizados |
| Expirada | O período permitido terminou |
| Cancelada | A portaria cancelou a autorização |

As autorizações ativas e agendadas aparecem na seção **Ativas**. As demais aparecem em **Encerradas**.

### 7.3 Consultar os detalhes

A tela de detalhes apresenta:

- portaria, porta e catraca permitidas;
- data inicial e data final;
- horário permitido;
- total e quantidade de usos restantes;
- orientação sobre quando será possível entrar.

Quando a autorização está ativa, a tela também apresenta o botão **Escanear QR Code**.

O usuário não pode criar, editar ou cancelar uma autorização. Solicite alterações à portaria.

## 8. Entrar por QR Code

O QR Code é exibido na tela do terminal da catraca. Ele muda com frequência e deve ser lido pelo aplicativo no momento da entrada.

### 8.1 Preparar o celular

Antes de escanear:

1. Ative a internet do celular.
2. Ative a localização ou o GPS.
3. Permita que o Passe use a câmera.
4. Permita o uso da localização enquanto estiver utilizando o aplicativo.
5. Aproxime-se da catraca autorizada.

### 8.2 Escanear o código

1. Na tela inicial, toque em **Escanear QR Code**. A opção também está disponível no menu e nos detalhes de uma autorização ativa.
2. Aponte a câmera para o QR exibido na catraca.
3. Mantenha o celular parado, aproximadamente a um palmo da tela.
4. Se o ambiente estiver escuro, use **Ligar lanterna**.
5. Aguarde a mensagem **Verificando seu acesso**.

Se o aplicativo informar que o código não é de uma catraca, confira se a câmera está apontada para o QR correto.

### 8.3 Acesso liberado

Quando a validação for aprovada, a tela ficará verde e mostrará:

- confirmação de acesso liberado;
- catraca e caminho do local;
- horário da liberação;
- quantidade de usos restantes.

Passe pela catraca e toque em **Voltar ao início**.

### 8.4 Acesso negado

Quando a validação for recusada, a tela ficará vermelha e mostrará:

- o motivo da recusa;
- a orientação sobre o que fazer;
- **Tentar novamente**;
- **Voltar ao início**.

Leia a orientação antes de tentar novamente. Como o QR muda rapidamente, uma nova tentativa deve usar o código atual exibido pelo terminal.

### 8.5 Câmera sem permissão

Se o aplicativo não tiver acesso à câmera:

1. Toque em **Abrir configurações**.
2. Permita o uso da câmera para o Passe.
3. Volte ao aplicativo.
4. Abra novamente o scanner.

### 8.6 Localização ausente

Se a localização estiver desativada ou sem permissão:

1. Toque em **Permitir localização**.
2. Ative o serviço de localização do celular, se necessário.
3. Autorize o Passe a obter sua posição.
4. Volte ao scanner.
5. Leia o novo QR exibido na catraca.

A localização é utilizada no momento da passagem para confirmar que o usuário está próximo da catraca.

## 9. Entrar com tag NFC

Para utilizar uma tag:

1. Confirme em **Minha tag NFC** se ela está ativa.
2. Aproxime a tag do leitor do terminal.
3. Aguarde a indicação de liberação ou recusa.
4. Passe pela catraca somente após a liberação.

A tag não substitui a autorização. O cadastro deve estar ativo e deve existir uma autorização válida para a catraca, data, horário e quantidade de usos.

O celular não participa da leitura NFC. Portanto, a internet do celular não é necessária para aproximar a tag física, mas o terminal e o sistema de acesso precisam estar funcionando.

## 10. Minha tag NFC

### 10.1 Consultar a tag

1. Abra o **Menu**.
2. Toque em **Minha tag NFC**.
3. Confira o final do UID e a situação:
   - **Ativa**: pode ser utilizada no terminal;
   - **Bloqueada**: não libera a catraca.

Se nenhuma tag estiver vinculada, solicite o vínculo à portaria.

### 10.2 Bloquear uma tag — morador

O morador pode bloquear a própria tag:

1. Abra **Minha tag NFC**.
2. Toque em **Bloquear tag**.
3. Leia o aviso.
4. Toque em **Bloquear** para confirmar.

O bloqueio é imediato. Para voltar a utilizar a tag, será necessário solicitar o desbloqueio à portaria.

### 10.3 Tag de visitante

O visitante pode consultar a tag, mas não possui o botão de bloqueio no aplicativo. Em caso de perda ou furto, deve avisar a portaria imediatamente para que ela seja bloqueada.

### 10.4 Perda ou furto

- Não espere até a próxima visita para informar a perda.
- Moradores devem bloquear a tag pelo aplicativo, quando possível.
- Visitantes devem solicitar o bloqueio à portaria.
- Depois de recuperar a tag, solicite o desbloqueio à portaria.

## 11. Histórico de acessos

### 11.1 Consultar o histórico pessoal

1. Abra **Histórico de acessos**.
2. Consulte suas tentativas liberadas e negadas.
3. Toque em **Filtrar** para escolher:
   - período: tudo, hoje, 7 dias ou 30 dias;
   - resultado: todos, liberados ou negados;
   - método: QR Code ou tag NFC.
4. Toque em **Mostrar resultados**.

São carregados 50 registros por vez. Quando houver mais eventos, toque em **Carregar mais**.

### 11.2 Consultar somente recusas

Abra **Acessos negados** para ver somente as tentativas recusadas. A tela mostra o motivo e uma orientação sobre o que fazer.

Use essa área antes de procurar a portaria, pois a causa pode ser uma permissão de localização, um horário incorreto ou uma autorização encerrada.

## 12. Perfil

Na tela **Perfil**, é possível consultar:

- nome;
- tipo de perfil;
- e-mail;
- CPF parcialmente oculto;
- situação e final da tag NFC;
- ajuda e contato da portaria;
- informações sobre o aplicativo.

Os dados são somente para consulta. Para corrigir nome, CPF, e-mail ou senha, procure a portaria.

Também é possível encerrar a sessão por **Sair da conta**.

## 13. Ajuda

A tela **Ajuda** contém:

- telefone da portaria;
- horário de atendimento;
- orientações para problemas comuns com QR Code, tag, senha e autorização.

No código atual do projeto, o telefone exibido é demonstrativo e ainda precisa ser substituído pelo contato real do edifício. Confirme o canal correto de atendimento com a administração.

## 14. Motivos comuns de acesso negado

| Situação | O que fazer |
|---|---|
| Sem localização | Ative o GPS, conceda a permissão e leia o novo QR |
| Longe da catraca | Aproxime-se do terminal autorizado e tente novamente |
| QR de outro lugar | Aponte para o QR mostrado pelo terminal da catraca |
| QR vencido | Aguarde o novo código e escaneie novamente |
| QR já utilizado | Leia um novo QR; cada código só pode ser usado uma vez |
| Sem autorização | Solicite uma autorização à portaria |
| Autorização agendada | Aguarde a data e o horário permitidos |
| Autorização expirada | Solicite uma nova autorização |
| Sem usos restantes | Solicite mais usos ou uma nova autorização |
| Local incorreto | Dirija-se à catraca indicada na autorização |
| Cadastro desativado | Procure a portaria para verificar o cadastro |
| Tag bloqueada | Solicite o desbloqueio à portaria |
| Tag desconhecida | Solicite o vínculo correto da tag à portaria |
| Sem conexão no celular | Confira Wi-Fi ou dados móveis e tente ler outro QR |

Sempre siga a mensagem apresentada na tela, pois ela corresponde à recusa registrada naquele momento.

## 15. Uso sem internet no celular

Sem conexão no celular:

- não é possível validar um QR Code;
- autorizações, perfil e histórico podem não carregar;
- uma tag NFC ativa ainda pode ser aproximada do terminal, pois a leitura não depende do aplicativo no celular.

Se os dados já estavam visíveis e a atualização falhar, o aplicativo pode manter a tela anterior e mostrar uma mensagem. Restabeleça a conexão e atualize a tela.

## 16. Funções ainda não disponíveis

Na versão atual:

- o cadastro público pelo aplicativo não cria uma conta;
- a recuperação automática de senha não está implementada;
- o login por NFC está em construção;
- **Meus visitantes**, no menu do morador, está em construção;
- o usuário não altera os próprios dados cadastrais;
- o visitante não bloqueia a própria tag pela interface.

Solicite essas ações à portaria quando necessário.

## 17. Sair do aplicativo

É possível sair de duas maneiras:

1. Abra **Menu** e toque em **Sair da conta**; ou
2. Abra **Perfil** e toque em **Sair da conta**.

O aplicativo apagará do dispositivo o token e os dados locais da sessão e retornará ao login.

Sempre saia da conta quando utilizar um celular ou computador compartilhado.

## 18. Solução de problemas

| Problema | Solução |
|---|---|
| Login não funciona | Revise e-mail, CPF e senha; depois procure a portaria |
| Conta desativada | Solicite a verificação do cadastro à portaria |
| Autorizações não aparecem | Atualize a tela e confirme se a portaria criou a liberação |
| Câmera não abre | Conceda a permissão de câmera nas configurações |
| QR não é reconhecido | Limpe a lente, ajuste a distância e aponte para o QR correto |
| Validação fica sem localização | Ative o GPS e conceda a permissão ao Passe |
| Acesso continua negado | Leia o motivo, consulte a autorização e procure a portaria |
| Tag não funciona | Confira se está ativa e se há autorização válida |
| Tag perdida | Bloqueie pelo aplicativo, se for morador, e avise a portaria |
| Dados pessoais estão incorretos | Solicite a correção à portaria |
| Aplicativo voltou ao login | Entre novamente; a sessão pode ter expirado |

## 19. Boas práticas de segurança

- Não compartilhe sua senha.
- Não permita que outra pessoa utilize sua conta ou sua tag.
- Não fotografe nem compartilhe o QR Code da catraca.
- Bloqueie e comunique imediatamente a perda da tag.
- Confira o local e o horário antes de tentar entrar.
- Leia o motivo de uma recusa antes de tentar novamente.
- Mantenha câmera e localização liberadas apenas conforme sua necessidade.
- Saia da conta em dispositivos compartilhados.
- Comunique à portaria acessos do histórico que você não reconhece.

## 20. Checklist rápido para entrar

- [ ] Confirmar que existe uma autorização ativa.
- [ ] Conferir a catraca, o período, o horário e os usos restantes.
- [ ] Aproximar-se da catraca correta.
- [ ] Ativar internet, câmera e localização para utilizar o QR Code.
- [ ] Ler o QR atual ou aproximar uma tag ativa do terminal.
- [ ] Aguardar a confirmação antes de passar.

