import 'package:flutter/material.dart';

import '../widgets/tela_base.dart';

/// Ajuda: texto fixo, sem chamar a API.
class AjudaView extends StatelessWidget {
  const AjudaView({super.key});

  // TROQUE pelos dados reais do prédio.
  static const _telefone = '(12) 0000-0000';
  static const _horario = 'Todos os dias, das 06:00 às 22:00';

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
        const Card(
          child: Column(
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
