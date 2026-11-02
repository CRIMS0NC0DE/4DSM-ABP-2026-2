import 'package:flutter/material.dart' show TimeOfDay;

import '../../models/usuario.dart';

/// Datas, horas e documentos como as telas mostram e como a API espera.
abstract final class Formato {
  static const _semana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];
  static const _meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static String _dois(int n) => n.toString().padLeft(2, '0');

  /// "AAAA-MM-DD", como a API recebe as datas das autorizações.
  static String dataApi(DateTime d) =>
      '${d.year}-${_dois(d.month)}-${_dois(d.day)}';

  /// "HH:MM", como a API recebe os horários.
  static String horaApi(TimeOfDay h) => '${_dois(h.hour)}:${_dois(h.minute)}';

  /// "HH:MM" da API de volta para o seletor de hora.
  static TimeOfDay horaDaApi(String hora) {
    final [h, m] = hora.split(':');
    return TimeOfDay(hour: int.parse(h), minute: int.parse(m));
  }

  /// "14/10/2026".
  static String data(DateTime d) =>
      '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

  /// "14/10".
  static String diaMes(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}';

  /// "09:12".
  static String hora(DateTime d) => '${_dois(d.hour)}:${_dois(d.minute)}';

  /// "Quarta-feira, 14 de outubro" (U2).
  static String dataPorExtenso(DateTime d) =>
      '${_semana[d.weekday - 1]}, ${d.day} de ${_meses[d.month - 1]}';

  /// "•••.456.789-••": a tela não mostra o CPF inteiro (U9, A3).
  static String cpfMascarado(String cpf) => cpf.length == 11
      ? '•••.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-••'
      : cpf;

  /// "123.456.789-00", para o campo do formulário (A4).
  static String cpf(String cpf) => cpf.length == 11
      ? '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.'
            '${cpf.substring(6, 9)}-${cpf.substring(9)}'
      : cpf;

  /// "MS", para o círculo com as iniciais (U9, A3).
  static String iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    final primeira = partes.first.isEmpty ? '?' : partes.first[0];
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return '$primeira$ultima'.toUpperCase();
  }

  /// "4F2A": os 4 últimos caracteres da tag (U9).
  static String finalTag(String uid) =>
      uid.length <= 4 ? uid : uid.substring(uid.length - 4);

  /// "Condômino", "Administrador"... (A3, A4, U9).
  static String perfil(Perfil perfil) => switch (perfil) {
    Perfil.admin => 'Administrador',
    Perfil.controladorAcesso => 'Controlador de acesso',
    Perfil.morador => 'Condômino',
    Perfil.visitante => 'Visitante',
  };
}