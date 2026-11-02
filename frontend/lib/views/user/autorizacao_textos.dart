import '../../models/autorizacao.dart';

/// Textos de uma autorização como as telas U7 e U8 mostram.
extension TextosDaAutorizacao on Autorizacao {
  /// "Das 08:00 às 18:00".
  String get horario => 'Das $horaInicio às $horaFim';

  /// "01/10/2026 a 31/10/2026" (U8).
  String get periodo => '${_data(dataInicio)} a ${_data(dataFim)}';

  /// Período do cartão (U7): "01/10 a 31/10/2026" ou, num dia só,
  /// "Somente hoje, 14/10".
  String periodoCurto(DateTime hoje) {
    if (_mesmoDia(dataInicio, dataFim)) {
      return _mesmoDia(dataInicio, hoje)
          ? 'Somente hoje, ${_diaMes(dataInicio)}'
          : 'Somente em ${_data(dataInicio)}';
    }
    final inicio = dataInicio.year == dataFim.year
        ? _diaMes(dataInicio)
        : _data(dataInicio);
    return '$inicio a ${_data(dataFim)}';
  }

  /// "7 de 10 usos restantes" (U7).
  String get usos => maxUsos == 1
      ? '$usosRestantes de 1 uso restante'
      : '$usosRestantes de $maxUsos usos restantes';

  /// "7 de 10 restantes" (U8, embaixo de "Usos").
  String get restantes => maxUsos == 1
      ? '$usosRestantes de 1 restante'
      : '$usosRestantes de $maxUsos restantes';

  /// Frase embaixo do selo na U8, ex.: "Você pode entrar hoje até 18:00.".
  String quandoEntrar(DateTime agora) => switch (situacao) {
    SituacaoAutorizacao.ativa => _quandoEntrarHoje(agora),
    SituacaoAutorizacao.agendada =>
      'Você poderá entrar a partir de ${_data(dataInicio)}.',
    SituacaoAutorizacao.esgotada =>
      'Você já usou todos os usos. Peça mais à portaria.',
    SituacaoAutorizacao.expirada => 'Terminou em ${_data(dataFim)}.',
    SituacaoAutorizacao.cancelada => switch (canceladaEm) {
      final em? =>
        'A portaria cancelou esta autorização em ${_data(em.toLocal())}.',
      null => 'A portaria cancelou esta autorização.',
    },
  };

  String _quandoEntrarHoje(DateTime agora) {
    // "HH:MM" com zero à esquerda: dá para comparar como texto.
    final hora = _hora(agora);
    if (dentroDoHorario(agora)) {
      // Janela que passa da meia-noite, ainda antes dela: vai até amanhã.
      final ateAmanha =
          horaInicio.compareTo(horaFim) > 0 && hora.compareTo(horaInicio) >= 0;
      return ateAmanha
          ? 'Você pode entrar até $horaFim de amanhã.'
          : 'Você pode entrar hoje até $horaFim.';
    }
    if (hora.compareTo(horaInicio) < 0) {
      return 'Hoje você pode entrar a partir das $horaInicio.';
    }
    return _mesmoDia(dataFim, agora)
        ? 'O horário de hoje já acabou.'
        : 'Amanhã você pode entrar a partir das $horaInicio.';
  }
}

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _diaMes(DateTime data) =>
    '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}';

String _data(DateTime data) => '${_diaMes(data)}/${data.year}';

String _hora(DateTime data) =>
    '${_doisDigitos(data.hour)}:${_doisDigitos(data.minute)}';

bool _mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
