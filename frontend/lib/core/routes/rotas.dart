import 'package:flutter/widgets.dart';

import '../../models/usuario.dart';
import '../../views/access_controller/access_controller_menu_view.dart';
import '../../views/admin/admin_menu_view.dart';
import '../../views/resident/resident_menu_view.dart';
import '../../views/visitor/visitor_menu_view.dart';

/// Menu que cada perfil abre depois do login (ou ao abrir o app já logado).
Widget menuDoPerfil(Perfil perfil) => switch (perfil) {
  Perfil.admin => AdminMenuView(),
  Perfil.controladorAcesso => AccessControllerMenuView(),
  Perfil.morador => ResidentMenuView(),
  Perfil.visitante => VisitorMenuView(),
};
