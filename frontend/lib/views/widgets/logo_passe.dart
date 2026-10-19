import 'package:flutter/material.dart';

/// Logo do app: escudo com o rosto do gorila.
/// Mesmo desenho dos SVGs de referência (viewBox 120×120), mas pintado com
/// as cores do tema, então serve no modo claro e no escuro sem dois arquivos.
class LogoPasse extends StatelessWidget {
  const LogoPasse({super.key, this.tamanho = 56});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(tamanho),
      painter: _PintorLogo(Theme.of(context).colorScheme),
    );
  }
}

class _PintorLogo extends CustomPainter {
  _PintorLogo(this.colorScheme);

  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 120);

    final escudo = Path()
      ..moveTo(60, 8)
      ..lineTo(102, 22)
      ..lineTo(102, 58)
      ..cubicTo(102, 84, 84, 102, 60, 112)
      ..cubicTo(36, 102, 18, 84, 18, 58)
      ..lineTo(18, 22)
      ..close();
    canvas
      ..drawPath(escudo, Paint()..color = colorScheme.surface)
      ..drawPath(escudo, _traco(colorScheme.primary, 5));

    // Sobrancelha
    canvas.drawPath(
      _poligono(const [
        (30, 50), (46, 40), (60, 47), (74, 40), (90, 50), //
        (86, 58), (73, 52), (60, 58), (47, 52), (34, 58),
      ]),
      Paint()..color = colorScheme.primary,
    );

    // Olhos
    final olho = Paint()..color = colorScheme.onSurface;
    const canto = Radius.circular(1);
    canvas
      ..drawRRect(RRect.fromLTRBR(43, 60, 52, 64, canto), olho)
      ..drawRRect(RRect.fromLTRBR(68, 60, 77, 64, canto), olho);

    // Focinho e narinas
    canvas
      ..drawPath(
        _poligono(const [(45, 72), (60, 66), (75, 72), (73, 87), (60, 95), (47, 87)]),
        _traco(colorScheme.onSurface, 3.2),
      )
      ..drawPath(
        Path()
          ..moveTo(54, 76)
          ..lineTo(56, 80)
          ..moveTo(66, 76)
          ..lineTo(64, 80),
        _traco(colorScheme.onSurface, 3),
      );

    // Boca
    canvas.drawPath(
      Path()
        ..moveTo(53, 87)
        ..lineTo(60, 90)
        ..lineTo(67, 87),
      _traco(colorScheme.onSurfaceVariant, 2.6),
    );
  }

  Paint _traco(Color cor, double largura) => Paint()
    ..color = cor
    ..style = PaintingStyle.stroke
    ..strokeWidth = largura
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  Path _poligono(List<(double, double)> pontos) =>
      Path()..addPolygon([for (final (x, y) in pontos) Offset(x, y)], true);

  @override
  bool shouldRepaint(_PintorLogo antigo) => antigo.colorScheme != colorScheme;
}
