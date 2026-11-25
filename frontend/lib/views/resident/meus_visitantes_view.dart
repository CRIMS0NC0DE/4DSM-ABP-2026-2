import 'package:flutter/material.dart';

import '../../controllers/meus_visitantes_controller.dart';
import '../../models/meu_visitante.dart';
import '../../services/api_client.dart';
import '../user/autorizacao_textos.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/selo_situacao.dart';
import '../widgets/tela_base.dart';
import 'visitante_form_view.dart';

/// Meus visitantes (condômino): quem o morador cadastrou, onde e quando pode
/// entrar, com o cancelamento. "Novo visitante" abre o formulário; ao voltar,
/// a lista recarrega.
class MeusVisitantesView extends StatefulWidget {
  MeusVisitantesView({super.key, MeusVisitantesController? controller})
    : controller = controller ?? MeusVisitantesController();

  final MeusVisitantesController controller;

  @override
  State<MeusVisitantesView> createState() => _MeusVisitantesViewState();
}

class _MeusVisitantesViewState extends State<MeusVisitantesView>
    with CarregaDados<List<MeuVisitante>, MeusVisitantesView> {
  /// Convite sendo cancelado agora; trava o botão dele.
  String? _cancelando;

  MeusVisitantesController get controller => widget.controller;

  @override
  Future<List<MeuVisitante>> buscar() => controller.listar();

  Future<void> _novo() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VisitanteFormView(controller: controller),
      ),
    );
    // Recarrega mesmo sem o "Concluir": o visitante pode ter sido criado.
    if (mounted) await carregar();
  }

  Future<void> _cancelar(MeuVisitante visitante) async {
    final autorizacao = visitante.autorizacao;
    final nome = visitante.visitanteNome;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        actionsOverflowButtonSpacing: 8,
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(contexto).colorScheme.error,
          size: 36,
        ),
        title: Text('Cancelar o acesso de $nome?'),
        content: Text(
          '$nome não vai mais conseguir passar pela '
          '${autorizacao.catraca.nome}. Para liberar de novo, cadastre o '
          'visitante outra vez.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Não, manter'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(contexto).colorScheme.error,
              foregroundColor: Theme.of(contexto).colorScheme.onError,
            ),
            icon: const Icon(Icons.block),
            label: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _cancelando = autorizacao.id);
    try {
      await controller.cancelar(autorizacao.id);
      if (!mounted) return;
      avisar(context, 'Acesso de $nome cancelado.');
      await carregar();
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    } finally {
      if (mounted) setState(() => _cancelando = null);
    }
  }

  List<Widget> _lista(List<MeuVisitante> visitantes) {
    if (visitantes.isEmpty) {
      return const [
        EstadoVazio(
          icone: Icons.group_add_outlined,
          titulo: 'Você ainda não cadastrou visitantes',
          texto:
              'Toque em Novo visitante para liberar a entrada de alguém por '
              'tempo limitado, nas catracas que você usa.',
        ),
      ];
    }
    final hoje = controller.hoje();
    return [
      for (final visitante in visitantes)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _CartaoVisitante(
            visitante: visitante,
            hoje: hoje,
            cancelando: _cancelando == visitante.autorizacao.id,
            onCancelar: () => _cancelar(visitante),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Meus visitantes',
      subtitulo: 'Quem você convidou e quando pode entrar',
      onAtualizar: carregar,
      botaoFlutuante: FloatingActionButton.extended(
        onPressed: _novo,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Novo visitante'),
      ),
      filhos: conteudo(_lista),
    );
  }
}

class _CartaoVisitante extends StatelessWidget {
  const _CartaoVisitante({
    required this.visitante,
    required this.hoje,
    required this.cancelando,
    required this.onCancelar,
  });

  final MeuVisitante visitante;
  final DateTime hoje;
  final bool cancelando;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final autorizacao = visitante.autorizacao;
    final catraca = autorizacao.catraca;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // O selo fica ao lado do nome e desce para a linha de baixo
            // quando não cabe (nome comprido, fonte grande).
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(visitante.visitanteNome, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${catraca.nome} · ${catraca.edificio}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SeloSituacao(situacao: autorizacao.situacao),
                ),
              ],
            ),
            const Divider(height: 28),
            _Linha(
              icone: Icons.event_outlined,
              texto: autorizacao.periodoCurto(hoje),
            ),
            _Linha(icone: Icons.schedule, texto: autorizacao.horario),
            _Linha(
              icone: Icons.confirmation_number_outlined,
              texto: autorizacao.usos,
            ),
            // Só o que ainda vai valer pode ser cancelado.
            if (autorizacao.situacao.vigente) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: cancelando ? null : onCancelar,
                icon: cancelando
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.block),
                label: const Text('Cancelar acesso'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 22, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
