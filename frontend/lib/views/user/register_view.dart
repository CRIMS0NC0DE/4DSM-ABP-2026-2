import 'package:flutter/material.dart';

import '../../controllers/register_controller.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_texto.dart';

/// Pedido de cadastro pelo app (POST /auth/register). O cadastro nasce
/// desativado: depois de enviar, explica que a portaria vai liberar o acesso
/// e volta ao login com o e-mail preenchido.
class RegisterView extends StatefulWidget {
  final RegisterController controller;

  RegisterView({super.key, RegisterController? controller})
    : controller = controller ?? RegisterController();

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _cpf = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();

  /// Só valida enquanto digita depois da primeira tentativa de enviar.
  var _validarAoDigitar = false;

  /// Esperando a API; trava o botão para não enviar duas vezes.
  var _enviando = false;

  /// Erros de cada campo que a API devolveu no 400.
  Map<String, List<String>> _errosDaApi = const {};

  RegisterController get controller => widget.controller;

  @override
  void dispose() {
    _nome.dispose();
    _cpf.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  String? _erroDaApi(String campo) => _errosDaApi[campo]?.first;

  Future<void> _registrar() async {
    if (_enviando) return;
    _errosDaApi = const {};
    if (!_form.currentState!.validate()) {
      setState(() => _validarAoDigitar = true);
      return;
    }
    setState(() => _enviando = true);
    final email = _email.text.trim();
    final String mensagem;
    try {
      mensagem = await controller.registrar(
        nome: _nome.text.trim(),
        cpf: _cpf.text.trim(),
        email: email,
        senha: _senha.text,
      );
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() => _enviando = false);
      if (erro.campos.isNotEmpty) {
        _errosDaApi = erro.campos;
        _form.currentState!.validate();
        setState(() => _validarAoDigitar = true);
      }
      // Ex.: "Já existe alguém com este e-mail." ou sem conexão.
      _avisar(erro.mensagem);
      return;
    }
    if (!mounted) return;
    setState(() => _enviando = false);
    await _confirmarEnvio(mensagem, email);
    // Volta para o login com o e-mail já preenchido.
    if (mounted) Navigator.of(context).maybePop(email);
  }

  /// O pedido foi aceito, mas a conta só entra depois da portaria liberar.
  Future<void> _confirmarEnvio(String mensagem, String email) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (contexto) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_outlined, size: 36),
        title: const Text('Pedido enviado'),
        content: SingleChildScrollView(
          child: Text(
            '$mensagem\n\nQuando a portaria liberar, entre com $email e a '
            'senha que você acabou de criar.',
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.of(contexto).pop(),
            icon: const Icon(Icons.login),
            label: const Text('Voltar ao login'),
          ),
        ],
      ),
    );
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
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (Navigator.of(context).canPop())
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Voltar'),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Solicitar cadastro',
                        style: textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preencha seus dados. A portaria confere e libera '
                        'seu acesso.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      CampoTexto(
                        rotulo: 'Nome completo',
                        controller: _nome,
                        icone: Icons.person_outline,
                        teclado: TextInputType.name,
                        autofill: const [AutofillHints.name],
                        validator: (v) =>
                            controller.validarNome(v) ?? _erroDaApi('nome'),
                      ),
                      const SizedBox(height: 20),
                      CampoTexto(
                        rotulo: 'CPF',
                        controller: _cpf,
                        icone: Icons.badge_outlined,
                        dica: '000.000.000-00',
                        ajuda: 'Pode digitar só os números.',
                        teclado: TextInputType.number,
                        validator: (v) =>
                            controller.validarCpf(v) ?? _erroDaApi('cpf'),
                      ),
                      const SizedBox(height: 20),
                      CampoTexto(
                        rotulo: 'E-mail',
                        controller: _email,
                        icone: Icons.mail_outline,
                        dica: 'seu@email.com',
                        teclado: TextInputType.emailAddress,
                        autofill: const [AutofillHints.email],
                        validator: (v) =>
                            controller.validarEmail(v) ?? _erroDaApi('email'),
                      ),
                      const SizedBox(height: 20),
                      CampoTexto(
                        rotulo: 'Senha',
                        controller: _senha,
                        icone: Icons.lock_outline,
                        senha: true,
                        ajuda:
                            'Pelo menos '
                            '${RegisterController.tamanhoMinimoSenha} '
                            'caracteres.',
                        autofill: const [AutofillHints.newPassword],
                        validator: (v) =>
                            controller.validarSenha(v) ?? _erroDaApi('senha'),
                      ),
                      const SizedBox(height: 20),
                      CampoTexto(
                        rotulo: 'Confirmar senha',
                        controller: _confirmacao,
                        icone: Icons.lock_outline,
                        senha: true,
                        acao: TextInputAction.done,
                        validator: (valor) =>
                            controller.validarConfirmacao(valor, _senha.text),
                        onEnviar: _registrar,
                      ),
                      const SizedBox(height: 32),
                      BotaoAcao(
                        rotulo: _enviando ? 'Enviando…' : 'Enviar pedido',
                        icone: Icons.person_add_alt_1_outlined,
                        carregando: _enviando,
                        onTocar: _registrar,
                      ),
                    ],
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
