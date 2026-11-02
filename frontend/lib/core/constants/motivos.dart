abstract final class Motivos {
  static const _textos = {
    'QR_INVALIDO': (
      'QR Code não reconhecido',
      'Escaneie o QR que aparece na tela da catraca.',
    ),
    'QR_EXPIRADO': (
      'O QR Code já mudou',
      'Escaneie o código novo que está na tela.',
    ),
    'QR_JA_UTILIZADO': (
      'Este QR Code já foi usado',
      'Espere o código novo aparecer e escaneie de novo.',
    ),
    'TERMINAL_DESCONHECIDO': ('Catraca não cadastrada', 'Fale com a portaria.'),
    'TAG_DESCONHECIDA': (
      'Tag não cadastrada',
      'Peça para a portaria vincular sua tag.',
    ),
    'TAG_BLOQUEADA': ('Sua tag está bloqueada', 'Fale com a portaria.'),
    'USUARIO_INATIVO': ('Seu cadastro está desativado', 'Fale com a portaria.'),
    'SEM_AUTORIZACAO': (
      'Você não tem autorização para esta catraca',
      'Peça uma autorização à portaria.',
    ),
    'AUTORIZACAO_CANCELADA': (
      'Sua autorização foi cancelada',
      'Fale com a portaria para saber mais.',
    ),
    'AUTORIZACAO_EXPIRADA': (
      'Sua autorização expirou',
      'Peça uma nova autorização à portaria.',
    ),
    'AUTORIZACAO_NAO_INICIADA': (
      'Sua autorização ainda não começou',
      'Volte na data de início.',
    ),
    'FORA_DO_HORARIO': (
      'Fora do horário permitido',
      'Volte dentro do horário ou fale com a portaria.',
    ),
    'SEM_USOS': ('Você não tem mais usos', 'Peça mais usos à portaria.'),
    'LOCALIZACAO_AUSENTE': (
      'Não conseguimos sua localização',
      'Permita a localização no celular e tente de novo.',
    ),
    'LONGE_DO_TERMINAL': (
      'Você está longe da catraca',
      'Chegue mais perto da catraca e tente de novo.',
    ),
  };

  static String titulo(String? codigo) =>
      _textos[codigo]?.$1 ?? 'Acesso negado';

  static String oQueFazer(String? codigo) =>
      _textos[codigo]?.$2 ?? 'Fale com a portaria.';
}