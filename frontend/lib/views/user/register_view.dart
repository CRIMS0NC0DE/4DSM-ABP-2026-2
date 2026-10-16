import 'package:flutter/material.dart';

import '../../controllers/register_controller.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/campo_texto.dart';

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

  /// Só valida enquanto digita depois da primeira tentativa de registrar.
  var _validarAoDigitar = false;

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

  void _registrar() {
    if (!_form.currentState!.validate()) {
      setState(() => _validarAoDigitar = true);
      return;
    }
    final email = _email.text.trim();
    final erro = controller.registrar(
      nome: _nome.text.trim(),
      cpf: _cpf.text.trim(),
      email: email,
      senha: _senha.text,
    );
    if (erro != null) {
      _avisar(erro);
      return;
    }
    _avisar('Conta criada. Agora é só entrar.');
    // Volta para o login com o e-mail já preenchido.
    Navigator.of(context).maybePop(email);
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
                      Text('Criar conta', style: textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Preencha seus dados para o primeiro acesso.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      CampoTexto(
                        rotulo: 'Nome completo',
                        controller: _nome,
                        icone: Icons.person_outline,
                        teclado: TextInputType.name,
                        autofill: const [AutofillHints.name],
                        validator: controller.validarNome,
                      ),
                      const SizedBox(height: 20),
                      CampoTexto(
                        rotulo: 'CPF',
                        controller: _cpf,
                        icone: Icons.badge_outlined,
                        dica: '000.000.000-00',
                        ajuda: 'Pode digitar só os números.',
                        teclado: TextInputType.number,
                        validator: controller.validarCpf,
                      ),
                      const SizedBox(height: 20),
                      CampoTexto(
                        rotulo: 'E-mail',
                        controller: _email,
                        icone: Icons.mail_outline,
                        dica: 'seu@email.com',
                        teclado: TextInputType.emailAddress,
                        autofill: const [AutofillHints.email],
                        validator: controller.validarEmail,
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
                        validator: controller.validarSenha,
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
                      FilledButton.icon(
                        onPressed: _registrar,
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Registrar'),
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
