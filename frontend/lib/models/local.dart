class Edificio {
  const Edificio({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.portarias,
  });

  factory Edificio.fromJson(Map<String, dynamic> json) => Edificio(
    id: json['id'] as String,
    nome: json['nome'] as String,
    endereco: json['endereco'] as String,
    portarias: [
      for (final item in json['portarias'] as List<dynamic>)
        Portaria.fromJson(item as Map<String, dynamic>),
    ],
  );

  final String id;
  final String nome;
  final String endereco;
  final List<Portaria> portarias;
}

class Portaria {
  const Portaria({required this.id, required this.nome, required this.portas});

  factory Portaria.fromJson(Map<String, dynamic> json) => Portaria(
    id: json['id'] as String,
    nome: json['nome'] as String,
    portas: [
      for (final item in json['portas'] as List<dynamic>)
        Porta.fromJson(item as Map<String, dynamic>),
    ],
  );

  final String id;
  final String nome;
  final List<Porta> portas;
}

class Porta {
  const Porta({required this.id, required this.nome, required this.catracas});

  factory Porta.fromJson(Map<String, dynamic> json) => Porta(
    id: json['id'] as String,
    nome: json['nome'] as String,
    catracas: [
      for (final item in json['catracas'] as List<dynamic>)
        Catraca.fromJson(item as Map<String, dynamic>),
    ],
  );

  final String id;
  final String nome;
  final List<Catraca> catracas;
}

class Catraca {
  const Catraca({
    required this.id,
    required this.nome,
    required this.doorId,
    required this.latitude,
    required this.longitude,
    required this.raioMetros,
  });

  factory Catraca.fromJson(Map<String, dynamic> json) => Catraca(
    id: json['id'] as String,
    nome: json['nome'] as String,
    doorId: json['doorId'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    raioMetros: json['raioMetros'] as int,
  );

  final String id;
  final String nome;
  final String doorId;
  final double latitude;
  final double longitude;
  final int raioMetros;
}

/// Catraca com o caminho até ela, para os seletores dos formulários.
typedef CatracaNoLocal = ({Catraca catraca, String caminho});

/// Achata a árvore: "Catraca 1 · Portaria Principal › Porta A".
List<CatracaNoLocal> catracasDe(List<Edificio> edificios) => [
  for (final edificio in edificios)
    for (final portaria in edificio.portarias)
      for (final porta in portaria.portas)
        for (final catraca in porta.catracas)
          (
            catraca: catraca,
            caminho: '${catraca.nome} · ${portaria.nome} › ${porta.nome}',
          ),
];