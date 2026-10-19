import 'package:flutter/material.dart';

/// Logo do app: gorila na mira da câmera, com a linha de scan amarela.
/// Arte original em docs/gorila-monitoramento-1024.png. O fundo escuro faz
/// parte do desenho, então o mesmo arquivo serve no modo claro e no escuro.
class LogoPasse extends StatelessWidget {
  const LogoPasse({super.key, this.tamanho = 56});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    // A arte tem 1024px; decodifica só no tamanho que aparece na tela.
    final pixels = (tamanho * MediaQuery.devicePixelRatioOf(context)).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(tamanho * 0.22),
      child: Image.asset(
        'assets/images/logo_gorila.png',
        width: tamanho,
        height: tamanho,
        cacheWidth: pixels,
        semanticLabel: 'Logo do Passe',
      ),
    );
  }
}
