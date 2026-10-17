import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/usuario.dart';

/// Quem está logado e o token (JWT) que a API devolveu no login.
/// Fica guardado no armazenamento seguro do celular, para não pedir login
/// toda vez que o app abre. O token vale 8 h (JWT_EXPIRES_IN do backend).
class SessaoService {
  SessaoService({
    FlutterSecureStorage? armazenamento,
    DateTime Function()? agora,
  }) : _armazenamento = armazenamento ?? const FlutterSecureStorage(),
       _agora = agora ?? DateTime.now;

  /// A mesma para o app inteiro.
  static final instancia = SessaoService();

  static const _chaveToken = 'passe.token';
  static const _chaveUsuario = 'passe.usuario';

  final FlutterSecureStorage _armazenamento;
  final DateTime Function() _agora;

  String? _token;
  Usuario? _usuario;

  String? get token => _token;
  Usuario? get usuario => _usuario;

  Future<void> iniciar(String token, Usuario usuario) async {
    _token = token;
    _usuario = usuario;
    await _armazenamento.write(key: _chaveToken, value: token);
    await _armazenamento.write(
      key: _chaveUsuario,
      value: jsonEncode(usuario.toJson()),
    );
  }

  /// Volta a sessão guardada, se o token ainda não venceu.
  /// Devolve null quando precisa entrar de novo.
  Future<Usuario?> restaurar() async {
    try {
      final token = await _armazenamento.read(key: _chaveToken);
      final usuario = await _armazenamento.read(key: _chaveUsuario);
      if (token == null || usuario == null || _venceu(token)) {
        await encerrar();
        return null;
      }
      _token = token;
      _usuario = Usuario.fromJson(jsonDecode(usuario) as Map<String, dynamic>);
      return _usuario;
    } catch (_) {
      // Armazenamento indisponível ou dado antigo em outro formato.
      _token = null;
      _usuario = null;
      return null;
    }
  }

  /// A API não tem logout: o JWT só deixa de valer quando vence.
  /// Sair é esquecer o token aqui no app.
  Future<void> encerrar() async {
    _token = null;
    _usuario = null;
    await _armazenamento.delete(key: _chaveToken);
    await _armazenamento.delete(key: _chaveUsuario);
  }

  /// Lê o "exp" de dentro do JWT, sem precisar chamar a API.
  bool _venceu(String token) {
    try {
      final payload = token.split('.')[1];
      final json = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(payload))),
      );
      final exp = DateTime.fromMillisecondsSinceEpoch(
        (json['exp'] as int) * 1000,
      );
      return !_agora().isBefore(exp);
    } catch (_) {
      return true;
    }
  }
}
