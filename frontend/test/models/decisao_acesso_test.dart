import 'package:flutter_test/flutter_test.dart';
import 'package:public/models/decisao_acesso.dart';

void main() {
  test('Lê o acesso liberado como a API devolve', () {
    final decisao = DecisaoAcesso.fromJson({
      'liberado': true,
      'titulo': 'Acesso liberado',
      'catraca': {
        'id': '00000000-0000-4000-8000-000000000004',
        'nome': 'Catraca 1',
        'caminho': 'FATEC Jacareí › Portaria Principal › Porta A',
      },
      'usosRestantes': 999,
      'distanciaMetros': 12,
      'eventoId': 'evento-1',
      'em': '2026-10-25T17:30:00.000Z',
    });

    expect(decisao.liberado, isTrue);
    expect(decisao.motivo, isNull);
    expect(decisao.oQueFazer, isNull);
    expect(decisao.titulo, 'Acesso liberado');
    expect(decisao.catraca?.nome, 'Catraca 1');
    expect(
      decisao.catraca?.caminho,
      'FATEC Jacareí › Portaria Principal › Porta A',
    );
    expect(decisao.usosRestantes, 999);
    expect(decisao.distanciaMetros, 12);
    expect(decisao.eventoId, 'evento-1');
    expect(decisao.em, DateTime.utc(2026, 10, 25, 17, 30));
  });

  test('Lê o acesso negado com o motivo e o que fazer', () {
    final decisao = DecisaoAcesso.fromJson({
      'liberado': false,
      'motivo': 'LONGE_DO_TERMINAL',
      'titulo': 'Você está longe da catraca',
      'oQueFazer': 'Chegue mais perto da catraca e tente de novo.',
      'catraca': {'id': 'c1', 'nome': 'Catraca 1', 'caminho': 'A › B › C'},
      'distanciaMetros': 1043,
      'eventoId': 'evento-2',
      'em': '2026-10-25T17:30:00.000Z',
    });

    expect(decisao.liberado, isFalse);
    expect(decisao.motivo, 'LONGE_DO_TERMINAL');
    expect(decisao.titulo, 'Você está longe da catraca');
    expect(decisao.oQueFazer, 'Chegue mais perto da catraca e tente de novo.');
    expect(decisao.distanciaMetros, 1043);
    expect(decisao.usosRestantes, isNull);
    expect(decisao.semLocalizacao, isFalse);
  });

  test('QR inválido vem sem catraca, usos e distância', () {
    final decisao = DecisaoAcesso.fromJson({
      'liberado': false,
      'motivo': 'QR_INVALIDO',
      'titulo': 'QR Code não reconhecido',
      'oQueFazer': 'Escaneie o QR que aparece na tela da catraca.',
      'eventoId': 'evento-3',
      'em': '2026-10-25T17:30:00.000Z',
    });

    expect(decisao.catraca, isNull);
    expect(decisao.usosRestantes, isNull);
    expect(decisao.distanciaMetros, isNull);
  });

  test('Sem a posição do celular, a decisão pede a E8', () {
    final decisao = DecisaoAcesso.fromJson({
      'liberado': false,
      'motivo': 'LOCALIZACAO_AUSENTE',
      'titulo': 'Não conseguimos sua localização',
      'oQueFazer': 'Permita a localização no celular e tente de novo.',
      'eventoId': 'evento-4',
      'em': '2026-10-25T17:30:00.000Z',
    });

    expect(decisao.semLocalizacao, isTrue);
  });
}
