import 'package:flutter/material.dart';

import '../../controllers/comunicados_controller.dart';
import '../../controllers/minhas_autorizacoes_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/autorizacao.dart';
import '../../models/comunicado.dart';
import '../../services/auth_service.dart';
import '../shared/comunicados_view.dart';
import '../widgets/botao_acao.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/selo_situacao.dart';
import '../widgets/tela_base.dart';
import 'autorizacao_textos.dart';
import 'detalhe_autorizacao_view.dart';
import 'scanner_qr_view.dart';

/// U2 · Início, com o carregando (E1) e o sem internet (E2): a próxima
/// autorização, o atalho para o scanner e, se houver, o comunicado mais
/// recente. [menu] é o menu em grade do perfil.
class InicioView extends StatefulWidget {
  InicioView({
    super.key,
    required this.menu,
    MinhasAutorizacoesController? controller,
    ComunicadosController? comunicados,
  }) : controller = controller ?? MinhasAutorizacoesController(),
       comunicados = comunicados ?? ComunicadosController();

  final Widget menu;
  final MinhasAutorizacoesController controller;
  final ComunicadosController comunicados;

  @override
  State<InicioView> createState() => _InicioViewState();
}

class _InicioViewState extends State<InicioView>
    with CarregaDados<List<Autorizacao>, InicioView> {
  MinhasAutorizacoesController get controller => widget.controller;

  /// O cartão do comunicado é um extra: se a busca falhar, o Início fica
  /// como antes, sem ele.
  Comunicado? _comunicado;

  @override
  Future<List<Autorizacao>> buscar() => controller.carregar();

  @override
  Future<void> carregar() async {
    // Em paralelo, sem segurar as autorizações.
    _buscarComunicado();
    await super.carregar();
  }

  Future<void> _buscarComunicado() async {
    final ultimo = await widget.comunicados.ultimo();
    if (mounted) setState(() => _comunicado = ultimo);
  }

  Future<void> _ir(Widget tela) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
    // Quem saiu da conta pelo menu não volta para cá: o Início ainda está
    // montado, mas não é a tela atual e já não tem token para buscar nada.
    if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
      await carregar();
    }
  }

  List<Widget> _resumo(List<Autorizacao> lista) {
    final textTheme = Theme.of(context).textTheme;
    final agora = controller.agora();
    final proxima = controller.agrupar(lista).ativas.firstOrNull;

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: proxima == null
              ? const Text(
                  'Você não tem autorização válida. Peça uma à portaria.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sua próxima autorização',
                                style: textTheme.bodySmall,
                              ),
                              Text(
                                proxima.catraca.nome,
                                style: textTheme.titleLarge,
                              ),
                              Text(
                                proxima.catraca.edificio,
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SeloSituacao(situacao: proxima.situacao),
                      ],
                    ),
                    const Divider(height: 28),
                    Text('Válida até ${Formato.data(proxima.dataFim)}'),
                    Text(proxima.horario),
                    Text(proxima.usos),
                    TextButton(
                      onPressed: () => _ir(
                        DetalheAutorizacaoView(
                          autorizacao: proxima,
                          agora: agora,
                        ),
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Ver detalhes ›'),
                    ),
                  ],
                ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final nome = AuthService.instancia.usuario?.nome.split(' ').first;

    return TelaBase(
      titulo: nome == null ? 'Olá' : 'Olá, $nome',
      subtitulo: Formato.dataPorExtenso(controller.agora()),
      onAtualizar: carregar,
      filhos: [
        ...conteudo(_resumo),
        const SizedBox(height: 16),
        BotaoAcao(
          rotulo: 'Escanear QR Code',
          icone: Icons.qr_code_scanner,
          onTocar: () => _ir(ScannerQrView()),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _ir(widget.menu),
          icon: const Icon(Icons.menu),
          label: const Text('Menu'),
        ),
        if (_comunicado case final comunicado?) ...[
          const SizedBox(height: 24),
          _CartaoComunicado(
            comunicado: comunicado,
            quando: comunicado.quando(widget.comunicados.agora()),
            onTocar: () => _ir(ComunicadosView(controller: widget.comunicados)),
          ),
        ],
      ],
    );
  }
}

/// Cartão discreto com o comunicado mais recente; abre a lista.
class _CartaoComunicado extends StatelessWidget {
  const _CartaoComunicado({
    required this.comunicado,
    required this.quando,
    required this.onTocar,
  });

  final Comunicado comunicado;

  /// "Hoje às 09:12".
  final String quando;
  final VoidCallback onTocar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.campaign_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comunicado · $quando',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(comunicado.titulo, style: textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      comunicado.mensagem,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
