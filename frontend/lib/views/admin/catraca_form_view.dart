import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../../services/localizacao_service.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_texto.dart';

/// Cadastro e edição de catraca (A6 · RF02): nome, ponto no mapa e raio em
/// que o celular precisa estar para o QR valer. Só o admin salva.
/// O ponto vem das coordenadas digitadas ou da posição do celular de quem
/// está em frente à catraca. Fecha devolvendo true quando salva.
class CatracaFormView extends StatefulWidget {
  const CatracaFormView({
    super.key,
    this.catraca,
    this.doorId,
    AdminService? servico,
    LocalizacaoService? localizacao,
  }) : _servico = servico,
       _localizacao = localizacao;

  /// Null cadastra uma nova na porta [doorId].
  final Catraca? catraca;
  final String? doorId;
  final AdminService? _servico;
  final LocalizacaoService? _localizacao;

  @override
  State<CatracaFormView> createState() => _CatracaFormViewState();
}

class _CatracaFormViewState extends State<CatracaFormView> {
  late final AdminService _servico = widget._servico ?? AdminService.instancia;
  late final LocalizacaoService _localizacao =
      widget._localizacao ?? LocalizacaoService.instancia;
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
  var _buscandoPosicao = false;

  bool get _nova => widget.catraca == null;

  @override
  void dispose() {
    for (final c in [_nome, _latitude, _longitude, _raio]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _numero(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  String? _coordenada(String? v, double limite, String nome) {
    final n = _numero(v ?? '');
    if (n == null) return 'Informe a $nome';
    return n.abs() > limite ? 'A $nome vai de -$limite a $limite' : null;
  }

  Future<void> _usarMinhaPosicao() async {
    setState(() => _buscandoPosicao = true);
    final posicao = await _localizacao.posicaoAtual();
    if (!mounted) return;
    setState(() => _buscandoPosicao = false);
    if (posicao == null) {
      avisar(
        context,
        'Não consegui sua localização. Permita o acesso no celular ou digite as coordenadas.',
        erro: true,
      );
      return;
    }
    setState(() {
      _latitude.text = posicao.latitude.toStringAsFixed(6);
      _longitude.text = posicao.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _salvar() async {
    if (!_servico.souAdmin) {
      avisar(context, 'Só o administrador altera locais.', erro: true);
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final lat = _numero(_latitude.text)!;
      final lon = _numero(_longitude.text)!;
      final raio = int.parse(_raio.text.trim());
      if (_nova) {
        await _servico.criarCatraca(
          nome: _nome.text.trim(),
          doorId: widget.doorId!,
          latitude: lat,
          longitude: lon,
          raioMetros: raio,
        );
      } else {
        await _servico.atualizarCatraca(
          widget.catraca!.id,
          nome: _nome.text.trim(),
          latitude: lat,
          longitude: lon,
          raioMetros: raio,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      avisar(context, erro.mensagem, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const teclado = TextInputType.numberWithOptions(decimal: true, signed: true);
    return TelaAdmin(
      titulo: _nova ? 'Nova catraca' : 'Editar catraca',
      corpo: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            CampoTexto(
              rotulo: 'Nome',
              controller: _nome,
              icone: Icons.qr_code_2,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            CampoTexto(
              rotulo: 'Latitude',
              controller: _latitude,
              icone: Icons.location_on_outlined,
              teclado: teclado,
              validator: (v) => _coordenada(v, 90, 'latitude'),
            ),
            const SizedBox(height: 16),
            CampoTexto(
              rotulo: 'Longitude',
              controller: _longitude,
              icone: Icons.location_on_outlined,
              teclado: teclado,
              validator: (v) => _coordenada(v, 180, 'longitude'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _buscandoPosicao ? null : _usarMinhaPosicao,
                icon: _buscandoPosicao
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Usar minha localização'),
              ),
            ),
            const SizedBox(height: 8),
            CampoTexto(
              rotulo: 'Raio permitido (metros)',
              controller: _raio,
              icone: Icons.radar,
              teclado: TextInputType.number,
              acao: TextInputAction.done,
              ajuda: 'O celular precisa estar a até esta distância da catraca. De 10 a 1000 m.',
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null) return 'Informe o raio em metros';
                return n < 10 || n > 1000 ? 'O raio vai de 10 a 1000 m' : null;
              },
            ),
            const SizedBox(height: 24),
            BotaoAcao(
              rotulo: _nova ? 'Cadastrar catraca' : 'Salvar local',
              icone: Icons.check,
              carregando: _salvando,
              onTocar: _salvar,
            ),
          ],
        ),
      ),
    );
  }
}
