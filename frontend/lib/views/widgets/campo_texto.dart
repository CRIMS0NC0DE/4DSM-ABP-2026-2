import 'package:flutter/material.dart';

/// Campo de formulário com o rótulo em cima, como no docs/Design.pdf.
/// Usado no login e no cadastro.
/// Com [senha], esconde o texto e mostra o botão "Mostrar"/"Ocultar".
class CampoTexto extends StatefulWidget {
  const CampoTexto({
    super.key,
    required this.rotulo,
    required this.controller,
    required this.icone,
    this.validator,
    this.dica,
    this.ajuda,
    this.senha = false,
    this.teclado,
    this.acao = TextInputAction.next,
    this.autofill,
    this.onEnviar,
  });

  final String rotulo;
  final TextEditingController controller;
  final IconData icone;
  final FormFieldValidator<String>? validator;

  /// Texto de exemplo dentro do campo vazio.
  final String? dica;

  /// Texto de ajuda embaixo do campo.
  final String? ajuda;

  final bool senha;
  final TextInputType? teclado;
  final TextInputAction acao;
  final Iterable<String>? autofill;
  final VoidCallback? onEnviar;

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  late var _oculto = widget.senha;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.rotulo, style: textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _oculto,
          enableSuggestions: !widget.senha,
          autocorrect: !widget.senha,
          keyboardType: widget.teclado,
          textInputAction: widget.acao,
          autofillHints: widget.autofill,
          onFieldSubmitted: (_) => widget.onEnviar?.call(),
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.dica,
            helperText: widget.ajuda,
            helperMaxLines: 2,
            errorMaxLines: 2,
            prefixIcon: Icon(widget.icone),
            suffixIcon: widget.senha
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: TextButton.icon(
                      onPressed: () => setState(() => _oculto = !_oculto),
                      icon: Icon(
                        _oculto
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      label: Text(_oculto ? 'Mostrar' : 'Ocultar'),
                      style: TextButton.styleFrom(
                        textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
