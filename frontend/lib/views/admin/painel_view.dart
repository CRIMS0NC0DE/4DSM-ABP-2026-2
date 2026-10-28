import 'package:flutter/material.dart';

import '../../core/formatos.dart';
import '../../core/theme/app_colors.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../widgets/admin_widgets.dart';
import 'autorizacoes_view.dart';
import 'historico_view.dart';

/// Painel do administrador (A1): números de hoje e os últimos acessos
/// negados, cada um levando para a tela com os detalhes.
class PainelView extends StatefulWidget {
  const PainelView({super.key, this._servico});

  final AdminService? _servico;

  @override
  State<PainelView> createState() => _PainelViewState();
}

class _PainelViewState extends State<PainelView> {
  late final AdminService _servico = widget._servico ?? AdminService.instancia;
  var _versao = 0;

  void _abrir(Widget tela) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => tela))
      .then((_) => mounted ? setState(() => _versao++) : null);

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    return TelaAdmin(
      titulo: 'Painel',
      subtitulo: 'Hoje, ${Formatos.diaMes(agora)}',
      corpo: CarregaDados<ResumoPainel>(
        key: ValueKey(_versao),
        carregar: _servico.painel,
        mensagem: 'Carregando o painel…',
        construir: (context, resumo) => RefreshIndicator(
          onRefresh: () async => setState(() => _versao++),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CartaoNumero(
                      icone: Icons.login,
                      numero: resumo.acessosHoje,
                      rotulo: 'Acessos hoje',
                      acao: 'Ver histórico',
                      tom: TomSelo.sucesso,
                      onTap: () => _abrir(const HistoricoView()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CartaoNumero(
                      icone: Icons.block,
                      numero: resumo.negadosHoje,
                      rotulo: 'Negados hoje',
                      acao: 'Ver motivos',
                      tom: TomSelo.perigo,
                      onTap: () => _abrir(
                        const HistoricoView(
                          somenteNegados: true,
                          titulo: 'Acessos negados',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CartaoNumero(
                icone: Icons.badge_outlined,
                numero: resumo.autorizacoesAtivas,
                rotulo: 'Autorizações ativas',
                acao: 'Ver',
                tom: TomSelo.marca,
                onTap: () => _abrir(const AutorizacoesView()),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Negados recentes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _abrir(
                      const HistoricoView(
                        somenteNegados: true,
                        titulo: 'Acessos negados',
                      ),
                    ),
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (resumo.negadosRecentes.isEmpty)
                const EstadoVazio(
                  icone: Icons.verified_outlined,
                  titulo: 'Nenhum acesso negado hoje',
                  texto: 'Quando alguém for barrado, aparece aqui.',
                )
              else
                for (final e in resumo.negadosRecentes) ...[
                  CartaoEvento(evento: e, comData: false),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoNumero extends StatelessWidget {
  const _CartaoNumero({
    required this.icone,
    required this.numero,
    required this.rotulo,
    required this.acao,
    required this.tom,
    required this.onTap,
  });

  final IconData icone;
  final int numero;
  final String rotulo;
  final String acao;
  final TomSelo tom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final (cor, fundo) = switch (tom) {
      TomSelo.sucesso => (status.success, status.successContainer),
      TomSelo.perigo => (colorScheme.error, colorScheme.errorContainer),
      TomSelo.atencao => (status.warning, status.warningContainer),
      _ => (colorScheme.primary, colorScheme.primaryContainer),
    };
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: fundo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: cor),
              ),
              const SizedBox(height: 10),
              Text('$numero', style: textTheme.headlineMedium),
              Text(rotulo, style: textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      acao,
                      style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
