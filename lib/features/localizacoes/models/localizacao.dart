/// Uma posição do aparelho registrada pelo aplicativo.
class Localizacao {
  const Localizacao({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.precisao,
    required this.instante,
  });

  /// Identificador gerado pelo banco; nulo antes de ser salvo.
  final int? id;
  final double latitude;
  final double longitude;

  /// Precisão estimada, em metros.
  final double precisao;

  /// Momento da leitura, sempre em UTC.
  final DateTime instante;

  /// Cria o objeto a partir de uma linha da tabela `localizacoes`.
  factory Localizacao.fromMap(Map<String, Object?> mapa) {
    return Localizacao(
      id: mapa['id'] as int?,
      latitude: (mapa['latitude'] as num).toDouble(),
      longitude: (mapa['longitude'] as num).toDouble(),
      precisao: (mapa['precisao'] as num).toDouble(),
      instante: DateTime.parse(mapa['instante'] as String).toUtc(),
    );
  }

  /// Converte para uma linha da tabela. O instante vai em UTC, no formato
  /// ISO 8601 (ex.: 2026-11-02T13:05:20.000Z).
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'precisao': precisao,
      'instante': instante.toUtc().toIso8601String(),
    };
  }
}
