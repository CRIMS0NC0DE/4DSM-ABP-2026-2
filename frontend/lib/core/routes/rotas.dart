import 'package:flutter/widgets.dart';

import '../../models/usuario.dart';
import '../../views/teams/access_controller/access_controller_menu_view.dart';
import '../../views/teams/admin/admin_menu_view.dart';
import '../../views/teams/resident/resident_menu_view.dart';
import '../../views/teams/visitor/visitor_menu_view.dart';
import '../../views/user/inicio_view.dart';

/// Tela que cada perfil abre depois do login (ou ao abrir o app já logado):
/// o menu da equipe; morador e visitante abrem o Início, que leva ao menu.
Widget menuDoPerfil(Perfil perfil) => switch (perfil) {
  Perfil.admin => AdminMenuView(),
  Perfil.controladorAcesso => AccessControllerMenuView(),
  Perfil.morador => InicioView(menu: ResidentMenuView()),
  Perfil.visitante => InicioView(menu: VisitorMenuView()),
};
