import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../controllers/acesso_qr_controller.dart';
import '../widgets/estado_erro.dart';
import 'validando_acesso_view.dart';

/// U3 · Scanner de QR. Lê o QR que a catraca mostra e passa o texto, sem
/// mudar nada, para a validação (U4). Câmera negada mostra a E7.
class ScannerQrView extends StatefulWidget {
  final AcessoQrController controller;

  ScannerQrView({super.key, AcessoQrController? controller})
    : controller = controller ?? AcessoQrController();

  @override
  State<ScannerQrView> createState() => _ScannerQrViewState();
}

class _ScannerQrViewState extends State<ScannerQrView> {
  final _camera = MobileScannerController();

  /// Já leu um QR e está validando: ignora as próximas leituras, para não
  /// mandar o mesmo QR duas vezes.
  var _validando = false;

  /// Leu um QR que não é de catraca (ex.: link de um site).
  var _qrDeOutroLugar = false;

  AcessoQrController get controller => widget.controller;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _ler(BarcodeCapture captura) async {
    if (_validando) return;
    final texto = captura.barcodes.firstOrNull?.rawValue;
    if (texto == null || !controller.qrDaCatraca(texto)) {
      if (!_qrDeOutroLugar) setState(() => _qrDeOutroLugar = true);
      return;
    }
    _validando = true;
    await _camera.stop();
    if (!mounted) return;

    final lerDeNovo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ValidandoAcessoView(token: texto, controller: controller),
      ),
    );
    if (!mounted) return;
    if (lerDeNovo ?? false) {
      setState(() {
        _validando = false;
        _qrDeOutroLugar = false;
      });
      await _camera.start();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _camera,
      builder: (context, estado, _) {
        if (estado.error?.errorCode ==
            MobileScannerErrorCode.permissionDenied) {
          return EstadoErro(
            icone: Icons.no_photography_outlined,
            titulo: 'O app precisa da câmera',
            texto:
                'Para ler o QR Code da catraca, permita o uso da câmera nas '
                'configurações do celular.',
            rotuloAcao: 'Abrir configurações',
            iconeAcao: Icons.settings_outlined,
            onAcao: controller.abrirConfiguracoes,
            rotuloVoltar: 'Voltar',
            iconeVoltar: Icons.arrow_back,
            onVoltar: () => Navigator.of(context).pop(),
          );
        }
        return _Camera(
          camera: _camera,
          lanterna: estado.torchState,
          qrDeOutroLugar: _qrDeOutroLugar,
          onLer: _ler,
        );
      },
    );
  }
}

/// A câmera com a moldura e as instruções do design, sempre no escuro.
class _Camera extends StatelessWidget {
  const _Camera({
    required this.camera,
    required this.lanterna,
    required this.qrDeOutroLugar,
    required this.onLer,
  });

  final MobileScannerController camera;
  final TorchState lanterna;
  final bool qrDeOutroLugar;
  final void Function(BarcodeCapture) onLer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme
        .apply(bodyColor: Colors.white, displayColor: Colors.white);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: camera,
              onDetect: onLer,
              errorBuilder: (context, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Não foi possível abrir a câmera.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white24,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Escanear QR Code', style: textTheme.titleLarge),
                  const Spacer(),
                  Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 4),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    qrDeOutroLugar
                        ? 'Esse QR Code não é de uma catraca'
                        : 'Aponte para o QR da catraca',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Segure o celular parado, a um palmo da tela.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  if (lanterna != TorchState.unavailable)
                    OutlinedButton.icon(
                      onPressed: camera.toggleTorch,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      icon: Icon(
                        lanterna == TorchState.on
                            ? Icons.flashlight_off
                            : Icons.flashlight_on,
                      ),
                      label: Text(
                        lanterna == TorchState.on
                            ? 'Desligar lanterna'
                            : 'Ligar lanterna',
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.contactless_outlined,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Ou aproxime sua tag do terminal',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
