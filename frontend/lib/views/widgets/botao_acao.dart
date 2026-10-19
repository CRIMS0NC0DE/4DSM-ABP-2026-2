import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Botão da ação principal da tela (ex.: Entrar, Registrar).
/// Brilha na cor da marca, afunda um pouco ao toque e vibra.
/// Com [carregando], troca o ícone por um indicador e não aceita toque,
/// mas mantém a cor da marca para não parecer desabilitado.
class BotaoAcao extends StatefulWidget {
  const BotaoAcao({
    super.key,
    required this.rotulo,
    required this.icone,
    required this.onTocar,
    this.carregando = false,
    this.brilho = true,
  });

  final String rotulo;
  final IconData icone;

  /// null desabilita o botão (fica cinza).
  final VoidCallback? onTocar;

  final bool carregando;
  final bool brilho;

  @override
  State<BotaoAcao> createState() => _BotaoAcaoState();
}

class _BotaoAcaoState extends State<BotaoAcao> {
  /// Avisa quando o botão é pressionado ou ganha foco, para o brilho reagir.
  final _estados = WidgetStatesController();

  @override
  void initState() {
    super.initState();
    _estados.addListener(_atualizar);
  }

  @override
  void dispose() {
    _estados.dispose();
    super.dispose();
  }

  void _atualizar() {
    // O ElevatedButton também avisa no meio do build, quando fica
    // habilitado/desabilitado (ex.: ao começar a carregar). Aí não dá para
    // chamar setState na hora; redesenha logo depois do frame.
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  bool get _habilitado => widget.onTocar != null && !widget.carregando;

  void _tocar() {
    HapticFeedback.mediumImpact();
    widget.onTocar?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final pressionado = _estados.value.contains(WidgetState.pressed);
    final destacado =
        _estados.value.contains(WidgetState.hovered) ||
        _estados.value.contains(WidgetState.focused);
    // Desabilitado de verdade fica cinza; carregando continua na cor da marca.
    final apagado = widget.onTocar == null && !widget.carregando;

    final alfaBrilho = !_habilitado || !widget.brilho
        ? 0.0
        : pressionado
        ? (isDark ? 0.30 : 0.22)
        : destacado
        ? (isDark ? 0.60 : 0.42)
        : (isDark ? 0.42 : 0.30);

    final botao = ElevatedButton(
      statesController: _estados,
      onPressed: _habilitado ? _tocar : null,
      style:
          ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: apagado
                ? colorScheme.surfaceContainerHighest
                : colorScheme.primary,
            disabledForegroundColor: apagado
                ? colorScheme.onSurfaceVariant
                : colorScheme.onPrimary,
            elevation: 0,
            side: BorderSide(
              color: apagado
                  ? colorScheme.outlineVariant
                  : Colors.white.withValues(alpha: isDark ? 0.35 : 0.18),
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith((estados) {
              if (estados.contains(WidgetState.pressed)) {
                return colorScheme.onPrimary.withValues(alpha: 0.14);
              }
              if (estados.contains(WidgetState.hovered)) {
                return Colors.white.withValues(alpha: 0.08);
              }
              return null;
            }),
          ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: widget.carregando
                ? SizedBox.square(
                    key: const ValueKey('carregando'),
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Icon(widget.icone, key: ValueKey(widget.icone), size: 22),
          ),
          const SizedBox(width: 10),
          Flexible(child: Text(widget.rotulo, textAlign: TextAlign.center)),
        ],
      ),
    );

    return AnimatedScale(
      scale: pressionado ? 0.97 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: alfaBrilho),
              blurRadius: pressionado ? 12 : 28,
              spreadRadius: -6,
              offset: Offset(0, pressionado ? 4 : 12),
            ),
          ],
        ),
        child: botao,
      ),
    );
  }
}
