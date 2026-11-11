import 'package:flutter/material.dart';

/// Campo que abre um seletor em vez do teclado (data e hora em A8 e A9).
class CampoSelecao extends StatelessWidget {
  const CampoSelecao({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.onTocar,
  });

  final String rotulo;
  final String valor;
  final IconData icone;
  final VoidCallback onTocar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '$rotulo: $valor',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(rotulo, style: textTheme.labelLarge),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTocar,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: InputDecoration(prefixIcon: Icon(icone)),
              child: Text(valor, style: textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de escolha com o rótulo em cima, como o [CampoTexto].
class CampoEscolha<T> extends StatelessWidget {
  const CampoEscolha({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.opcoes,
    required this.onMudar,
    required this.icone,
    this.validator,
  });

  final String rotulo;
  final T? valor;

  /// Valor e texto de cada opção. Um valor null serve para "Todas".
  final List<(T, String)> opcoes;

  /// null desabilita (ex.: a pessoa não muda ao editar uma autorização).
  final ValueChanged<T?>? onMudar;
  final IconData icone;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(rotulo, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: valor,
          isExpanded: true,
          // Sem isto, o campo vazio não mostra nem anuncia nada.
          hint: const Text('Escolha…'),
          validator: validator,
          decoration: InputDecoration(prefixIcon: Icon(icone)),
          onChanged: onMudar,
          items: [
            for (final (valor, texto) in opcoes)
              DropdownMenuItem(
                value: valor,
                child: Text(texto, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ],
    );
  }
}

/// Uma escolha entre poucas opções, em chips (Status em A8, Resultado em A11).
class EscolhaEmChips<T> extends StatelessWidget {
  const EscolhaEmChips({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.opcoes,
    required this.onMudar,
  });

  final String rotulo;
  final T valor;
  final List<(T, String)> opcoes;
  final ValueChanged<T> onMudar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (opcao, texto) in opcoes)
              ChoiceChip(
                label: Text(texto),
                selected: opcao == valor,
                onSelected: (_) => onMudar(opcao),
              ),
          ],
        ),
      ],
    );
  }
}

/// Botão "Filtrar" das listas (A7, A11). Um botão de verdade: o ActionChip é
/// anunciado como caixa de seleção pelo leitor de tela.
class BotaoFiltrar extends StatelessWidget {
  const BotaoFiltrar({super.key, required this.onTocar});

  final VoidCallback onTocar;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTocar,
      icon: const Icon(Icons.tune),
      label: const Text('Filtrar'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
    );
  }
}
