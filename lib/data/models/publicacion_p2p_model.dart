class PublicacionP2PModel {
  final String id;
  final String usuarioId;
  final String titulo;
  final String descripcion;
  final double precioBob;
  final bool esGratis;
  final String categoria;
  final String zonaSantaCruz;
  final String whatsappNumero;
  final String estado;
  final int vistas;
  final String? imagenUrl;

  const PublicacionP2PModel({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.descripcion,
    required this.precioBob,
    required this.esGratis,
    required this.categoria,
    required this.zonaSantaCruz,
    required this.whatsappNumero,
    required this.estado,
    required this.vistas,
    this.imagenUrl,
  });

  factory PublicacionP2PModel.fromJson(Map<String, dynamic> json) {
    return PublicacionP2PModel(
      id: json['id'] as String? ?? '',
      usuarioId: json['usuario_id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      precioBob: (json['precio_bob'] as num?)?.toDouble() ?? 0.0,
      esGratis: json['es_gratis'] as bool? ?? false,
      categoria: json['categoria'] as String? ?? '',
      zonaSantaCruz: json['zona_santa_cruz'] as String? ?? '',
      whatsappNumero: json['whatsapp_numero'] as String? ?? '',
      estado: json['estado'] as String? ?? 'Activo',
      vistas: (json['vistas'] as num?)?.toInt() ?? 0,
      imagenUrl: json['imagen_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'titulo': titulo,
      'descripcion': descripcion,
      'precio_bob': precioBob,
      'es_gratis': esGratis,
      'categoria': categoria,
      'zona_santa_cruz': zonaSantaCruz,
      'whatsapp_numero': whatsappNumero,
      'estado': estado,
      'vistas': vistas,
      'imagen_url': imagenUrl,
    };
  }

  PublicacionP2PModel copyWith({
    String? id,
    String? usuarioId,
    String? titulo,
    String? descripcion,
    double? precioBob,
    bool? esGratis,
    String? categoria,
    String? zonaSantaCruz,
    String? whatsappNumero,
    String? estado,
    int? vistas,
    String? imagenUrl,
  }) {
    return PublicacionP2PModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      precioBob: precioBob ?? this.precioBob,
      esGratis: esGratis ?? this.esGratis,
      categoria: categoria ?? this.categoria,
      zonaSantaCruz: zonaSantaCruz ?? this.zonaSantaCruz,
      whatsappNumero: whatsappNumero ?? this.whatsappNumero,
      estado: estado ?? this.estado,
      vistas: vistas ?? this.vistas,
      imagenUrl: imagenUrl ?? this.imagenUrl,
    );
  }

  @override
  String toString() {
    return 'PublicacionP2PModel(id: $id, titulo: $titulo, precioBob: $precioBob, whatsapp: $whatsappNumero)';
  }
}
