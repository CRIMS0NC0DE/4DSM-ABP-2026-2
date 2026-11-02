import 'package:flutter/material.dart';

import '../../controllers/painel_controller.dart';
import '../../core/constants/formato.dart';
import '../../core/theme/app_colors.dart';
import '../../models/painel.dart';
import '../compartilhado/historico_view.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/item_evento.dart';
import '../widgets/tela_base.dart';
import 'autorizacao_form_view.dart';
import 'autorizacoes_view.dart';

/// A1 · Painel: o resumo de hoje para o admin e a portaria.
class PainelView extends StatefulWidget {
  PainelView({super.key, PainelController? controller})
    : controller = controller ?? PainelController();

  final PainelController controller;

  @override
  State<PainelView> createState() => _PainelViewState();
}

class _PainelViewState extends State<PainelView>
    with CarregaDados<({Painel painel, String? predio}), PainelView> {
  @override
  Future<({Painel painel, String? predio})> buscar() =>
      widget.controller.carregar();

  Future<void> _ir(Widget tela) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => tela));
    if (mounted) await carregar();
  }

  List<Widget> _resumo(({Painel painel, String? predio}) dados) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final painel = dados.painel;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Numero(
              icone: Icons.login,
              cor: status.success,
              fundo: status.successContainer,
              valor: painel.acessosHoje,
              rotulo: 'Acessos hoje',
              acao: 'Ver histórico',
              onTocar: () => _ir(HistoricoView(daEquipe: true)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Numero(
              icone: Icons.block,
              cor: colorScheme.error,
              fundo: colorScheme.errorContainer,
              valor: painel.negadosHoje,
              rotulo: 'Negados hoje',
              acao: 'Ver motivos',
              onTocar: () =>
                  _ir(HistoricoView(daEquipe: true, soNegados: true)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _Numero(
        icone: Icons.badge_outlined,
        cor: colorScheme.primary,
        fundo: colorScheme.primaryContainer,
        valor: painel.autorizacoesAtivas,
        rotulo: 'Autorizações ativas',
        acao: 'Ver autorizações',
        onTocar: () => _ir(AutorizacoesView()),
      ),
      const SizedBox(height: 24),
      Text('Negados recentes', style: textTheme.titleMedium),
      const SizedBox(height: 12),
      if (painel.negadosRecentes.isEmpty)
        Text('Nenhum acesso negado hoje.', style: textTheme.bodyMedium),
      for (final evento in painel.negadosRecentes) ItemEvento(evento: evento),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final predio = dados?.predio;
    final hoje = Formato.diaMes(DateTime.now());
    return TelaBase(
      titulo: 'Painel',
      subtitulo: predio == null ? 'Hoje, $hoje' : '$predio · hoje, $hoje',
      onAtualizar: carregar,
      botaoFlutuante: FloatingActionButton.extended(
        onPressed: () => _ir(AutorizacaoFormView()),
        icon: const Icon(Icons.add),
        label: const Text('Nova autorização'),
      ),
      filhos: conteudo(_resumo),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({
    required this.icone,
    required this.cor,
    required this.fundo,
    required this.valor,
    required this.rotulo,
    required this.acao,
    required this.onTocar,
  });

  final IconData icone;
  final Color cor;
  final Color fundo;
  final int valor;
  final String rotulo;
  final String acao;
  final VoidCallback onTocar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: fundo,
                child: Icon(icone, color: cor),
              ),
              const SizedBox(height: 12),
              Text('$valor', style: textTheme.headlineMedium),
              Text(rotulo, style: textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                '$acao ›',
                style: textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
