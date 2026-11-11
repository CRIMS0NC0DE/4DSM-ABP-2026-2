import 'package:flutter/material.dart';

import '../../models/autorizacao.dart';
import '../widgets/botao_acao.dart';
import '../widgets/selo_situacao.dart';
import 'autorizacao_textos.dart';
import 'scanner_qr_view.dart';

/// U8 · Detalhe da autorização: onde, período, horário e usos. Quando ela
/// vale hoje, mostra como passar e o botão do scanner.
class DetalheAutorizacaoView extends StatelessWidget {
  const DetalheAutorizacaoView({
    super.key,
    required this.autorizacao,
    required this.agora,
  });

  final Autorizacao autorizacao;

  /// Hora em que a tela abriu, para "Você pode entrar hoje até 18:00.".
  final DateTime agora;

  bool get _ativa => autorizacao.situacao == SituacaoAutorizacao.ativa;

  void _escanear(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ScannerQrView()));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final catraca = autorizacao.catraca;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Voltar'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(catraca.nome, style: textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      catraca.edificio,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SeloSituacao(situacao: autorizacao.situacao),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      autorizacao.quandoEntrar(agora),
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _Item(
                              icone: Icons.location_on_outlined,
                              rotulo: 'Onde',
                              valor: catraca.onde,
                            ),
                            const Divider(height: 1),
                            _Item(
                              icone: Icons.event_outlined,
                              rotulo: 'Período',
                              valor: autorizacao.periodo,
                            ),
                            const Divider(height: 1),
                            _Item(
                              icone: Icons.schedule,
                              rotulo: 'Horário',
                              valor: autorizacao.horario,
                            ),
                            const Divider(height: 1),
                            _Item(
                              icone: Icons.confirmation_number_outlined,
                              rotulo: 'Usos',
                              valor: autorizacao.restantes,
                              rodape: _BarraDeUsos(autorizacao: autorizacao),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_ativa) ...[
                      const SizedBox(height: 16),
                      const _ComoPassar(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      // Só dá para passar com a autorização que vale hoje.
      bottomNavigationBar: _ativa
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: Center(
                    heightFactor: 1,
                    // Mesma largura do conteúdo (480 menos as margens).
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 432),
                      child: SizedBox(
                        width: double.infinity,
                        child: BotaoAcao(
                          rotulo: 'Escanear QR Code',
                          icone: Icons.qr_code_scanner,
                          onTocar: () => _escanear(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.rodape,
  });

  final IconData icone;
  final String rotulo;
  final String valor;
  final Widget? rodape;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icone, color: colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotulo, style: textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(valor, style: textTheme.titleMedium),
                if (rodape != null) ...[const SizedBox(height: 10), rodape!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraDeUsos extends StatelessWidget {
  const _BarraDeUsos({required this.autorizacao});

  final Autorizacao autorizacao;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fracao = autorizacao.maxUsos == 0
        ? 0.0
        : autorizacao.usosRestantes / autorizacao.maxUsos;

    // O texto em cima já diz os números; a barra é só visual.
    return ExcludeSemantics(
      child: LinearProgressIndicator(
        value: fracao.clamp(0, 1),
        minHeight: 6,
        borderRadius: BorderRadius.circular(3),
        color: colorScheme.primary,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class _ComoPassar extends StatelessWidget {
  const _ComoPassar();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Como passar', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            const _Passo(
              numero: 1,
              texto: TextSpan(
                children: [
                  TextSpan(text: 'Toque em '),
                  TextSpan(
                    text: 'Escanear QR Code',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ', aqui embaixo.'),
                ],
              ),
            ),
            const _Passo(
              numero: 2,
              texto: TextSpan(
                text: 'Aponte a câmera para o QR na tela da catraca.',
              ),
            ),
            const _Passo(
              numero: 3,
              texto: TextSpan(
                text: 'Se tiver uma tag NFC, é só aproximar do terminal.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({required this.numero, required this.texto});

  final int numero;
  final TextSpan texto;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              '$numero',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text.rich(texto, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
