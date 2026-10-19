import 'dart:async';

import 'package:flutter/material.dart';

import 'logo_passe.dart';

/// Tela de transição para quando a próxima tela depende de uma espera
/// (ex.: entrar pela API, sair da conta): logo do app e uma barra amarela
/// que vai enchendo. Quando a [tarefa] termina, a barra completa e o app vai
/// para a tela que ela devolveu, limpando o histórico para o Voltar não
/// reabrir a anterior.
class TelaCarregando extends StatefulWidget {
  const TelaCarregando({
    super.key,
    required this.mensagem,
    required this.tarefa,
  });

  /// Texto embaixo da barra, ex.: "Entrando…".
  final String mensagem;

  /// Faz o trabalho e devolve a próxima tela.
  final Future<Widget> Function() tarefa;

  /// Abre a tela de carregamento por cima da atual e roda a [tarefa].
  /// Se ela falhar, fecha o carregamento e relança o erro, para a tela de
  /// antes avisar (ex.: senha errada no login).
  static Future<void> abrir(
    BuildContext context, {
    required String mensagem,
    required Future<Widget> Function() tarefa,
  }) async {
    final falha = await Navigator.of(context).push<(Object, StackTrace)>(
      _rotaComFade(TelaCarregando(mensagem: mensagem, tarefa: tarefa)),
    );
    if (falha case (final erro, final pilha)) {
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  @override
  State<TelaCarregando> createState() => _TelaCarregandoState();
}

/// Mesmo com resposta rápida, a barra leva [_tempoMinimo] para chegar a
/// [_parada], para a tela não só piscar.
const _tempoMinimo = Duration(milliseconds: 900);
const _parada = 0.8;

/// Troca de tela com fade, sem o deslize do Material.
PageRouteBuilder<T> _rotaComFade<T>(Widget tela) => PageRouteBuilder<T>(
  pageBuilder: (_, _, _) => tela,
  transitionsBuilder: (_, animacao, _, filho) =>
      FadeTransition(opacity: animacao, child: filho),
  transitionDuration: const Duration(milliseconds: 250),
  reverseTransitionDuration: const Duration(milliseconds: 200),
);

class _TelaCarregandoState extends State<TelaCarregando>
    with SingleTickerProviderStateMixin {
  late final _barra = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _barra.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final tarefa = widget.tarefa();
    final minimo = _encher();
    final Widget proxima;
    try {
      proxima = await tarefa;
      await minimo;
    } catch (erro, pilha) {
      await minimo;
      if (mounted) Navigator.of(context).pop((erro, pilha));
      return;
    }
    if (!mounted) return;
    // Completa a barra e só então troca de tela.
    await _barra.animateTo(
      1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeIn,
    );
    if (!mounted) return;
    Navigator.of(context)
        .pushAndRemoveUntil(_rotaComFade(proxima), (_) => false);
  }

  /// Enche a barra até [_parada]. Se a tarefa demorar mais que isso, segue
  /// andando devagar, sem chegar ao fim, para não parecer travada.
  Future<void> _encher() async {
    await _barra.animateTo(
      _parada,
      duration: _tempoMinimo,
      curve: Curves.easeOut,
    );
    unawaited(
      _barra.animateTo(
        0.95,
        duration: const Duration(seconds: 8),
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      // A tarefa já começou; o Voltar do celular não interrompe.
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _LogoComBrilho(tamanho: 112),
                  const SizedBox(height: 40),
                  _BarraProgresso(progresso: _barra, rotulo: widget.mensagem),
                  const SizedBox(height: 16),
                  // A barra já lê a mensagem para o leitor de tela.
                  ExcludeSemantics(
                    child: Text(
                      widget.mensagem,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo com o mesmo brilho amarelo do botão da ação principal.
class _LogoComBrilho extends StatelessWidget {
  const _LogoComBrilho({required this.tamanho});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tamanho * 0.22),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primaryFixed.withValues(
              alpha: isDark ? 0.30 : 0.22,
            ),
            blurRadius: 40,
            spreadRadius: -4,
          ),
        ],
      ),
      child: LogoPasse(tamanho: tamanho),
    );
  }
}

/// Barra de largura fixa na cor da marca.
class _BarraProgresso extends StatelessWidget {
  const _BarraProgresso({required this.progresso, required this.rotulo});

  final Animation<double> progresso;
  final String rotulo;

  static const _largura = 220.0;
  static const _altura = 6.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final raio = BorderRadius.circular(_altura / 2);

    return AnimatedBuilder(
      animation: progresso,
      builder: (context, _) => Semantics(
        label: rotulo,
        value: '${(progresso.value * 100).round()}%',
        child: Container(
          width: _largura,
          height: _altura,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant,
            borderRadius: raio,
          ),
          child: FractionallySizedBox(
            widthFactor: progresso.value,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primaryFixed,
                borderRadius: raio,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primaryFixed.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
