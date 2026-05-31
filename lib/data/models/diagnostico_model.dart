import 'resultado_diagnostico_model.dart';

class DiagnosticoModel {
  final String id;
  final String usuarioId;
  final String imagenUrl;
  final String descripcionTexto;
  final ResultadoDiagnosticoModel resultadoJson;
  final String cultivo;
  final String zona;
  final double? lat;
  final double? lon;
  final List<Map<String, dynamic>>? conversation;

  const DiagnosticoModel({
    required this.id,
    required this.usuarioId,
    required this.imagenUrl,
    required this.descripcionTexto,
    required this.resultadoJson,
    required this.cultivo,
    required this.zona,
    this.lat,
    this.lon,
    this.conversation,
  });

  factory DiagnosticoModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticoModel(
      id: json['id'] as String? ?? '',
      usuarioId: json['usuario_id'] as String? ?? '',
      imagenUrl: json['imagen_url'] as String? ?? '',
      descripcionTexto: json['descripcion_texto'] as String? ?? '',
      resultadoJson: ResultadoDiagnosticoModel.fromJson(
        json['resultado_json'] as Map<String, dynamic>? ?? {},
      ),
      cultivo: json['cultivo'] as String? ?? '',
      zona: json['zona'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      conversation: (json['conversation'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'imagen_url': imagenUrl,
      'descripcion_texto': descripcionTexto,
      'resultado_json': resultadoJson.toJson(),
      'cultivo': cultivo,
      'zona': zona,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (conversation != null) 'conversation': conversation,
    };
  }

  DiagnosticoModel copyWith({
    String? id,
    String? usuarioId,
    String? imagenUrl,
    String? descripcionTexto,
    ResultadoDiagnosticoModel? resultadoJson,
    String? cultivo,
    String? zona,
    double? lat,
    double? lon,
    List<Map<String, dynamic>>? conversation,
  }) {
    return DiagnosticoModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      descripcionTexto: descripcionTexto ?? this.descripcionTexto,
      resultadoJson: resultadoJson ?? this.resultadoJson,
      cultivo: cultivo ?? this.cultivo,
      zona: zona ?? this.zona,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      conversation: conversation ?? this.conversation,
    );
  }

  @override
  String toString() {
    return 'DiagnosticoModel(id: $id, usuarioId: $usuarioId, imagenUrl: $imagenUrl, cultivo: $cultivo, zona: $zona)';
  }
}
