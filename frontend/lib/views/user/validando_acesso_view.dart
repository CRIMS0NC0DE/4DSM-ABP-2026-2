import 'package:flutter/material.dart';

import '../../controllers/acesso_qr_controller.dart';
import '../../models/decisao_acesso.dart';
import '../../services/api_client.dart';
import '../widgets/estado_erro.dart';
import '../widgets/tela_carregando.dart';
import 'acesso_liberado_view.dart';
import 'acesso_negado_view.dart';
import 'login_view.dart';

/// U4 · Validando. Manda o QR lido para a API e mostra o resultado (U5, U6
/// ou E8) ou a falta de internet (E3).
/// Fecha devolvendo true quando a pessoa quer ler o QR de novo.
class ValidandoAcessoView extends StatefulWidget {
  final String token;
  final AcessoQrController controller;

  ValidandoAcessoView({
    super.key,
    required this.token,
    AcessoQrController? controller,
  }) : controller = controller ?? AcessoQrController();

  @override
  State<ValidandoAcessoView> createState() => _ValidandoAcessoViewState();
}

class _ValidandoAcessoViewState extends State<ValidandoAcessoView> {
  DecisaoAcesso? _decisao;
  ApiException? _erro;

  AcessoQrController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _validar();
  }

  Future<void> _validar() async {
    try {
      final decisao = await controller.validar(widget.token);
      if (mounted) setState(() => _decisao = decisao);
    } on ApiException catch (erro) {
      if (!mounted) return;
      if (erro.naoAutenticado) {
        await _sessaoVencida();
      } else {
        setState(() => _erro = erro);
      }
    }
  }

  /// Volta para o login; a tela de carregamento limpa o histórico, como o
  /// Sair dos menus.
  Future<void> _sessaoVencida() => TelaCarregando.abrir(
    context,
    mensagem: 'Sua sessão venceu. Voltando ao login…',
    tarefa: () async {
      await controller.sair();
      return LoginView();
    },
  );

  void _lerDeNovo() => Navigator.of(context).pop(true);

  void _voltar() => Navigator.of(context).pop(false);

  Future<void> _permitirLocalizacao() async {
    await controller.permitirLocalizacao();
    // O QR pode ter trocado enquanto a pessoa mexia nas configurações.
    if (mounted) _lerDeNovo();
  }

  @override
  Widget build(BuildContext context) {
    if (_decisao case final decisao?) {
      return decisao.liberado
          ? AcessoLiberadoView(decisao: decisao, onConcluir: _voltar)
          : AcessoNegadoView(
              decisao: decisao,
              onTentarDeNovo: _lerDeNovo,
              onVoltar: _voltar,
              onPermitirLocalizacao: _permitirLocalizacao,
            );
    }
    if (_erro case final erro?) {
      return EstadoErro(
        icone: erro.semConexao ? Icons.wifi_off : Icons.error_outline,
        titulo: erro.semConexao
            ? 'Sem conexão com a internet'
            : 'Não foi possível validar',
        texto: erro.semConexao
            ? 'Confira o Wi-Fi ou os dados móveis do celular e tente de novo.'
            : erro.mensagem,
        dica: erro.semConexao
            ? 'Sem internet, sua tag NFC continua funcionando no terminal.'
            : null,
        destaque: false,
        rotuloAcao: 'Tentar novamente',
        iconeAcao: Icons.refresh,
        onAcao: _lerDeNovo,
        rotuloVoltar: 'Voltar ao início',
        iconeVoltar: Icons.home_outlined,
        onVoltar: _voltar,
      );
    }
    // A chamada já começou; o Voltar do celular não interrompe.
    return const PopScope(canPop: false, child: _Verificando());
  }
}

class _Verificando extends StatelessWidget {
  const _Verificando();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 56,
                    child: CircularProgressIndicator(strokeWidth: 5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verificando seu acesso…',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Isso leva só alguns segundos.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _Etapa(feita: true, texto: 'QR Code lido'),
                  const _Etapa(
                    feita: false,
                    texto: 'Conferindo sua autorização e se você está perto',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Etapa extends StatelessWidget {
  const _Etapa({required this.feita, required this.texto});

  final bool feita;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 22,
            child: feita
                ? Icon(Icons.check_circle, color: colorScheme.primary, size: 22)
                : const CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
