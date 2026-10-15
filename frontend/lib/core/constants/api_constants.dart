/// Endereço da API Express.
abstract final class ApiConstants {
  /// Para apontar para outro endereço sem mudar o código:
  /// flutter run --dart-define=API_URL=http://192.168.0.10:3000
  /// (no emulador Android, o "localhost" do computador é http://10.0.2.2:3000)
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const timeout = Duration(seconds: 10);
}
