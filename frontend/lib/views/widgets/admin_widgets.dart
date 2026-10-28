import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/admin_models.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../user/login_view.dart';

/// Moldura das telas do admin, como no docs/Design.pdf: "Voltar" com texto
/// no topo, título grande e uma linha de apoio embaixo dele.
class TelaAdmin extends StatelessWidget {
  const TelaAdmin({
    super.key,
    required this.titulo,
    required this.corpo,
    this.subtitulo,
    this.botaoFlutuante,
  });

  final String titulo;
  final String? subtitulo;
  final Widget corpo;
  final Widget? botaoFlutuante;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 132,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Voltar'),
          ),
        ),
      ),
      floatingActionButton: botaoFlutuante,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: textTheme.headlineMedium),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitulo!, style: textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            Expanded(child: corpo),
          ],
        ),
      ),
    );
  }
}

/// Mostra "carregando", o erro com "Tentar novamente" ou o conteúdo.
/// Para recarregar de fora (filtro mudou, voltou de uma edição), troque a
/// `key` do widget: ele carrega de novo do zero.
class CarregaDados<T> extends StatefulWidget {
  const CarregaDados({
    super.key,
    required this.carregar,
    required this.construir,
    this.mensagem = 'Carregando…',
  });

  final Future<T> Function() carregar;
  final Widget Function(BuildContext context, T dados) construir;
  final String mensagem;

  @override
  State<CarregaDados<T>> createState() => _CarregaDadosState<T>();
}

class _CarregaDadosState<T> extends State<CarregaDados<T>> {
  late Future<T> _futuro = widget.carregar();

  void _tentarDeNovo() {
    // O bloco do setState não pode devolver o Future: por isso as chaves.
    setState(() {
      _futuro = widget.carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _Carregando(mensagem: widget.mensagem);
        }
        if (snapshot.hasError) {
          return ErroDeCarga(
            erro: snapshot.error!,
            onTentarDeNovo: _tentarDeNovo,
          );
        }
        return widget.construir(context, snapshot.data as T);
      },
    );
  }
}

class _Carregando extends StatelessWidget {
  const _Carregando({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(mensagem, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Texto do erro de uma [ApiException] ou genérico para qualquer outro.
String mensagemDoErro(Object erro) =>
    erro is ApiException ? erro.mensagem : 'Algo deu errado. Tente de novo.';

/// Erro ao carregar uma lista (sem internet, sem permissão, sessão vencida).
class ErroDeCarga extends StatelessWidget {
  const ErroDeCarga({
    super.key,
    required this.erro,
    required this.onTentarDeNovo,
  });

  final Object erro;
  final VoidCallback onTentarDeNovo;

  Future<void> _entrarDeNovo(BuildContext context) async {
    final navigator = Navigator.of(context);
    await AuthService.instancia.sair();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final vencida = erro is ApiException && (erro as ApiException).naoAutenticado;
    final semConexao = erro is ApiException && (erro as ApiException).semConexao;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                  child: Icon(
                    semConexao ? Icons.wifi_off : Icons.error_outline,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                mensagemDoErro(erro),
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              if (vencida)
                FilledButton.icon(
                  onPressed: () => _entrarDeNovo(context),
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar de novo'),
                )
              else
                FilledButton.icon(
                  onPressed: onTentarDeNovo,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista vazia (A12): ícone, o que houve e, se der, o que fazer.
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.texto,
    this.rotuloAcao,
    this.iconeAcao,
    this.onAcao,
  });

  final IconData icone;
  final String titulo;
  final String texto;
  final String? rotuloAcao;
  final IconData? iconeAcao;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurfaceVariant,
              child: Icon(icone, size: 32),
            ),
            const SizedBox(height: 16),
            Text(titulo, style: textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(texto, style: textTheme.bodyMedium, textAlign: TextAlign.center),
            if (rotuloAcao != null && onAcao != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onAcao,
                icon: Icon(iconeAcao ?? Icons.refresh),
                label: Text(rotuloAcao!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Selo colorido (Ativa, Negado, Visitante…).
class Selo extends StatelessWidget {
  const Selo({super.key, required this.texto, required this.tom, this.icone});

  final String texto;
  final TomSelo tom;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final (cor, fundo) = switch (tom) {
      TomSelo.sucesso => (status.onSuccessContainer, status.successContainer),
      TomSelo.atencao => (status.onWarningContainer, status.warningContainer),
      TomSelo.perigo => (colorScheme.onErrorContainer, colorScheme.errorContainer),
      TomSelo.marca => (
        colorScheme.onPrimaryContainer,
        colorScheme.primaryContainer,
      ),
      TomSelo.neutro => (
        colorScheme.onSurfaceVariant,
        colorScheme.surfaceContainerHighest,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 16, color: cor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cor),
            ),
          ),
        ],
      ),
    );
  }
}

enum TomSelo { sucesso, atencao, perigo, marca, neutro }

/// Selo da situação de uma autorização.
class SeloSituacao extends StatelessWidget {
  const SeloSituacao({super.key, required this.situacao});

  final SituacaoAutorizacao situacao;

  @override
  Widget build(BuildContext context) {
    final (tom, icone) = switch (situacao) {
      SituacaoAutorizacao.ativa => (TomSelo.sucesso, Icons.check_circle),
      SituacaoAutorizacao.agendada => (TomSelo.marca, Icons.event),
      SituacaoAutorizacao.expirada => (TomSelo.neutro, Icons.history),
      SituacaoAutorizacao.esgotada => (TomSelo.atencao, Icons.warning_amber),
      SituacaoAutorizacao.cancelada => (TomSelo.perigo, Icons.cancel),
    };
    return Selo(texto: situacao.rotulo, tom: tom, icone: icone);
  }
}

/// Linha "ícone + texto" dos cartões (período, horário, usos).
class LinhaInfo extends StatelessWidget {
  const LinhaInfo({super.key, required this.icone, required this.texto, this.cor});

  final IconData icone;
  final String texto;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cor = this.cor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: textTheme.bodyMedium?.copyWith(color: cor)),
          ),
        ],
      ),
    );
  }
}

/// Mostra o erro de uma ação (salvar, cancelar…) numa faixa de aviso.
void avisar(BuildContext context, String texto, {bool erro = false}) {
  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          texto,
          style: TextStyle(color: erro ? colorScheme.onError : null),
        ),
        backgroundColor: erro ? colorScheme.error : null,
      ),
    );
}

/// Pergunta de confirmação (A10): o que vai acontecer e dois botões com
/// texto. Devolve true só quando a pessoa confirma.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String rotuloSim,
  required String rotuloNao,
  IconData icone = Icons.warning_amber_rounded,
}) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(icone, color: Theme.of(context).colorScheme.error, size: 36),
      title: Text(titulo),
      content: Text(texto),
      actionsOverflowDirection: VerticalDirection.down,
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(rotuloNao),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(rotuloSim),
        ),
      ],
    ),
  );
  return resposta ?? false;
}
