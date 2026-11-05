import 'package:flutter/material.dart';

import '../../controllers/usuarios_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/usuario.dart';
import '../../models/usuario_cadastro.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/tela_base.dart';
import 'autorizacao_form_view.dart';
import 'usuario_form_view.dart';

/// Visitantes (equipe): a API não tem rota única, então são dois passos, com
/// os formulários que já existem. Passo 1: cria a pessoa (POST /users). Passo
/// 2: cria a autorização (POST /authorizations). Se a pessoa sair no passo 2,
/// o visitante fica na lista e o toque nele retoma daí.
class VisitantesView extends StatefulWidget {
  VisitantesView({super.key, UsuariosController? controller})
    : controller = controller ?? UsuariosController();

  final UsuariosController controller;

  @override
  State<VisitantesView> createState() => _VisitantesViewState();
}

class _VisitantesViewState extends State<VisitantesView>
    with CarregaDados<List<UsuarioCadastro>, VisitantesView> {
  UsuariosController get controller => widget.controller;

  @override
  Future<List<UsuarioCadastro>> buscar() =>
      controller.listar(perfil: Perfil.visitante);

  Future<void> _novo() async {
    final visitante = await Navigator.of(context).push<UsuarioCadastro>(
      MaterialPageRoute(
        builder: (_) => UsuarioFormView(
          perfilFixo: Perfil.visitante,
          rotuloSalvar: 'Continuar',
          controller: controller,
        ),
      ),
    );
    if (visitante == null || !mounted) return;
    await carregar();
    if (mounted) await _liberar(visitante);
  }

  Future<void> _liberar(UsuarioCadastro visitante) =>
      Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AutorizacaoFormView(pessoaFixa: visitante),
        ),
      );

  List<Widget> _lista(List<UsuarioCadastro> visitantes) {
    if (visitantes.isEmpty) {
      return const [
        EstadoVazio(
          icone: Icons.schedule,
          titulo: 'Nenhum visitante cadastrado',
          texto: 'Cadastre quem vai chegar e libere o acesso por tempo limitado.',
        ),
      ];
    }
    return [
      for (final visitante in visitantes)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: CircleAvatar(
                child: Text(Formato.iniciais(visitante.nome)),
              ),
              title: Text(visitante.nome),
              subtitle: Text(
                'CPF ${Formato.cpfMascarado(visitante.cpf)}\n'
                'Toque para liberar um acesso',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _liberar(visitante),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Visitantes',
      subtitulo: 'Acessos por tempo limitado',
      onAtualizar: carregar,
      botaoFlutuante: FloatingActionButton.extended(
        onPressed: _novo,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Novo visitante'),
      ),
      filhos: conteudo(_lista),
    );
  }
}
