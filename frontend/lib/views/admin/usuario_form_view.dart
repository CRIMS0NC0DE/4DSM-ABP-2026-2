import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatos.dart';
import '../../models/admin_models.dart';
import '../../models/usuario.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_texto.dart';

/// Cadastro e edição de usuário (A4 · RF01), com as tags NFC dele.
/// A API não apaga usuário: para tirar o acesso de alguém, desative o
/// cadastro (e cancele as autorizações).
/// Fecha devolvendo true quando algo mudou, para a lista recarregar.
class UsuarioFormView extends StatefulWidget {
  const UsuarioFormView({
    super.key,
    this.usuario,
    this.perfilInicial,
    AdminService? servico,
  }) : _servico = servico;

  /// Null cria um usuário novo.
  final UsuarioAdmin? usuario;
  final Perfil? perfilInicial;
  final AdminService? _servico;

  @override
  State<UsuarioFormView> createState() => _UsuarioFormViewState();
}

class _UsuarioFormViewState extends State<UsuarioFormView> {
  late final AdminService _servico = widget._servico ?? AdminService.instancia;
  final _form = GlobalKey<FormState>();

  late final _nome = TextEditingController(text: widget.usuario?.nome);
  late final _email = TextEditingController(text: widget.usuario?.email);
  late final _cpf = TextEditingController(
    text: widget.usuario == null ? '' : Formatos.cpf(widget.usuario!.cpf),
  );
  final _senha = TextEditingController();
  final _novaTag = TextEditingController();

  late Perfil _perfil =
      widget.usuario?.perfil ?? widget.perfilInicial ?? Perfil.morador;
  late bool _ativo = widget.usuario?.ativo ?? true;
  late List<TagNfc> _tags = [...?widget.usuario?.tags];

  var _salvando = false;
  var _mudou = false;

  bool get _novo => widget.usuario == null;

  /// A portaria só cadastra condôminos e visitantes.
  List<Perfil> get _perfisPermitidos => [
    for (final p in Perfil.values)
      if (_servico.podeGerenciar(p)) p,
  ];

