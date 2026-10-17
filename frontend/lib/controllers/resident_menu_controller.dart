import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;

import '../models/opcao_menu.dart';
import '../services/auth_service.dart';

/// Menu do morador.
/// Só mostra o que é dele: as próprias autorizações, acessos e conta,
/// como nas telas U1 a U9 do docs/Design.pdf. Gestão do prédio (Painel,
/// Locais, Usuários...) fica com o admin e o controlador de acesso.
/// Protótipo: as opções ainda não abrem telas, só registram o clique.
class ResidentMenuController {
  ResidentMenuController({AuthService? auth})
    : _auth = auth ?? AuthService.instancia;

  final AuthService _auth;

  List<SecaoMenu> get secoes => const [
    SecaoMenu(
      titulo: 'Acessos',
      opcoes: [
        OpcaoMenu(
          titulo: 'Escanear QR Code',
          descricao: 'Aponte para o QR da catraca',
          icone: Icons.qr_code_scanner,
        ),
        OpcaoMenu(
          titulo: 'Minhas autorizações',
          descricao: 'Onde e quando você pode entrar',
          icone: Icons.badge_outlined,
        ),
        OpcaoMenu(
          titulo: 'Histórico de acessos',
          descricao: 'Suas entradas liberadas e negadas',
          icone: Icons.history,
          tom: TomOpcao.sucesso,
        ),
        OpcaoMenu(
          titulo: 'Acessos negados',
          descricao: 'Motivo e o que fazer',
          icone: Icons.block,
          tom: TomOpcao.perigo,
        ),
      ],
    ),
    SecaoMenu(
      titulo: 'Minha conta',
      opcoes: [
        OpcaoMenu(
          titulo: 'Meus visitantes',
          descricao: 'Avisar a portaria de quem vai chegar',
          icone: Icons.schedule,
          tom: TomOpcao.atencao,
        ),
        OpcaoMenu(
          titulo: 'Minha tag NFC',
          descricao: 'Ver ou bloquear sua tag',
          icone: Icons.contactless_outlined,
        ),
        OpcaoMenu(
          titulo: 'Perfil',
          descricao: 'Seus dados e documentos',
          icone: Icons.person_outline,
        ),
        OpcaoMenu(
          titulo: 'Ajuda',
          descricao: 'Contato da portaria',
          icone: Icons.support_agent,
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
