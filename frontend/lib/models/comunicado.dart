import '../core/constants/formato.dart';

/// Aviso da administração para quem usa o prédio, como vem no
/// GET /announcements.
class Comunicado {
  const Comunicado({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.criadoEm,
    this.autor,
  });

  factory Comunicado.fromJson(Map<String, dynamic> json) => Comunicado(
    id: json['id'] as String,
    titulo: json['titulo'] as String,
    mensagem: json['mensagem'] as String,
    criadoEm: DateTime.parse(json['createdAt'] as String).toLocal(),
    // Vem null quando a conta de quem escreveu foi apagada.
    autor: (json['autor'] as Map<String, dynamic>?)?['nome'] as String?,
  );

  /// Limites do POST /announcements.
  static const maxTitulo = 120;
  static const maxMensagem = 2000;

  final String id;
  final String titulo;
  final String mensagem;

  /// Já no horário do celular.
  final DateTime criadoEm;

  /// Nome de quem publicou.
  final String? autor;

  /// "Agora há pouco", "Há 5 min", "Hoje às 09:12", "Ontem às 18:00",
  /// "14/10" ou, de outro ano, "14/10/2025".
  String quando(DateTime agora) {
    final passou = agora.difference(criadoEm);
    if (passou.inMinutes < 1) return 'Agora há pouco';
    if (passou.inMinutes < 60) return 'Há ${passou.inMinutes} min';
    final dia = DateTime(criadoEm.year, criadoEm.month, criadoEm.day);
    final hoje = DateTime(agora.year, agora.month, agora.day);
    // Arredonda: com horário de verão, um dia pode ter 23 ou 25 horas.
    final dias = (hoje.difference(dia).inHours / 24).round();
    if (dias == 0) return 'Hoje às ${Formato.hora(criadoEm)}';
    if (dias == 1) return 'Ontem às ${Formato.hora(criadoEm)}';
    return criadoEm.year == agora.year
        ? Formato.diaMes(criadoEm)
        : Formato.data(criadoEm);
  }
}
