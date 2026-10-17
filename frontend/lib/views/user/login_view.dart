import 'package:flutter/material.dart';

import '../../controllers/login_controller.dart';
import '../../core/routes/rotas.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_client.dart';
import '../widgets/campo_texto.dart';
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
    try {
      final usuario = await controller.entrar(
        _usuario.text.trim(),
        _senha.text,
      );
      if (!mounted) return;
      // Troca o login pelo menu do perfil, para o Voltar do celular não
      // voltar ao login.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => menuDoPerfil(usuario.perfil)),
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

    return Scaffold(
      backgroundColor: AppColors.surface,
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
                                color: AppColors.textSecondary,
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
                            FilledButton.icon(
                              onPressed: _entrando ? null : _entrar,
                              icon: _entrando
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login),
                              label: Text(_entrando ? 'Entrando…' : 'Entrar'),
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
                                    color: AppColors.textSecondary,
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
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.door_front_door,
            color: AppColors.onPrimary,
            size: 32,
          ),
        ),
        const SizedBox(width: 12),
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
