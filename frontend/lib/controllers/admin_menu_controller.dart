import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;

import '../models/opcao_menu.dart';
import '../services/auth_service.dart';

/// Menu do administrador.
/// Protótipo: as opções ainda não abrem telas, só registram o clique.
class AdminMenuController {
  AdminMenuController({AuthService? auth})
    : _auth = auth ?? AuthService.instancia;

  final AuthService _auth;

  List<SecaoMenu> get secoes => const [
    SecaoMenu(
      titulo: 'Controle de acesso',
      opcoes: [
        OpcaoMenu(
          titulo: 'Painel',
          descricao: 'Resumo dos acessos de hoje',
          icone: Icons.dashboard_outlined,
        ),
        OpcaoMenu(
          titulo: 'Autorizações',
          descricao: 'Quem pode entrar, onde e quando',
          icone: Icons.badge_outlined,
        ),
        OpcaoMenu(
          titulo: 'Histórico de acessos',
          descricao: 'Entradas liberadas e negadas',
          icone: Icons.history,
          tom: TomOpcao.sucesso,
        ),
        OpcaoMenu(
          titulo: 'Acessos negados',
          descricao: 'Motivo de cada recusa',
          icone: Icons.block,
          tom: TomOpcao.perigo,
        ),
      ],
    ),
    SecaoMenu(
      titulo: 'Cadastros',
      opcoes: [
        OpcaoMenu(
          titulo: 'Usuários',
          descricao: 'Pessoas, perfis e documentos',
          icone: Icons.group_outlined,
        ),
        OpcaoMenu(
          titulo: 'Visitantes',
          descricao: 'Acessos por tempo limitado',
          icone: Icons.schedule,
          tom: TomOpcao.atencao,
        ),
        OpcaoMenu(
          titulo: 'Locais',
          descricao: 'Edifícios, portarias e catracas',
          icone: Icons.apartment,
        ),
        OpcaoMenu(
          titulo: 'Tags NFC',
          descricao: 'Vincular e bloquear tags',
          icone: Icons.contactless_outlined,
        ),
      ],
    ),
    SecaoMenu(
      titulo: 'Gestão',
      opcoes: [
        OpcaoMenu(
          titulo: 'Terminais',
          descricao: 'Leitores de QR Code das catracas',
          icone: Icons.qr_code_2,
        ),
        OpcaoMenu(
          titulo: 'Relatórios',
          descricao: 'Acessos por período e local',
          icone: Icons.insert_chart_outlined,
        ),
        OpcaoMenu(
          titulo: 'Comunicados',
          descricao: 'Avisos para quem usa o prédio',
          icone: Icons.campaign_outlined,
        ),
        OpcaoMenu(
          titulo: 'Configurações',
          descricao: 'Regras e horários de acesso',
          icone: Icons.settings_outlined,
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
