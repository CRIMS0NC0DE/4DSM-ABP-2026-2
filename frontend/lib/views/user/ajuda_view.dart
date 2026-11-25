import 'package:flutter/material.dart';

import '../../controllers/configuracoes_controller.dart';
import '../widgets/tela_base.dart';

/// Ajuda: o contato da portaria vem das Configurações (GET /settings). Sem
/// internet ou com qualquer erro, mostra o contato fixo abaixo: a Ajuda não
/// pode depender da API.
class AjudaView extends StatefulWidget {
  const AjudaView({super.key, this.controller});

  /// null usa a API do app.
  final ConfiguracoesController? controller;

  @override
  State<AjudaView> createState() => _AjudaViewState();
}

class _AjudaViewState extends State<AjudaView> {
  // Reserva, quando a API não responde. TROQUE pelos dados reais do prédio.
  static const _telefone = '(12) 0000-0000';
  static const _horario = 'Todos os dias, das 06:00 às 22:00';

  /// Nunca falha: sem contato na API, completa com null.
  late final Future<String?> _contato =
      (widget.controller ?? ConfiguracoesController()).contatoPortaria();

  static const _perguntas = [
    (
      'O QR Code não abre a catraca',
      'Confira se a localização do celular está ligada e chegue mais perto da '
          'catraca. O QR troca a cada 10 segundos: espere o novo e escaneie de '
          'novo.',
    ),
    (
      'Perdi minha tag NFC',
      'Avise a portaria o quanto antes para ela bloquear a tag.',
    ),
    (
      'Esqueci minha senha',
      'A portaria cria uma senha nova para você. Leve um documento.',
    ),
    (
      'Minha autorização venceu',
      'Peça uma nova autorização à portaria ou à pessoa que recebe você.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TelaBase(
      titulo: 'Ajuda',
      subtitulo: 'Contato da portaria',
      filhos: [
        Card(
          child: FutureBuilder<String?>(
            future: _contato,
            builder: (context, contato) {
              if (contato.connectionState != ConnectionState.done) {
                return const ListTile(
                  leading: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  title: Text('Buscando o contato da portaria…'),
                );
              }
              final texto = contato.data;
              if (texto != null) {
                return ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Portaria'),
                  subtitle: Text(texto),
                );
              }
              return const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.phone_outlined),
                    title: Text('Telefone'),
                    subtitle: Text(_telefone),
                  ),
                  ListTile(
                    leading: Icon(Icons.schedule),
                    title: Text('Atendimento'),
                    subtitle: Text(_horario),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text('Dúvidas comuns', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (pergunta, resposta) in _perguntas)
                ExpansionTile(
                  title: Text(pergunta),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(resposta)],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
