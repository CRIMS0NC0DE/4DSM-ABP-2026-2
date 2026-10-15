import 'package:flutter/widgets.dart';

/// Cor do ícone da opção. A tela troca pelo par de cores do AppColors.
enum TomOpcao { padrao, sucesso, atencao, perigo }

/// Um card do menu em grade.
class OpcaoMenu {
  const OpcaoMenu({
    required this.titulo,
    required this.descricao,
    required this.icone,
    this.tom = TomOpcao.padrao,
  });

  final String titulo;
  final String descricao;
  final IconData icone;
  final TomOpcao tom;
}

/// Um grupo de opções com título, ex.: "Cadastros".
class SecaoMenu {
  const SecaoMenu({required this.titulo, required this.opcoes});

  final String titulo;
  final List<OpcaoMenu> opcoes;
}
