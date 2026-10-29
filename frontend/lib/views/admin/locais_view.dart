import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../widgets/admin_widgets.dart';
import 'catraca_form_view.dart';

/// Locais (A5 · RF02): a árvore Edifício › Portaria › Porta › Catraca.
/// Todos da equipe veem; só o admin cadastra e edita (a API devolve 403 para
/// a portaria, por isso os botões de criar só aparecem para o admin).
class LocaisView extends StatefulWidget {
  const LocaisView({super.key, this._servico});

  final AdminService? _servico;

  @override
  State<LocaisView> createState() => _LocaisViewState();
}

class _LocaisViewState extends State<LocaisView> {
  late final AdminService _servico = widget._servico ?? AdminService.instancia;
  var _versao = 0;

  void _recarregar() => setState(() => _versao++);

  /// Pede um nome (e o endereço, para edifício) e cria na API.
  Future<void> _criarSimples({
    required String titulo,
    required Future<void> Function(String nome, String endereco) criar,
    bool comEndereco = false,
  }) async {
    final dados = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _DialogoNome(titulo: titulo, comEndereco: comEndereco),
    );
    if (dados == null) return;
    try {
      await criar(dados.$1, dados.$2);
      if (mounted) _recarregar();
    } on ApiException catch (erro) {
      if (mounted) avisar(context, erro.mensagem, erro: true);
    }
  }

  Future<void> _abrirCatraca({Catraca? catraca, String? doorId}) async {
    final mudou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CatracaFormView(
          catraca: catraca,
          doorId: doorId,
          servico: _servico,
        ),
      ),
    );
    if (mudou == true && mounted) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    final admin = _servico.souAdmin;
    return TelaAdmin(
      titulo: 'Locais',
      subtitulo: 'Edifício > Portaria > Porta > Catraca',
      botaoFlutuante: admin
          ? FloatingActionButton.extended(
              onPressed: () => _criarSimples(
                titulo: 'Novo edifício',
                comEndereco: true,
                criar: _servico.criarEdificio,
              ),
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Novo edifício'),
            )
          : null,
      corpo: CarregaDados<List<Edificio>>(
        key: ValueKey(_versao),
        carregar: _servico.locais,
        mensagem: 'Carregando locais…',
        construir: (context, edificios) {
          if (edificios.isEmpty) {
            return EstadoVazio(
              icone: Icons.apartment,
              titulo: 'Nenhum local cadastrado',
              texto: admin
                  ? 'Comece cadastrando o edifício.'
                  : 'Peça ao administrador para cadastrar os locais.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _recarregar(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                for (final e in edificios)
                  _CartaoEdificio(
                    edificio: e,
                    admin: admin,
                    onNovaPortaria: () => _criarSimples(
                      titulo: 'Nova portaria',
                      criar: (nome, _) => _servico.criarPortaria(nome, e.id),
                    ),
                    onNovaPorta: (portaria) => _criarSimples(
                      titulo: 'Nova porta',
                      criar: (nome, _) => _servico.criarPorta(nome, portaria.id),
                    ),
                    onCatraca: (catraca, porta) =>
                        _abrirCatraca(catraca: catraca, doorId: porta.id),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CartaoEdificio extends StatelessWidget {
  const _CartaoEdificio({
    required this.edificio,
    required this.admin,
    required this.onNovaPortaria,
    required this.onNovaPorta,
    required this.onCatraca,
  });

  final Edificio edificio;
  final bool admin;
  final VoidCallback onNovaPortaria;
  final ValueChanged<Portaria> onNovaPorta;

  /// Catraca nula cria uma nova na porta.
  final void Function(Catraca? catraca, Porta porta) onCatraca;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final n = edificio.portarias.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.apartment),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(edificio.nome, style: textTheme.titleMedium),
                      Text(edificio.endereco, style: textTheme.bodySmall),
                      Text(
                        '$n ${n == 1 ? 'portaria' : 'portarias'}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            for (final portaria in edificio.portarias)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 12),
                child: _BlocoPortaria(
                  portaria: portaria,
                  admin: admin,
                  onNovaPorta: () => onNovaPorta(portaria),
                  onCatraca: onCatraca,
                ),
              ),
            if (admin)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onNovaPortaria,
                  icon: const Icon(Icons.add),
                  label: const Text('Nova portaria'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BlocoPortaria extends StatelessWidget {
  const _BlocoPortaria({
    required this.portaria,
    required this.admin,
    required this.onNovaPorta,
    required this.onCatraca,
  });

  final Portaria portaria;
  final bool admin;
  final VoidCallback onNovaPorta;
  final void Function(Catraca? catraca, Porta porta) onCatraca;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colorScheme.outlineVariant, width: 2)),
      ),
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(portaria.nome, style: textTheme.titleMedium)),
            ],
          ),
          for (final porta in portaria.portas) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 8),
              child: Row(
                children: [
                  const Icon(Icons.door_front_door_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(porta.nome, style: textTheme.bodyLarge)),
                ],
              ),
            ),
            for (final c in porta.catracas)
              ListTile(
                contentPadding: const EdgeInsets.only(left: 24),
                leading: const Icon(Icons.qr_code_2),
                title: Text(c.nome),
                subtitle: Text('Raio de ${c.raioMetros} m · localização definida'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onCatraca(c, porta),
              ),
            if (admin)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: TextButton.icon(
                  onPressed: () => onCatraca(null, porta),
                  icon: const Icon(Icons.add),
                  label: const Text('Nova catraca'),
                ),
              ),
          ],
          if (admin)
            TextButton.icon(
              onPressed: onNovaPorta,
              icon: const Icon(Icons.add),
              label: const Text('Nova porta'),
            ),
        ],
      ),
    );
  }
}

class _DialogoNome extends StatefulWidget {
  const _DialogoNome({required this.titulo, required this.comEndereco});

  final String titulo;
  final bool comEndereco;

  @override
  State<_DialogoNome> createState() => _DialogoNomeState();
}

class _DialogoNomeState extends State<_DialogoNome> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _endereco = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    _endereco.dispose();
    super.dispose();
  }

  String? _obrigatorio(String? v) =>
      (v ?? '').trim().isEmpty ? 'Preencha este campo' : null;

  void _confirmar() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop((_nome.text.trim(), _endereco.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nome,
              autofocus: true,
              textInputAction: widget.comEndereco
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: _obrigatorio,
              onFieldSubmitted: (_) => widget.comEndereco ? null : _confirmar(),
            ),
            if (widget.comEndereco) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _endereco,
                decoration: const InputDecoration(labelText: 'Endereço'),
                validator: _obrigatorio,
                onFieldSubmitted: (_) => _confirmar(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirmar, child: const Text('Salvar')),
      ],
    );
  }
}
