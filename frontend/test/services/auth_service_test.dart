import 'package:flutter_test/flutter_test.dart';
import 'package:public/models/usuario.dart';
import 'package:public/services/auth_service.dart';

void main() {
  late AuthService auth;

  // Cada teste começa só com as contas de demonstração.
  setUp(() => auth = AuthService());

  test('Tem uma conta de demonstração de cada perfil', () {
    final perfis = AuthService.contasDemo.map((usuario) => usuario.perfil);
    expect(perfis, unorderedEquals(Perfil.values));
  });

  test('Entra pelo e-mail sem ligar para maiúsculas e espaços', () {
    final usuario = auth.entrar(' Admin@Passe.com ', AuthService.senhaDemo);
    expect(usuario?.perfil, Perfil.admin);
  });

  test('Entra pelo CPF com ou sem pontuação', () {
    expect(
      auth.entrar('222.222.222-22', AuthService.senhaDemo)?.perfil,
      Perfil.controladorAcesso,
    );
    expect(
      auth.entrar('33333333333', AuthService.senhaDemo)?.perfil,
      Perfil.morador,
    );
  });

  test('Senha errada ou conta que não existe não entra', () {
    expect(auth.entrar('admin@passe.com', 'errada'), isNull);
    expect(auth.entrar('ninguem@passe.com', AuthService.senhaDemo), isNull);
    expect(auth.entrar('999.999.999-99', AuthService.senhaDemo), isNull);
  });

  test('Cadastro cria morador e a conta já consegue entrar', () {
    final novo = auth.registrar(
      nome: ' João Pereira ',
      cpf: '765.430.123-00',
      email: 'Joao@Email.com',
      senha: 'segredo123',
    );

    expect(novo?.perfil, Perfil.morador);
    expect(novo?.nome, 'João Pereira');
    expect(novo?.email, 'joao@email.com');
    expect(novo?.cpf, '76543012300');
    expect(auth.entrar('joao@email.com', 'segredo123')?.nome, 'João Pereira');
    expect(auth.entrar('76543012300', 'segredo123'), isNotNull);
  });

  test('Não deixa cadastrar e-mail ou CPF que já tem conta', () {
    expect(
      auth.registrar(
        nome: 'Outra pessoa',
        cpf: '765.430.123-00',
        email: 'ADMIN@passe.com',
        senha: 'segredo123',
      ),
      isNull,
    );
    expect(
      auth.registrar(
        nome: 'Outra pessoa',
        cpf: '111.111.111-11',
        email: 'outra@email.com',
        senha: 'segredo123',
      ),
      isNull,
    );
  });
}
