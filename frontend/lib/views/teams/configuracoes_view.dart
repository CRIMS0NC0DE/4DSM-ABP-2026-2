import 'package:flutter/material.dart';

import '../../controllers/configuracoes_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/configuracoes.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/tela_base.dart';

/// Configurações (sem tela no design), só do admin: as regras do condomínio,
/// salvas com PATCH /settings, e embaixo os valores fixos do servidor.
class ConfiguracoesView extends StatefulWidget {
  ConfiguracoesView({super.key, ConfiguracoesController? controller})
    : controller = controller ?? ConfiguracoesController();

  final ConfiguracoesController controller;

  @override
  State<ConfiguracoesView> createState() => _ConfiguracoesViewState();
}

class _ConfiguracoesViewState extends State<ConfiguracoesView>
    with CarregaDados<Configuracoes, ConfiguracoesView> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _contato = TextEditingController();
  final _usos = TextEditingController();
  final _dias = TextEditingController();
  var _podeConvidar = true;
  var _salvando = false;

  /// Erros de cada campo que a API devolveu no 400.
  Map<String, List<String>> _errosDaApi = const {};

  @override
  void dispose() {
    _nome.dispose();
    _contato.dispose();
    _usos.dispose();
    _dias.dispose();
    super.dispose();
  }

  // Sem "puxar para atualizar": buscar de novo apagaria o que o admin digitou.
  @override
  Future<Configuracoes> buscar() async {
    final atuais = await widget.controller.carregar();
    if (mounted) _preencher(atuais);
    return atuais;
  }

  void _preencher(Configuracoes c) {
    _nome.text = c.nomeCondominio;
    _contato.text = c.contatoPortaria;
    _usos.text = '${c.visitanteMaxUsos}';
    _dias.text = '${c.visitanteDiasMax}';
    _podeConvidar = c.moradorPodeConvidar;
  }

  String? _erroDaApi(String campo) => _errosDaApi[campo]?.first;

  String? _validarTexto(
    String? valor, {
    required String campo,
    required int maximo,
    required String vazio,
  }) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return vazio;
    if (texto.length > maximo) return 'Use até $maximo caracteres.';
    return _erroDaApi(campo);
  }

  String? _validarNumero(
    String? valor, {
    required String campo,
    required ({int min, int max}) faixa,
  }) {
    final numero = int.tryParse((valor ?? '').trim());
    if (numero == null || numero < faixa.min || numero > faixa.max) {
      return 'Use um número de ${faixa.min} a ${faixa.max}.';
    }
    return _erroDaApi(campo);
  }

  Future<void> _salvar() async {
    _errosDaApi = const {};
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final salvas = await widget.controller.salvar(
        nomeCondominio: _nome.text.trim(),
        contatoPortaria: _contato.text.trim(),
        moradorPodeConvidar: _podeConvidar,
        visitanteMaxUsos: int.parse(_usos.text.trim()),
        visitanteDiasMax: int.parse(_dias.text.trim()),
      );
      if (!mounted) return;
      setState(() {
        _preencher(salvas);
        dados = salvas;
      });
      avisar(context, 'Configurações salvas.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _errosDaApi = e.campos;
      // Erro de um campo que está na tela aparece embaixo dele; o resto vira
      // aviso.
      if (e.campos.isEmpty || _form.currentState!.validate()) {
        await tratarErro(context, e);
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  List<Widget> _formulario(Configuracoes atuais) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final atualizadoEm = atuais.atualizadoEm;
    final sistema = atuais.sistema;

    return [
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Condomínio', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            CampoTexto(
              rotulo: 'Nome do condomínio',
              controller: _nome,
              icone: Icons.apartment_outlined,
              validator: (v) => _validarTexto(
                v,
                campo: 'nomeCondominio',
                maximo: Configuracoes.maxNome,
                vazio: 'Informe o nome do condomínio.',
              ),
            ),
            const SizedBox(height: 20),
            CampoTexto(
              rotulo: 'Contato da portaria',
              controller: _contato,
              icone: Icons.phone_outlined,
              dica: 'Telefone e horário de atendimento',
              ajuda: 'Aparece na Ajuda do app, para todo mundo.',
              validator: (v) => _validarTexto(
                v,
                campo: 'contatoPortaria',
                maximo: Configuracoes.maxContato,
                vazio: 'Informe o contato da portaria.',
              ),
            ),
            const SizedBox(height: 28),
            Text('Visitantes dos moradores', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            SwitchListTile(
              value: _podeConvidar,
              onChanged: (v) => setState(() => _podeConvidar = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('Moradores podem cadastrar visitantes'),
              subtitle: const Text(
                'Desligado, só a portaria cadastra visitantes.',
              ),
            ),
            const SizedBox(height: 12),
            CampoTexto(
              rotulo: 'Usos por visita',
              controller: _usos,
              icone: Icons.repeat,
              ajuda: 'Quantas vezes o visitante passa na catraca, de 1 a 20.',
              teclado: TextInputType.number,
              validator: (v) => _validarNumero(
                v,
                campo: 'visitanteMaxUsos',
                faixa: Configuracoes.faixaUsos,
              ),
            ),
            const SizedBox(height: 20),
            CampoTexto(
              rotulo: 'Máximo de dias de uma visita',
              controller: _dias,
              icone: Icons.date_range_outlined,
              ajuda: 'Contando o primeiro e o último dia, de 1 a 30.',
              teclado: TextInputType.number,
              acao: TextInputAction.done,
              validator: (v) => _validarNumero(
                v,
                campo: 'visitanteDiasMax',
                faixa: Configuracoes.faixaDias,
              ),
            ),
          ],
        ),
      ),
      if (atualizadoEm != null) ...[
        const SizedBox(height: 16),
        Text(
          'Última alteração: ${Formato.data(atualizadoEm)} às '
          '${Formato.hora(atualizadoEm)}',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
      if (sistema != null) ...[
        const SizedBox(height: 28),
        Text('Do sistema', style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Ficam no servidor e não mudam pelo app.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _ValoresDoSistema(sistema: sistema),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Configurações',
      subtitulo: 'Regras do condomínio',
      rodape: dados == null
          ? null
          : BotaoAcao(
              rotulo: 'Salvar configurações',
              icone: Icons.check,
              carregando: _salvando,
              onTocar: _salvar,
            ),
      filhos: conteudo(_formulario),
    );
  }
}

/// Os valores de `sistema`, cada um com uma linha explicando.
class _ValoresDoSistema extends StatelessWidget {
  const _ValoresDoSistema({required this.sistema});

  final ConfiguracoesSistema sistema;

  @override
  Widget build(BuildContext context) {
    final linhas = [
      (
        Icons.public,
        'Fuso horário',
        sistema.fuso,
        'Datas e horários das autorizações e do histórico seguem este fuso.',
      ),
      (
        Icons.qr_code_2,
        'Troca do QR Code',
        'A cada ${sistema.qrTrocaSegundos} segundos',
        'O terminal da catraca mostra um QR novo nesse intervalo.',
      ),
      (
        Icons.timer_outlined,
        'Validade do QR Code',
        '${sistema.qrValidadeSegundos} segundos',
        'Depois disso, um QR escaneado não abre mais a catraca.',
      ),
      (
        Icons.radar,
        'Raio padrão',
        '${sistema.raioPadraoMetros} metros',
        'Cada catraca nova começa com essa distância máxima para usar o QR.',
      ),
    ];

    return Card(
      child: Column(
        children: [
          for (final (icone, titulo, valor, explicacao) in linhas)
            ListTile(
              leading: Icon(icone),
              title: Text('$titulo: $valor'),
              subtitle: Text(explicacao),
            ),
        ],
      ),
    );
  }
}
