import 'package:flutter/material.dart';

import '../../controllers/locais_controller.dart';
import '../../models/local.dart';
import '../../services/api_client.dart';
import '../../services/localizacao_service.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/tela_base.dart';

/// A6 · Local · localização: cria ou edita a catraca. O design mostra um mapa;
/// sem pacote de mapa no pubspec, começa com os campos e o "Usar minha
/// localização", que resolve para quem está ao lado da catraca.
class CatracaFormView extends StatefulWidget {
  CatracaFormView({
    super.key,
    this.catraca,
    required this.portaId,
    required this.caminho,
    LocaisController? controller,
    LocalizacaoService? localizacao,
  }) : controller = controller ?? LocaisController(),
       localizacao = localizacao ?? LocalizacaoService.instancia;

  /// null cria uma nova.
  final Catraca? catraca;
  final String portaId;

  /// "Portaria Principal › Porta A".
  final String caminho;
  final LocaisController controller;
  final LocalizacaoService localizacao;

  @override
  State<CatracaFormView> createState() => _CatracaFormViewState();
}

class _CatracaFormViewState extends State<CatracaFormView> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.catraca?.nome);
  late final _latitude = TextEditingController(
    text: widget.catraca?.latitude.toString(),
  );
  late final _longitude = TextEditingController(
    text: widget.catraca?.longitude.toString(),
  );
  late final _raio = TextEditingController(
    text: '${widget.catraca?.raioMetros ?? 100}',
  );
  var _salvando = false;
  var _localizando = false;

  @override
  void dispose() {
    _nome.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _raio.dispose();
    super.dispose();
  }

  /// Aceita vírgula, que é o que o teclado em português costuma ter.
  double? _numero(String? texto) =>
      double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

  String? _validarFaixa(String? texto, double limite, String nome) {
    final valor = _numero(texto);
    return valor == null || valor.abs() > limite
        ? '$nome vai de -${limite.toInt()} a ${limite.toInt()}.'
        : null;
  }

  Future<void> _usarMinhaLocalizacao() async {
    setState(() => _localizando = true);
    final posicao = await widget.localizacao.posicaoAtual();
    if (!mounted) return;
    setState(() {
      _localizando = false;
      if (posicao != null) {
        _latitude.text = posicao.latitude.toString();
        _longitude.text = posicao.longitude.toString();
      }
    });
    if (posicao == null) {
      avisar(context, 'Não conseguimos sua localização. Digite os números.');
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final catraca = widget.catraca;
      if (catraca == null) {
        await widget.controller.criarCatraca(
          nome: _nome.text.trim(),
          portaId: widget.portaId,
          latitude: _numero(_latitude.text)!,
          longitude: _numero(_longitude.text)!,
          raioMetros: int.parse(_raio.text.trim()),
        );
      } else {
        await widget.controller.atualizarCatraca(
          catraca.id,
          nome: _nome.text.trim(),
          latitude: _numero(_latitude.text)!,
          longitude: _numero(_longitude.text)!,
          raioMetros: int.parse(_raio.text.trim()),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const teclado = TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    );

    return TelaBase(
      titulo: widget.catraca == null ? 'Nova catraca' : 'Editar catraca',
      subtitulo: widget.caminho,
      rodape: BotaoAcao(
        rotulo: 'Salvar local',
        icone: Icons.check,
        carregando: _salvando,
        onTocar: _salvar,
      ),
      filhos: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoTexto(
                rotulo: 'Nome',
                controller: _nome,
                icone: Icons.edit_outlined,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe o nome.' : null,
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'Latitude',
                controller: _latitude,
                icone: Icons.explore_outlined,
                dica: '-23.3053',
                teclado: teclado,
                validator: (v) => _validarFaixa(v, 90, 'A latitude'),
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'Longitude',
                controller: _longitude,
                icone: Icons.explore_outlined,
                dica: '-45.9658',
                teclado: teclado,
                validator: (v) => _validarFaixa(v, 180, 'A longitude'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _localizando ? null : _usarMinhaLocalizacao,
                icon: const Icon(Icons.my_location),
                label: Text(
                  _localizando ? 'Localizando…' : 'Usar minha localização',
                ),
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'Raio permitido (metros)',
                controller: _raio,
                icone: Icons.radar,
                ajuda: 'A pessoa precisa estar a essa distância para passar.',
                teclado: TextInputType.number,
                acao: TextInputAction.done,
                validator: (v) {
                  final raio = int.tryParse((v ?? '').trim());
                  return raio == null || raio < 10 || raio > 1000
                      ? 'O raio vai de 10 a 1000 metros.'
                      : null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
