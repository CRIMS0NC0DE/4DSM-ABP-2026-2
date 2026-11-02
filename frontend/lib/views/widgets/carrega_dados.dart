import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../user/login_view.dart';
import 'cartao_erro.dart';
import 'estado_vazio.dart';
import 'tela_carregando.dart';

/// 401: esquece o token e volta ao login, como o Sair dos menus. Um lugar só
/// para as telas (F2 do backlog). Cadastro desativado não é sessão vencida: o
/// login abre explicando o motivo. [sair] troca o Sair padrão.
Future<void> voltarAoLogin(
  BuildContext context,
  ApiException erro, {
  Future<void> Function()? sair,
}) {
  final desativado = erro.cadastroDesativado;
  return TelaCarregando.abrir(
    context,
    mensagem: desativado
        ? 'Voltando ao login…'
        : 'Sua sessão venceu. Voltando ao login…',
    tarefa: () async {
      await (sair ?? AuthService.instancia.sair)();
      return LoginView(aviso: desativado ? erro.mensagem : null);
    },
  );
}

void avisar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));
}

/// Trata o erro de uma ação (salvar, cancelar...): 401 volta ao login e o
/// resto vira aviso. Nos formulários, mostre antes os erros de [ApiException.campos].
Future<void> tratarErro(BuildContext context, ApiException erro) async {
  if (erro.naoAutenticado) {
    await voltarAoLogin(context, erro);
  } else {
    avisar(context, erro.mensagem);
  }
}

/// Carrega os dados da tela ao abrir e guarda os estados da U7: carregando,
/// erro e pronto. A tela só implementa [buscar] e monta o conteúdo com
/// [conteudo].
mixin CarregaDados<T, W extends StatefulWidget> on State<W> {
  /// null enquanto carrega pela primeira vez.
  T? dados;
  ApiException? erro;

  Future<T> buscar();

  @override
  void initState() {
    super.initState();
    carregar();
  }

  /// Busca sem apagar o que está na tela (puxar para atualizar, voltar de um
  /// formulário). Se falhar com a lista já na tela, só avisa.
  Future<void> carregar() async {
    try {
      final novos = await buscar();
      if (!mounted) return;
      setState(() {
        dados = novos;
        erro = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.naoAutenticado) {
        await voltarAoLogin(context, e);
      } else if (dados == null) {
        setState(() => erro = e);
      } else {
        avisar(context, e.mensagem);
      }
    }
  }

  /// Volta ao carregando e busca de novo ("Tentar novamente", trocar filtro).
  void recarregar() {
    setState(() {
      dados = null;
      erro = null;
    });
    carregar();
  }

  /// Os filhos da tela: o erro, o carregando ou o que [pronto] montar.
  List<Widget> conteudo(List<Widget> Function(T dados) pronto) {
    if (erro case final e?) {
      return [
        CartaoErro(
          icone: e.semConexao ? Icons.wifi_off : Icons.error_outline,
          titulo: e.semConexao
              ? 'Sem conexão com a internet'
              : 'Não foi possível carregar',
          texto: e.semConexao
              ? 'Confira o Wi-Fi ou os dados móveis do celular e tente de novo.'
              : e.mensagem,
          onTentarDeNovo: recarregar,
        ),
      ];
    }
    final atuais = dados;
    if (atuais == null) return const [Carregando()];
    return pronto(atuais);
  }
}
