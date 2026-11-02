import 'package:flutter/material.dart';

import '../../core/constants/formato.dart';
import '../../core/constants/motivos.dart';
import '../../models/evento_acesso.dart';
import '../../models/opcao_menu.dart';
import 'selo.dart';

/// Uma linha do histórico (A11) e dos negados recentes (A1).
class ItemEvento extends StatelessWidget {
  const ItemEvento({
    super.key,
    required this.evento,
    this.mostrarPessoa = true,
    this.mostrarOQueFazer = false,
  });

  final EventoAcesso evento;

  /// A equipe vê quem tentou; o morador só vê os próprios acessos.
  final bool mostrarPessoa;

  /// O morador vê como resolver; a equipe só o motivo.
  final bool mostrarOQueFazer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final titulo = mostrarPessoa
        ? (evento.pessoa ?? 'Pessoa não identificada')
        : (evento.catraca ?? 'Catraca não identificada');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Formato.hora(evento.em), style: textTheme.titleMedium),
                    Text(
                      Formato.diaMes(evento.em),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: textTheme.titleMedium),
                    if (mostrarPessoa && evento.catraca != null)
                      Text(evento.catraca!, style: textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        evento.liberado
                            ? const Selo(
                                texto: 'Liberado',
                                icone: Icons.check_circle,
                                tom: TomOpcao.sucesso,
                              )
                            : const Selo(
                                texto: 'Negado',
                                icone: Icons.cancel,
                                tom: TomOpcao.perigo,
                              ),
                        Selo(
                          texto: evento.metodo == 'NFC' ? 'Tag NFC' : 'QR Code',
                          icone: evento.metodo == 'NFC'
                              ? Icons.contactless_outlined
                              : Icons.qr_code_2,
                        ),
                      ],
                    ),
                    if (!evento.liberado) ...[
                      const SizedBox(height: 8),
                      Text(
                        Motivos.titulo(evento.motivo),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (mostrarOQueFazer)
                        Text(
                          Motivos.oQueFazer(evento.motivo),
                          style: textTheme.bodySmall,
                        ),
                    ],
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
