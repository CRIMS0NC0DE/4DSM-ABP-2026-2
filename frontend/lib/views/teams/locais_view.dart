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

/// A5 · Locais: a árvore do prédio. Para o admin, o "+" de cada nível cria o
/// nível de baixo e o menu "⋮" edita ou apaga. A portaria só consulta.
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

  /// Faz a ação e recarrega a árvore, mesmo quando a API recusa (alguém pode
  /// ter mudado os locais enquanto isso). 401 volta ao login. Ao apagar, o 409
  /// abre um aviso com a mensagem da API, que diz o que tirar antes.
  Future<void> _executar(
    Future<void> Function() acao, {
    String? feito,
    bool apagando = false,
  }) async {
    try {
      await acao();
      if (!mounted) return;
      if (feito != null) avisar(context, feito);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.naoAutenticado) {
        await voltarAoLogin(context, e);
        return;
      }
      if (apagando && e.status == 409) {
        await _explicarRecusa(e.mensagem);
      } else {
        avisar(context, e.mensagem);
      }
    }
    if (mounted) await carregar();
  }

  /// Pede o nome (e o endereço, no edifício) e salva. Com [nome] e
  /// [endereco] preenchidos, é a edição.
  Future<void> _pedirNome({
    required String titulo,
    required Future<void> Function(String nome, String endereco) salvar,
    bool comEndereco = false,
    String nome = '',
    String endereco = '',
  }) async {
    final valores = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _DialogoNome(
        titulo: titulo,
        comEndereco: comEndereco,
        nome: nome,
        endereco: endereco,
      ),
    );
    if (valores == null || !mounted) return;
    await _executar(() => salvar(valores.$1, valores.$2));
  }

  /// Confirma antes de apagar. [tipo] vai no título: "Apagar porta?".
  Future<void> _apagar({
    required String tipo,
    required String nome,
    required String feito,
    required Future<void> Function() apagar,
  }) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text('Apagar $tipo?'),
        content: Text(
          '$nome sai da lista de locais. O histórico de acessos continua '
          'guardado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Não apagar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(contexto).colorScheme.error,
            ),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    await _executar(apagar, feito: feito, apagando: true);
  }

  Future<void> _explicarRecusa(String mensagem) => showDialog<void>(
    context: context,
    builder: (contexto) => AlertDialog(
      icon: const Icon(Icons.info_outline),
      title: const Text('Ainda não dá para apagar'),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contexto).pop(),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );

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
    final admin = controller.podeGerenciar;
    if (edificios.isEmpty) {
      return [
        EstadoVazio(
          icone: Icons.apartment,
          titulo: 'Nenhum local cadastrado',
          texto: admin
              ? 'Comece pelo edifício.'
              : 'O administrador cadastra os edifícios e as catracas.',
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
                  onAdicionar: admin
                      ? () => _pedirNome(
                          titulo: 'Nova portaria',
                          salvar: (nome, _) =>
                              controller.criarPortaria(nome, edificio.id),
                        )
                      : null,
                  onEditar: admin
                      ? () => _pedirNome(
                          titulo: 'Editar edifício',
                          comEndereco: true,
                          nome: edificio.nome,
                          endereco: edificio.endereco,
                          salvar: (nome, endereco) => controller.editarEdificio(
                            edificio.id,
                            nome: nome,
                            endereco: endereco,
                          ),
                        )
                      : null,
                  onApagar: admin
                      ? () => _apagar(
                          tipo: 'edifício',
                          nome: edificio.nome,
                          feito: 'Edifício apagado.',
                          apagar: () => controller.apagarEdificio(edificio.id),
                        )
                      : null,
                ),
                for (final portaria in edificio.portarias) ...[
                  _Nivel(
                    recuo: 1,
                    icone: Icons.meeting_room_outlined,
                    rotulo: 'Portaria',
                    nome: portaria.nome,
                    rotuloAdicionar: 'Nova porta',
                    onAdicionar: admin
                        ? () => _pedirNome(
                            titulo: 'Nova porta',
                            salvar: (nome, _) =>
                                controller.criarPorta(nome, portaria.id),
                          )
                        : null,
                    onEditar: admin
                        ? () => _pedirNome(
                            titulo: 'Editar portaria',
                            nome: portaria.nome,
                            salvar: (nome, _) =>
                                controller.editarPortaria(portaria.id, nome),
                          )
                        : null,
                    onApagar: admin
                        ? () => _apagar(
                            tipo: 'portaria',
                            nome: portaria.nome,
                            feito: 'Portaria apagada.',
                            apagar: () =>
                                controller.apagarPortaria(portaria.id),
                          )
                        : null,
                  ),
                  for (final porta in portaria.portas) ...[
                    _Nivel(
                      recuo: 2,
                      icone: Icons.door_front_door_outlined,
                      rotulo: 'Porta',
                      nome: porta.nome,
                      rotuloAdicionar: 'Nova catraca',
                      onAdicionar: admin
                          ? () => _abrirCatraca(
                              portaId: porta.id,
                              caminho: '${portaria.nome} › ${porta.nome}',
                            )
                          : null,
                      onEditar: admin
                          ? () => _pedirNome(
                              titulo: 'Editar porta',
                              nome: porta.nome,
                              salvar: (nome, _) =>
                                  controller.editarPorta(porta.id, nome),
                            )
                          : null,
                      onApagar: admin
                          ? () => _apagar(
                              tipo: 'porta',
                              nome: porta.nome,
                              feito: 'Porta apagada.',
                              apagar: () => controller.apagarPorta(porta.id),
                            )
                          : null,
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
                        onTocar: admin
                            ? () => _abrirCatraca(
                                portaId: porta.id,
                                caminho: '${portaria.nome} › ${porta.nome}',
                                catraca: catraca,
                              )
                            : null,
                        onEditar: admin
                            ? () => _abrirCatraca(
                                portaId: porta.id,
                                caminho: '${portaria.nome} › ${porta.nome}',
                                catraca: catraca,
                              )
                            : null,
                        onApagar: admin
                            ? () => _apagar(
                                tipo: 'catraca',
                                nome: catraca.nome,
                                feito: 'Catraca apagada.',
                                apagar: () =>
                                    controller.apagarCatraca(catraca.id),
                              )
                            : null,
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
      botaoFlutuante: controller.podeGerenciar
          ? FloatingActionButton.extended(
              onPressed: () => _pedirNome(
                titulo: 'Novo edifício',
                comEndereco: true,
                salvar: controller.criarEdificio,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Novo edifício'),
            )
          : null,
      filhos: conteudo(_arvore),
    );
  }
}

enum _Acao { editar, apagar }

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
    this.onEditar,
    this.onApagar,
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
  final VoidCallback? onEditar;
  final VoidCallback? onApagar;

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
            if (onEditar != null || onApagar != null)
              PopupMenuButton<_Acao>(
                tooltip: 'Opções de $nome',
                icon: const Icon(Icons.more_vert),
                onSelected: (acao) {
                  switch (acao) {
                    case _Acao.editar:
                      onEditar?.call();
                    case _Acao.apagar:
                      onApagar?.call();
                  }
                },
                itemBuilder: (_) => [
                  if (onEditar != null)
                    const PopupMenuItem(
                      value: _Acao.editar,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
                      ),
                    ),
                  if (onApagar != null)
                    PopupMenuItem(
                      value: _Acao.apagar,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                        ),
                        title: Text(
                          'Apagar',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ),
                ],
              ),
            if (onTocar != null)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(Icons.chevron_right),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogoNome extends StatefulWidget {
  const _DialogoNome({
    required this.titulo,
    required this.comEndereco,
    this.nome = '',
    this.endereco = '',
  });

  final String titulo;
  final bool comEndereco;

  /// Valores atuais, na edição.
  final String nome;
  final String endereco;

  @override
  State<_DialogoNome> createState() => _DialogoNomeState();
}

class _DialogoNomeState extends State<_DialogoNome> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.nome);
  late final _endereco = TextEditingController(text: widget.endereco);

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
              Navigator.of(context)
                  .pop((_nome.text.trim(), _endereco.text.trim()));
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
