import 'package:flutter/material.dart';

import '../../controllers/usuarios_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/usuario.dart';
import '../../models/usuario_cadastro.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/tela_base.dart';

/// A4 · Usuário · formulário: cria ou edita. Ao salvar, devolve o usuário
/// para quem abriu a tela (Visitantes usa isso para seguir à autorização).
class UsuarioFormView extends StatefulWidget {
  UsuarioFormView({
    super.key,
    this.usuario,
    this.perfilFixo,
    this.rotuloSalvar,
    UsuariosController? controller,
  }) : controller = controller ?? UsuariosController();

  /// null cria um novo.
  final UsuarioCadastro? usuario;

  /// Esconde a escolha de perfil, ex.: cadastro de visitante.
  final Perfil? perfilFixo;
  final String? rotuloSalvar;
  final UsuariosController controller;

  @override
  State<UsuarioFormView> createState() => _UsuarioFormViewState();
}

class _UsuarioFormViewState extends State<UsuarioFormView> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.usuario?.nome);
  late final _cpf = TextEditingController(
    text: widget.usuario == null ? null : Formato.cpf(widget.usuario!.cpf),
  );
  late final _email = TextEditingController(text: widget.usuario?.email);
  final _senha = TextEditingController();
  late var _perfil =
      widget.perfilFixo ?? widget.usuario?.perfil ?? Perfil.morador;
  late var _ativo = widget.usuario?.ativo ?? true;
  var _salvando = false;

  /// Erros de cada campo que a API devolveu no 400.
  Map<String, List<String>> _errosDaApi = const {};

  bool get _novo => widget.usuario == null;

  @override
  void dispose() {
    _nome.dispose();
    _cpf.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  String? _erroDaApi(String campo) => _errosDaApi[campo]?.first;

  Future<void> _salvar() async {
    _errosDaApi = const {};
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final senha = _senha.text;
      final salvo = _novo
          ? await widget.controller.criar(
              nome: _nome.text.trim(),
              email: _email.text.trim(),
              cpf: _cpf.text.trim(),
              senha: senha,
              perfil: _perfil,
            )
          : await widget.controller.atualizar(
              widget.usuario!.id,
              nome: _nome.text.trim(),
              email: _email.text.trim(),
              cpf: _cpf.text.trim(),
              senha: senha.isEmpty ? null : senha,
              perfil: _perfil,
              ativo: _ativo,
            );
      if (mounted) Navigator.of(context).pop(salvo);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.campos.isNotEmpty) {
        _errosDaApi = e.campos;
        _form.currentState!.validate();
      } else {
        await tratarErro(context, e);
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Quem está logado não desativa nem muda o perfil da própria conta: valem
    // na hora e a pessoa não conseguiria desfazer.
    final eleMesmo = !_novo && widget.usuario?.id == widget.controller.idLogado;

    return TelaBase(
      titulo: _novo
          ? (widget.perfilFixo == Perfil.visitante
                ? 'Novo visitante'
                : 'Novo usuário')
          : 'Editar usuário',
      subtitulo: widget.perfilFixo == Perfil.visitante
          ? 'Passo 1 de 2: dados da pessoa'
          : null,
      rodape: BotaoAcao(
        rotulo: widget.rotuloSalvar ??
            (_novo ? 'Criar usuário' : 'Salvar alterações'),
        icone: Icons.check,
        carregando: _salvando,
        onTocar: _salvar,
      ),
      filhos: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoTexto(
                rotulo: 'Nome completo',
                controller: _nome,
                icone: Icons.person_outline,
                validator: (v) => (v ?? '').trim().length < 3
                    ? 'Informe o nome completo.'
                    : _erroDaApi('nome'),
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'Documento (CPF)',
                controller: _cpf,
                icone: Icons.badge_outlined,
                dica: '123.456.789-00',
                ajuda: 'Pode digitar só os números.',
                teclado: TextInputType.number,
                validator: (v) =>
                    (v ?? '').replaceAll(RegExp(r'\D'), '').length != 11
                    ? 'O CPF precisa ter 11 números.'
                    : _erroDaApi('cpf'),
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'E-mail',
                controller: _email,
                icone: Icons.mail_outline,
                teclado: TextInputType.emailAddress,
                validator: (v) => !(v ?? '').contains('@')
                    ? 'Informe um e-mail válido.'
                    : _erroDaApi('email'),
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: _novo ? 'Senha inicial' : 'Nova senha',
                controller: _senha,
                icone: Icons.lock_outline,
                senha: true,
                acao: TextInputAction.done,
                ajuda: _novo
                    ? 'A pessoa entra com esta senha.'
                    : 'Deixe em branco para manter a atual.',
                validator: (v) {
                  final senha = v ?? '';
                  if (_novo || senha.isNotEmpty) {
                    if (senha.length < 6) {
                      return 'A senha precisa de pelo menos 6 caracteres.';
                    }
                  }
                  return _erroDaApi('senha');
                },
              ),
              if (widget.perfilFixo == null && !eleMesmo) ...[
                const SizedBox(height: 20),
                Text('Perfil', style: textTheme.labelLarge),
                const SizedBox(height: 8),
                RadioGroup<Perfil>(
                  groupValue: _perfil,
                  onChanged: (perfil) {
                    if (perfil != null) setState(() => _perfil = perfil);
                  },
                  child: Column(
                    children: [
                      for (final perfil in widget.controller.perfisPermitidos)
                        RadioListTile<Perfil>(
                          value: perfil,
                          title: Text(Formato.perfil(perfil)),
                          subtitle: Text(switch (perfil) {
                            Perfil.admin =>
                              'Gerencia usuários, locais e autorizações',
                            Perfil.controladorAcesso =>
                              'Cuida da portaria no dia a dia',
                            Perfil.morador => 'Mora ou trabalha no prédio',
                            Perfil.visitante => 'Acesso por tempo limitado',
                          }),
                        ),
                    ],
                  ),
                ),
              ],
              if (!_novo && !eleMesmo) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _ativo,
                  onChanged: (v) => setState(() => _ativo = v),
                  title: const Text('Cadastro ativo'),
                  subtitle: const Text(
                    'Desativado, a pessoa não passa na catraca.',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
