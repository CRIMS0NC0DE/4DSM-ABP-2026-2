// O Material já tem uma classe MenuController; escondemos a dele para usar a nossa.
import 'package:flutter/material.dart' hide MenuController;

import '../../controllers/menu_controller.dart';

class MenuView extends StatelessWidget {
  final MenuController controller;

  MenuView({super.key, MenuController? controller})
    : controller = controller ?? MenuController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => controller.entrar(),
              child: const Text('1. Entrar'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => controller.registrar(),
              child: const Text('2. Registrar'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => controller.criarConta(),
              child: const Text('3. Criar conta'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => controller.fechar(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('4. Fechar'),
            ),
          ],
        ),
      ),
    );
  }
}
