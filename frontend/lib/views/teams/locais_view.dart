import 'package:flutter/material.dart';

import '../../controllers/locais_controller.dart';
import '../../models/local.dart';
import '../../models/opcao_menu.dart';
import '../../services/api_client.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/selo.dart';
import '../widgets/tela_base.dart';
import 'catraca_form_view.dart';

/// A5 · Locais: a árvore do prédio. O "+" de cada nível cria o nível de baixo.
class LocaisView extends StatefulWidget {
  LocaisView({super.key, LocaisController? controller})
    : controller = controller ?? LocaisController();

  final LocaisController controller;

  @override
  State<LocaisView> createState() => _LocaisViewState();
}

class _LocaisViewState extends State<LocaisView>
    with CarregaDados<List<Edificio>, LocaisView> {
  LocaisController get controller => widget.controller;

  @override
  Future<List<Edificio>> buscar() => controller.arvore();

  /// Pede o nome (e o endereço, no edifício), salva e recarrega a árvore.
  Future<void> _novo({
    required String titulo,
    required Future<void> Function(String nome, String endereco) salvar,
    bool comEndereco = false,
  }) async {
    final valores = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _DialogoNome(titulo: titulo, comEndereco: comEndereco),
    );
    if (valores == null) return;
    try {
      await salvar(valores.$1, valores.$2);
      if (mounted) await carregar();
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    }
  }

  Future<void> _abrirCatraca({
    required String portaId,
    required String caminho,
    Catraca? catraca,
  }) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CatracaFormView(
          catraca: catraca,
          portaId: portaId,
          caminho: caminho,
          controller: controller,
        ),
      ),
    );
    if (salvou == true && mounted) await carregar();
  }

  List<Widget> _arvore(List<Edificio> edificios) {
    if (edificios.isEmpty) {
      return const [
        EstadoVazio(
          icone: Icons.apartment,
          titulo: 'Nenhum local cadastrado',
          texto: 'Comece pelo edifício.',
        ),
      ];
    }
    return [
      for (final edificio in edificios) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Nivel(
                  recuo: 0,
                  icone: Icons.apartment,
                  rotulo: 'Edifício',
                  nome: edificio.nome,
                  detalhe: edificio.endereco,
                  rotuloAdicionar: 'Nova portaria',
                  onAdicionar: () => _novo(
                    titulo: 'Nova portaria',
                    salvar: (nome, _) =>
                        controller.criarPortaria(nome, edificio.id),
                  ),
                ),
                for (final portaria in edificio.portarias) ...[
                  _Nivel(
                    recuo: 1,
                    icone: Icons.meeting_room_outlined,
                    rotulo: 'Portaria',
                    nome: portaria.nome,
                    rotuloAdicionar: 'Nova porta',
                    onAdicionar: () => _novo(
                      titulo: 'Nova porta',
                      salvar: (nome, _) =>
                          controller.criarPorta(nome, portaria.id),
                    ),
                  ),
                  for (final porta in portaria.portas) ...[
                    _Nivel(
                      recuo: 2,
                      icone: Icons.door_front_door_outlined,
                      rotulo: 'Porta',
                      nome: porta.nome,
                      rotuloAdicionar: 'Nova catraca',
                      onAdicionar: () => _abrirCatraca(
                        portaId: porta.id,
                        caminho: '${portaria.nome} › ${porta.nome}',
                      ),
                    ),
                    for (final catraca in porta.catracas)
                      _Nivel(
                        recuo: 3,
                        icone: Icons.qr_code_2,
                        rotulo: 'Catraca',
                        nome: catraca.nome,
                        selo: Selo(
                          texto: 'Raio de ${catraca.raioMetros} m',
                          icone: Icons.location_on_outlined,
                          tom: TomOpcao.sucesso,
                        ),
                        onTocar: () => _abrirCatraca(
                          portaId: porta.id,
                          caminho: '${portaria.nome} › ${porta.nome}',
                          catraca: catraca,
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Locais',
      subtitulo: 'Edifício › Portaria › Porta › Catraca',
      onAtualizar: carregar,
      botaoFlutuante: FloatingActionButton.extended(
        onPressed: () => _novo(
          titulo: 'Novo edifício',
          comEndereco: true,
          salvar: controller.criarEdificio,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo edifício'),
      ),
      filhos: conteudo(_arvore),
    );
  }
}

class _Nivel extends StatelessWidget {
  const _Nivel({
    required this.recuo,
    required this.icone,
    required this.rotulo,
    required this.nome,
    this.detalhe,
    this.selo,
    this.rotuloAdicionar,
    this.onAdicionar,
    this.onTocar,
  });

  final int recuo;
  final IconData icone;
  final String rotulo;
  final String nome;
  final String? detalhe;
  final Widget? selo;
  final String? rotuloAdicionar;
  final VoidCallback? onAdicionar;
  final VoidCallback? onTocar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTocar,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.0 + 12 * recuo, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rotulo, style: textTheme.bodySmall),
                  Text(nome, style: textTheme.titleMedium),
                  if (detalhe != null)
                    Text(detalhe!, style: textTheme.bodySmall),
                  if (selo != null) ...[const SizedBox(height: 4), selo!],
                ],
              ),
            ),
            if (onAdicionar != null)
              IconButton(
                onPressed: onAdicionar,
                tooltip: rotuloAdicionar,
                icon: const Icon(Icons.add_circle_outline),
              ),
            if (onTocar != null) const Icon(Icons.chevron_right),
          ],
        ),
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

  String? _obrigatorio(String? valor) =>
      (valor ?? '').trim().isEmpty ? 'Campo obrigatório.' : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoTexto(
                rotulo: 'Nome',
                controller: _nome,
                icone: Icons.edit_outlined,
                validator: _obrigatorio,
              ),
              if (widget.comEndereco) ...[
                const SizedBox(height: 16),
                CampoTexto(
                  rotulo: 'Endereço',
                  controller: _endereco,
                  icone: Icons.place_outlined,
                  validator: _obrigatorio,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
        TextButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.of(
                context,
              ).pop((_nome.text.trim(), _endereco.text.trim()));
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
