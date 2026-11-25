import 'package:flutter/material.dart';

import '../../controllers/comunicados_controller.dart';
import '../../models/comunicado.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/tela_base.dart';

/// Comunicados do condomínio (sem tela no design). Com [podeGerenciar]
/// (admin), publica e apaga; morador, visitante e portaria só leem.
class ComunicadosView extends StatefulWidget {
  ComunicadosView({
    super.key,
    this.podeGerenciar = false,
    ComunicadosController? controller,
  }) : controller = controller ?? ComunicadosController();

  final bool podeGerenciar;
  final ComunicadosController controller;

  @override
  State<ComunicadosView> createState() => _ComunicadosViewState();
}

class _ComunicadosViewState extends State<ComunicadosView>
    with CarregaDados<List<Comunicado>, ComunicadosView> {
  ComunicadosController get controller => widget.controller;

  @override
  Future<List<Comunicado>> buscar() => controller.listar();

  Future<void> _novo() async {
    final publicado = await Navigator.of(context).push<Comunicado>(
      MaterialPageRoute(
        builder: (_) => _NovoComunicadoView(controller: controller),
      ),
    );
    if (publicado == null || !mounted) return;
    avisar(context, 'Comunicado publicado.');
    await carregar();
  }

  Future<void> _apagar(Comunicado comunicado) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Apagar este comunicado?'),
        content: Text(
          '"${comunicado.titulo}" some do app de todo mundo. '
          'Não dá para desfazer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Não, manter'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Sim, apagar'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      await controller.apagar(comunicado.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      // 404: alguém já apagou. Para quem está vendo, dá no mesmo.
      if (e.status != 404) {
        await tratarErro(context, e);
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      dados = [
        for (final c in dados ?? const <Comunicado>[])
          if (c.id != comunicado.id) c,
      ];
    });
    avisar(context, 'Comunicado apagado.');
  }

  List<Widget> _lista(List<Comunicado> lista) {
    if (lista.isEmpty) {
      return [
        EstadoVazio(
          icone: Icons.campaign_outlined,
          titulo: 'Nenhum comunicado',
          texto: widget.podeGerenciar
              ? 'Toque em "Novo comunicado" para avisar quem usa o prédio.'
              : 'Quando a administração publicar um aviso, ele aparece aqui.',
        ),
      ];
    }
    final agora = controller.agora();
    return [
      for (final comunicado in lista)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CartaoComunicado(
            comunicado: comunicado,
            quando: comunicado.quando(agora),
            onApagar: widget.podeGerenciar ? () => _apagar(comunicado) : null,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Comunicados',
      subtitulo: 'Avisos do condomínio',
      onAtualizar: carregar,
      botaoFlutuante: widget.podeGerenciar && dados != null
          ? FloatingActionButton.extended(
              onPressed: _novo,
              icon: const Icon(Icons.add),
              label: const Text('Novo comunicado'),
            )
          : null,
      filhos: conteudo(_lista),
    );
  }
}

class _CartaoComunicado extends StatelessWidget {
  const _CartaoComunicado({
    required this.comunicado,
    required this.quando,
    required this.onApagar,
  });

  final Comunicado comunicado;

  /// "Hoje às 09:12".
  final String quando;
  final VoidCallback? onApagar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comunicado.titulo, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(comunicado.mensagem, style: textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(
              '${comunicado.autor ?? 'Administração'} · $quando',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (onApagar != null)
              TextButton.icon(
                onPressed: onApagar,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Apagar'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Formulário do admin. Ao publicar, devolve o comunicado para a lista.
class _NovoComunicadoView extends StatefulWidget {
  const _NovoComunicadoView({required this.controller});

  final ComunicadosController controller;

  @override
  State<_NovoComunicadoView> createState() => _NovoComunicadoViewState();
}

class _NovoComunicadoViewState extends State<_NovoComunicadoView> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _mensagem = TextEditingController();
  var _publicando = false;

  /// Erros de cada campo que a API devolveu no 400.
  Map<String, List<String>> _errosDaApi = const {};

  @override
  void dispose() {
    _titulo.dispose();
    _mensagem.dispose();
    super.dispose();
  }

  String? _erroDaApi(String campo) => _errosDaApi[campo]?.first;

  /// Mesmas regras do POST /announcements: obrigatório e com limite de
  /// tamanho, contando sem os espaços das pontas.
  String? _validar(
    String? valor, {
    required String campo,
    required int maximo,
    required String vazio,
    required String longo,
  }) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return vazio;
    if (texto.length > maximo) return longo;
    return _erroDaApi(campo);
  }

  Future<void> _publicar() async {
    _errosDaApi = const {};
    if (!_form.currentState!.validate()) return;
    setState(() => _publicando = true);
    try {
      final publicado = await widget.controller.publicar(
        titulo: _titulo.text.trim(),
        mensagem: _mensagem.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(publicado);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.campos.isNotEmpty) {
        _errosDaApi = e.campos;
        _form.currentState!.validate();
      } else {
        await tratarErro(context, e);
      }
    } finally {
      if (mounted) setState(() => _publicando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Novo comunicado',
      subtitulo: 'Todos que usam o app vão ver este aviso',
      rodape: BotaoAcao(
        rotulo: 'Publicar comunicado',
        icone: Icons.send_outlined,
        carregando: _publicando,
        onTocar: _publicar,
      ),
      filhos: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CampoLongo(
                rotulo: 'Título',
                controller: _titulo,
                dica: 'Ex.: Manutenção da catraca 1',
                maximo: Comunicado.maxTitulo,
                validator: (v) => _validar(
                  v,
                  campo: 'titulo',
                  maximo: Comunicado.maxTitulo,
                  vazio: 'Informe o título.',
                  longo:
                      'O título pode ter até ${Comunicado.maxTitulo} '
                      'caracteres.',
                ),
              ),
              const SizedBox(height: 20),
              _CampoLongo(
                rotulo: 'Mensagem',
                controller: _mensagem,
                dica: 'O que as pessoas precisam saber',
                maximo: Comunicado.maxMensagem,
                linhas: 6,
                validator: (v) => _validar(
                  v,
                  campo: 'mensagem',
                  maximo: Comunicado.maxMensagem,
                  vazio: 'Escreva a mensagem.',
                  longo:
                      'A mensagem pode ter até ${Comunicado.maxMensagem} '
                      'caracteres.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Como o CampoTexto (rótulo em cima), com contador de caracteres e, na
/// mensagem, várias linhas.
class _CampoLongo extends StatelessWidget {
  const _CampoLongo({
    required this.rotulo,
    required this.controller,
    required this.maximo,
    required this.validator,
    this.dica,
    this.linhas = 1,
  });

  final String rotulo;
  final TextEditingController controller;
  final int maximo;
  final FormFieldValidator<String> validator;
  final String? dica;
  final int linhas;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final variasLinhas = linhas > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(rotulo, style: textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLength: maximo,
          minLines: linhas,
          maxLines: variasLinhas ? linhas * 2 : 1,
          keyboardType: variasLinhas ? TextInputType.multiline : null,
          textInputAction: variasLinhas
              ? TextInputAction.newline
              : TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(hintText: dica, errorMaxLines: 2),
        ),
      ],
    );
  }
}
