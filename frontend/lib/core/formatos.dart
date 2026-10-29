/// Formatação de datas e documentos para as telas.
/// Feito à mão para não depender da inicialização de locale do intl.
abstract final class Formatos {
  static String _dois(int n) => n.toString().padLeft(2, '0');

  /// DateTime -> "14/10".
  static String diaMes(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}';

  /// DateTime -> "14/10/2026".
  static String data(DateTime d) => '${diaMes(d)}/${d.year}';

  /// DateTime -> "09:12".
  static String hora(DateTime d) => '${_dois(d.hour)}:${_dois(d.minute)}';

  /// "2026-10-14" (como a API escreve) -> "14/10/2026".
  static String dataIsoParaBr(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  /// DateTime -> "2026-10-14".
  static String dataIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_dois(d.month)}-${_dois(d.day)}';

  /// "2026-10-14" -> DateTime local à meia-noite.
  static DateTime? daDataIso(String iso) {
    final p = iso.split('-');
    if (p.length != 3) return null;
    final a = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
    if (a == null || m == null || d == null) return null;
    return DateTime(a, m, d);
  }

  /// "09:30" -> 9:30 como [Duration], para os seletores de hora.
  static ({int hora, int minuto}) daHora(String hhmm) {
    final p = hhmm.split(':');
    return (
      hora: int.tryParse(p.first) ?? 0,
      minuto: p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0,
    );
  }

  /// 6 e 30 -> "06:30".
  static String horaHm(int hora, int minuto) => '${_dois(hora)}:${_dois(minuto)}';

  /// "12345678900" -> "123.456.789-00".
  static String cpf(String numeros) {
    if (numeros.length != 11) return numeros;
    return '${numeros.substring(0, 3)}.${numeros.substring(3, 6)}.'
        '${numeros.substring(6, 9)}-${numeros.substring(9)}';
  }

  /// Esconde o começo e o fim, como no docs/Design.pdf: "•••.456.789-••".
  static String cpfMascarado(String numeros) {
    if (numeros.length != 11) return numeros;
    return '•••.${numeros.substring(3, 6)}.${numeros.substring(6, 9)}-••';
  }

  /// UID da tag -> final de 4 caracteres, ex.: "4F2A".
  static String finalDaTag(String uid) =>
      uid.length <= 4 ? uid : uid.substring(uid.length - 4);

  /// Só os números, para mandar o CPF para a API.
  static String somenteNumeros(String texto) =>
      texto.replaceAll(RegExp(r'\D'), '');

  /// "Há 2 min", "há 3 h" ou a data, para o último sinal do terminal.
  static String hojeOuData(DateTime d, DateTime agora) {
    final local = d.toLocal();
    final mesmoDia =
        local.year == agora.year &&
        local.month == agora.month &&
        local.day == agora.day;
    return mesmoDia ? 'hoje, ${hora(local)}' : '${data(local)}, ${hora(local)}';
  }
}
