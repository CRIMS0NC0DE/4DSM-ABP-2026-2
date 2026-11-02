import 'package:flutter/material.dart';

import '../../controllers/minhas_autorizacoes_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/autorizacao.dart';
import '../../services/api_client.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/cartao_erro.dart';
import '../widgets/selo_situacao.dart';
import 'autorizacao_textos.dart';
import 'detalhe_autorizacao_view.dart';

/// U7 · Minhas autorizações, com o carregando (E3), o vazio (E4) e a falta
/// de internet. "Ver detalhes" abre a U8; ao voltar, a lista recarrega,
/// porque a pessoa pode ter passado pela catraca de lá.
class MinhasAutorizacoesView extends StatefulWidget {
  final MinhasAutorizacoesController controller;

  MinhasAutorizacoesView({super.key, MinhasAutorizacoesController? controller})
    : controller = controller ?? MinhasAutorizacoesController();

  @override
  State<MinhasAutorizacoesView> createState() => _MinhasAutorizacoesViewState();
}

class _MinhasAutorizacoesViewState extends State<MinhasAutorizacoesView> {
  /// null enquanto carrega pela primeira vez.
  List<Autorizacao>? _lista;
  ApiException? _erro;

  MinhasAutorizacoesController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final lista = await controller.carregar();
      if (mounted) {
        setState(() {
          _lista = lista;
          _erro = null;
        });
      }
    } on ApiException catch (erro) {
      if (!mounted) return;
      if (erro.naoAutenticado) {
        await voltarAoLogin(context, erro, sair: controller.sair);
      } else if (_lista == null) {
        setState(() => _erro = erro);
      } else {
        // Já tem lista na tela: só avisa, sem apagar o que a pessoa vê.
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(erro.mensagem)));
      }
    }
  }

  /// Volta ao carregando (E3) e busca de novo.
  void _recarregar() {
    setState(() {
      _lista = null;
      _erro = null;
    });
    _carregar();
  }

  Future<void> _abrir(Autorizacao autorizacao) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalheAutorizacaoView(
          autorizacao: autorizacao,
          agora: controller.agora(),
        ),
      ),
    );
    if (mounted) await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregar,
          child: SingleChildScrollView(
            // Puxar para atualizar funciona mesmo com a lista curta.
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (Navigator.of(context).canPop())
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Voltar'),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Minhas autorizações',
                        style: textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Onde e quando você pode entrar',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._conteudo(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _conteudo() {
    if (_erro case final erro?) {
      return [
        CartaoErro(
          icone: erro.semConexao ? Icons.wifi_off : Icons.error_outline,
          titulo: erro.semConexao
              ? 'Sem conexão com a internet'
              : 'Não foi possível carregar',
          texto: erro.semConexao
              ? 'Confira o Wi-Fi ou os dados móveis do celular e tente de novo.'
              : erro.mensagem,
          dica: erro.semConexao
              ? 'Sem internet, sua tag NFC continua funcionando no terminal.'
              : null,
          onTentarDeNovo: _recarregar,
        ),
      ];
    }
    final lista = _lista;
    if (lista == null) return const [_Carregando()];
    if (lista.isEmpty) return [_Vazio(onAtualizar: _recarregar)];

    final (:ativas, :encerradas) = controller.agrupar(lista);
    final hoje = controller.agora();
    Widget cartao(Autorizacao a) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _CartaoAutorizacao(
        autorizacao: a,
        hoje: hoje,
        onAbrir: () => _abrir(a),
      ),
    );

    return [
      const _TituloSecao('Ativas'),
      if (ativas.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Nenhuma autorização vale agora. Se precisar entrar, peça uma '
            'nova à portaria.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ...ativas.map(cartao),
      if (encerradas.isNotEmpty) ...[
        const SizedBox(height: 8),
        const _TituloSecao('Encerradas'),
        ...encerradas.map(cartao),
      ],
    ];
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        header: true,
        child: Text(
          texto,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _CartaoAutorizacao extends StatelessWidget {
  const _CartaoAutorizacao({
    required this.autorizacao,
    required this.hoje,
    required this.onAbrir,
  });

  final Autorizacao autorizacao;
  final DateTime hoje;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final catraca = autorizacao.catraca;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAbrir,
        borderRadius: BorderRadius.circular(AppTheme.radius + 4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(catraca.nome, style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          catraca.edificio,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SeloSituacao(situacao: autorizacao.situacao),
                ],
              ),
              const Divider(height: 28),
              _Linha(
                icone: Icons.event_outlined,
                texto: autorizacao.periodoCurto(hoje),
              ),
              _Linha(icone: Icons.schedule, texto: autorizacao.horario),
              if (autorizacao.ultimoUso)
                _Linha(
                  icone: Icons.warning_amber_rounded,
                  texto: 'Último uso disponível',
                  cor: status.warning,
                )
              else
                _Linha(
                  icone: Icons.confirmation_number_outlined,
                  texto: autorizacao.usos,
                ),
              TextButton(
                onPressed: onAbrir,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text('Ver detalhes')),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.texto, this.cor});

  final IconData icone;
  final String texto;

  /// Cor de destaque (ex.: laranja em "Último uso disponível").
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 22, color: cor ?? colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: cor == null
                  ? textTheme.bodyMedium
                  : textTheme.bodyMedium?.copyWith(
                      color: cor,
                      fontWeight: FontWeight.w700,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// E3 · Autorizações · carregando: aviso e cartões "fantasma".
class _Carregando extends StatelessWidget {
  const _Carregando();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Carregando suas autorizações…',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const ExcludeSemantics(
          child: Column(
            children: [
              _CartaoFantasma(),
              SizedBox(height: 16),
              _CartaoFantasma(),
              SizedBox(height: 16),
              _CartaoFantasma(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartaoFantasma extends StatelessWidget {
  const _CartaoFantasma();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Barra(largura: 0.75, altura: 22),
                      SizedBox(height: 10),
                      _Barra(largura: 0.45, altura: 14),
                    ],
                  ),
                ),
                SizedBox(width: 24),
                SizedBox(width: 80, child: _Barra(largura: 1, altura: 30)),
              ],
            ),
            Divider(height: 32),
            _Barra(largura: 0.7, altura: 16),
            SizedBox(height: 10),
            _Barra(largura: 0.55, altura: 16),
          ],
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({required this.largura, required this.altura});

  /// Fração da largura disponível.
  final double largura;
  final double altura;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: largura,
      child: Container(
        height: altura,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(altura / 2),
        ),
      ),
    );
  }
}

/// E4 · Autorizações · vazio.
class _Vazio extends StatelessWidget {
  const _Vazio({required this.onAtualizar});

  final VoidCallback onAtualizar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: const Icon(Icons.event_busy, size: 40),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Você ainda não tem autorizações',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Quando a portaria liberar seu acesso, ele aparece aqui.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onAtualizar,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }
}
