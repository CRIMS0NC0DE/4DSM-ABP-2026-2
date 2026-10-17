import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;

import '../models/opcao_menu.dart';
import '../services/auth_service.dart';

/// Menu do controlador de acesso (portaria).
/// Cuida do dia a dia: atende quem foi barrado, cadastra visitantes e
/// renova autorizações. O admin é o cargo superior, então toda opção daqui
/// também existe no menu dele; Locais, Relatórios, Comunicados e
/// Configurações ficam só com o admin.
/// Protótipo: as opções ainda não abrem telas, só registram o clique.
class AccessControllerMenuController {
  AccessControllerMenuController({AuthService? auth})
    : _auth = auth ?? AuthService.instancia;

  final AuthService _auth;

  List<SecaoMenu> get secoes => const [
    SecaoMenu(
      titulo: 'Portaria',
      opcoes: [
        OpcaoMenu(
          titulo: 'Painel',
          descricao: 'Acessos de hoje em tempo real',
          icone: Icons.dashboard_outlined,
        ),
        OpcaoMenu(
          titulo: 'Acessos negados',
          descricao: 'Ver o motivo e ajudar quem foi barrado',
          icone: Icons.block,
          tom: TomOpcao.perigo,
        ),
        OpcaoMenu(
          titulo: 'Visitantes',
          descricao: 'Cadastrar visitante com acesso limitado',
          icone: Icons.schedule,
          tom: TomOpcao.atencao,
        ),
        OpcaoMenu(
          titulo: 'Autorizações',
          descricao: 'Renovar ou liberar mais usos',
          icone: Icons.badge_outlined,
        ),
      ],
    ),
    SecaoMenu(
      titulo: 'Cadastros',
      opcoes: [
        OpcaoMenu(
          titulo: 'Usuários',
          descricao: 'Primeiro acesso de moradores',
          icone: Icons.group_outlined,
        ),
        OpcaoMenu(
          titulo: 'Tags NFC',
          descricao: 'Vincular ou bloquear tag perdida',
          icone: Icons.contactless_outlined,
        ),
      ],
    ),
    SecaoMenu(
      titulo: 'Acompanhamento',
      opcoes: [
        OpcaoMenu(
          titulo: 'Histórico de acessos',
          descricao: 'Entradas liberadas e negadas',
          icone: Icons.history,
          tom: TomOpcao.sucesso,
        ),
        OpcaoMenu(
          titulo: 'Terminais',
          descricao: 'Catracas e leitores fora do ar',
          icone: Icons.qr_code_2,
        ),
      ],
    ),
  ];

  void abrir(OpcaoMenu opcao) {
    // Lógica para navegar para a tela da opção
    debugPrint('Abrindo ${opcao.titulo}...');
  }

  /// Esquece o token guardado no login.
  Future<void> sair() {
    debugPrint('Saindo da conta...');
    return _auth.sair();
  }
}