  @override
  void dispose() {
    for (final c in [_nome, _email, _cpf, _senha, _novaTag]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final cpf = Formatos.somenteNumeros(_cpf.text);
      if (_novo) {
        await _servico.criarUsuario(
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          cpf: cpf,
          senha: _senha.text,
          perfil: _perfil,
        );
      } else {
        await _servico.atualizarUsuario(
          widget.usuario!.id,
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          cpf: cpf,
          senha: _senha.text,
          perfil: _perfil,
          ativo: _ativo,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      avisar(context, erro.mensagem, erro: true);
    }
  }

  /// Executa uma ação nas tags e mostra o erro da API, se houver.
  Future<void> _naTag(Future<void> Function() acao) async {
    try {
      await acao();
      _mudou = true;
    } on ApiException catch (erro) {
      if (mounted) avisar(context, erro.mensagem, erro: true);
    }
  }

  Future<void> _vincular() async {
    final uid = _novaTag.text.trim();
    if (!RegExp(r'^[0-9a-fA-F:\s-]{4,40}$').hasMatch(uid)) {
      avisar(context, 'UID da tag inválido. Use letras de A a F e números.', erro: true);
      return;
    }
    await _naTag(() async {
      final tag = await _servico.vincularTag(widget.usuario!.id, uid);
      if (!mounted) return;
      setState(() {
        _tags = [..._tags, tag];
        _novaTag.clear();
      });
    });
  }

  Future<void> _alternar(TagNfc tag, bool ativa) => _naTag(() async {
    final nova = await _servico.alterarTag(widget.usuario!.id, tag.id, ativa);
    if (!mounted) return;
    setState(() => _tags = [for (final t in _tags) t.id == tag.id ? nova : t]);
  });

  Future<void> _remover(TagNfc tag) async {
    final sim = await confirmar(
      context,
      titulo: 'Remover a tag ${Formatos.finalDaTag(tag.uid)}?',
      texto: 'Ela deixa de abrir a catraca para ${widget.usuario!.nome}.',
      rotuloSim: 'Sim, remover',
      rotuloNao: 'Não, manter',
    );
    if (!sim || !mounted) return;
    await _naTag(() async {
      await _servico.removerTag(widget.usuario!.id, tag.id);
      if (!mounted) return;
      setState(() => _tags = [for (final t in _tags) if (t.id != tag.id) t]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_mudou);
      },
      child: TelaAdmin(
        titulo: _novo ? 'Novo usuário' : 'Editar usuário',
        corpo: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              CampoTexto(
                rotulo: 'Nome completo',
                controller: _nome,
                icone: Icons.person_outline,
                teclado: TextInputType.name,
                validator: (v) => (v ?? '').trim().length < 3
                    ? 'Informe o nome completo'
                    : null,
              ),
              const SizedBox(height: 16),
              CampoTexto(
                rotulo: 'E-mail',
                controller: _email,
                icone: Icons.mail_outline,
                teclado: TextInputType.emailAddress,
                validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
                    ? null
                    : 'E-mail inválido',
              ),
              const SizedBox(height: 16),
              CampoTexto(
                rotulo: 'Documento (CPF)',
                controller: _cpf,
                icone: Icons.badge_outlined,
                teclado: TextInputType.number,
                ajuda: 'Pode digitar só os números.',
                validator: (v) => Formatos.somenteNumeros(v ?? '').length == 11
                    ? null
                    : 'O CPF precisa ter 11 números',
              ),
              const SizedBox(height: 16),
              CampoTexto(
                rotulo: _novo ? 'Senha' : 'Nova senha',
                controller: _senha,
                icone: Icons.lock_outline,
                senha: true,
                acao: TextInputAction.done,
                ajuda: _novo
                    ? 'A pessoa usa esta senha no primeiro acesso.'
                    : 'Deixe em branco para manter a senha atual.',
                validator: (v) {
                  final texto = v ?? '';
                  if (texto.isEmpty && !_novo) return null;
                  return texto.length < 6
                      ? 'A senha precisa de pelo menos 6 caracteres'
                      : null;
                },
              ),
              const SizedBox(height: 24),
              Text('Perfil', style: textTheme.labelLarge),
              RadioGroup<Perfil>(
                groupValue: _perfil,
                onChanged: (p) => setState(() => _perfil = p ?? _perfil),
                child: Column(
                  children: [
                    for (final p in _perfisPermitidos)
                      RadioListTile<Perfil>(
                        value: p,
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.rotulo),
                        subtitle: Text(p.descricao),
                      ),
                  ],
                ),
              ),
              if (!_novo) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cadastro ativo'),
                  subtitle: Text(
                    _ativo
                        ? 'Pode entrar de acordo com as autorizações.'
                        : 'Desativado: não passa em nenhuma catraca.',
                  ),
                  value: _ativo,
                  onChanged: (v) => setState(() => _ativo = v),
                ),
                const SizedBox(height: 16),
                _SecaoTags(
                  tags: _tags,
                  controller: _novaTag,
                  onVincular: _vincular,
                  onAlternar: _alternar,
                  onRemover: _remover,
                ),
              ],
              const SizedBox(height: 24),
              BotaoAcao(
                rotulo: _novo ? 'Cadastrar usuário' : 'Salvar alterações',
                icone: Icons.check,
                carregando: _salvando,
                onTocar: _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecaoTags extends StatelessWidget {
  const _SecaoTags({
    required this.tags,
    required this.controller,
    required this.onVincular,
    required this.onAlternar,
    required this.onRemover,
  });

  final List<TagNfc> tags;
  final TextEditingController controller;
  final VoidCallback onVincular;
  final void Function(TagNfc tag, bool ativa) onAlternar;
  final void Function(TagNfc tag) onRemover;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tags NFC', style: textTheme.labelLarge),
        const SizedBox(height: 8),
        if (tags.isEmpty)
          Text('Nenhuma tag vinculada.', style: textTheme.bodyMedium)
        else
          for (final tag in tags)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.contactless_outlined),
                title: Text('Tag ${tag.uid}'),
                subtitle: Text(tag.ativa ? 'Ativa' : 'Bloqueada'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: tag.ativa,
                      onChanged: (v) => onAlternar(tag, v),
                    ),
                    IconButton(
                      tooltip: 'Remover tag',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onRemover(tag),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F:\s-]')),
          ],
          decoration: InputDecoration(
            labelText: 'UID da nova tag',
            hintText: '04A1B2C3',
            prefixIcon: const Icon(Icons.contactless_outlined),
            suffixIcon: IconButton(
              tooltip: 'Vincular tag',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onVincular,
            ),
          ),
          onSubmitted: (_) => onVincular(),
        ),
      ],
    );
  }
}
