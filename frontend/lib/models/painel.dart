import 'evento_acesso.dart';

class Painel {
  const Painel({
    required this.acessosHoje,
    required this.negadosHoje,
    required this.autorizacoesAtivas,
    required this.negadosRecentes,
  });

  factory Painel.fromJson(Map<String, dynamic> json) => Painel(
    acessosHoje: json['acessosHoje'] as int,
    negadosHoje: json['negadosHoje'] as int,
    autorizacoesAtivas: json['autorizacoesAtivas'] as int,
    negadosRecentes: [
      for (final item in json['negadosRecentes'] as List<dynamic>)
        EventoAcesso.fromJson(item as Map<String, dynamic>),
    ],
  );

  final int acessosHoje;
  final int negadosHoje;

  /// Só as que valem hoje: não conta as agendadas nem as sem usos.
  final int autorizacoesAtivas;
  final List<EventoAcesso> negadosRecentes;
}