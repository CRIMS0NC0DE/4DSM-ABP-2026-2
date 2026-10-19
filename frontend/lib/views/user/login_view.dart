import 'package:flutter/material.dart';

import '../../controllers/login_controller.dart';
import '../../core/routes/rotas.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_texto.dart';
import '../widgets/logo_passe.dart';
import '../widgets/tela_carregando.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  final LoginController controller;

  LoginView({super.key, LoginController? controller})
    : controller = controller ?? LoginController();

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _form = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _senha = TextEditingController();

  /// Só valida enquanto digita depois da primeira tentativa de entrar.
  var _validarAoDigitar = false;

  /// Esperando a resposta da API; trava o botão para não enviar duas vezes.
  var _entrando = false;

  LoginController get controller => widget.controller;

  @override
  void dispose() {
    _usuario.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_entrando) return;
    if (!_form.currentState!.validate()) {
      setState(() => _validarAoDigitar = true);
      return;
    }
    setState(() => _entrando = true);
    final usuario = _usuario.text.trim();
    final senha = _senha.text;
    try {
      // A tela de carregamento troca o login pelo menu do perfil, para o
      // Voltar do celular não voltar ao login.
      await TelaCarregando.abrir(
        context,
        mensagem: 'Entrando…',
        tarefa: () async {
          final conta = await controller.entrar(usuario, senha);
          return menuDoPerfil(conta.perfil);
        },
      );
    } on ApiException catch (erro) {
      // A mensagem vem da API, ex.: "E-mail, CPF ou senha não conferem."
      if (mounted) _avisar(erro.mensagem);
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  Future<void> _registrar() async {
    controller.registrar();
    // O cadastro devolve o e-mail da conta criada, para já vir preenchido.
    final email = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => RegisterView()));
    if (mounted && email != null) _usuario.text = email;
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          autovalidateMode: _validarAoDigitar
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          // Ocupa a tela toda para os botões ficarem embaixo, mas rola
          // quando não cabe (fonte grande ou teclado aberto).
          child: LayoutBuilder(
            builder: (context, tela) => SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 480,
                    minHeight: tela.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _Marca(),
                            const SizedBox(height: 40),
                            Text('Entrar', style: textTheme.headlineMedium),
                            const SizedBox(height: 8),
                            Text(
                              'Use seu e-mail ou CPF e a senha que você '
                              'recebeu da portaria.',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 28),
                            CampoTexto(
                              rotulo: 'E-mail ou CPF',
                              controller: _usuario,
                              icone: Icons.person_outline,
                              dica: 'seu@email.com',
                              teclado: TextInputType.emailAddress,
                              autofill: const [
                                AutofillHints.email,
                                AutofillHints.username,
                              ],
                              validator: controller.validarUsuario,
                            ),
                            const SizedBox(height: 20),
                            CampoTexto(
                              rotulo: 'Senha',
                              controller: _senha,
                              icone: Icons.lock_outline,
                              dica: '••••••••',
                              senha: true,
                              acao: TextInputAction.done,
                              autofill: const [AutofillHints.password],
                              validator: controller.validarSenha,
                              onEnviar: _entrar,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 32),
                            BotaoAcao(
                              rotulo: _entrando ? 'Entrando…' : 'Entrar',
                              icone: Icons.login,
                              carregando: _entrando,
                              onTocar: _entrar,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                controller.entrarComNfc();
                                _avisar('Entrar com NFC: em construção.');
                              },
                              icon: const Icon(Icons.contactless_outlined),
                              label: const Text('Entrar com NFC'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                controller.esqueciSenha();
                                _avisar('Peça uma nova senha na portaria.');
                              },
                              child: const Text('Esqueci minha senha'),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Primeiro acesso?',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _registrar,
                                  child: const Text('Registrar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo e nome do app no topo do login.
class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Passe', style: textTheme.headlineSmall),
              Text(
                'Seu acesso ao prédio pelo celular',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
