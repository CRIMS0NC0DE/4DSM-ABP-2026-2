import 'package:flutter/material.dart';


class Carregando extends StatelessWidget {
  const Carregando({super.key, this.mensagem = 'Carregando…'});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(mensagem, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.texto,
    this.rotuloAcao,
    this.iconeAcao,
    this.onAcao,
  });

  final IconData icone;
  final String titulo;
  final String texto;
  final String? rotuloAcao;
  final IconData? iconeAcao;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Icon(icone, size: 40),
            ),
          ),
          const SizedBox(height: 24),
          Text(titulo, textAlign: TextAlign.center, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (rotuloAcao != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onAcao,
              icon: Icon(iconeAcao ?? Icons.refresh),
              label: Text(rotuloAcao!),
            ),
          ],
        ],
      ),
    );
  }
}