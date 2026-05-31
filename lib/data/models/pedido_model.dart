class PedidoModel {
  final String id;
  final String usuarioId;
  final int productoId;
  final int cantidad;
  final String estado;
  final DateTime creadoAt;

  const PedidoModel({
    required this.id,
    required this.usuarioId,
    required this.productoId,
    required this.cantidad,
    required this.estado,
    required this.creadoAt,
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      id: json['id'] as String? ?? '',
      usuarioId: json['usuario_id'] as String? ?? '',
      productoId: (json['producto_id'] as num?)?.toInt() ?? 0,
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 1,
      estado: json['estado'] as String? ?? 'Pendiente',
      creadoAt: json['creado_at'] != null
          ? DateTime.parse(json['creado_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'estado': estado,
      'creado_at': creadoAt.toIso8601String(),
    };
  }

  PedidoModel copyWith({
    String? id,
    String? usuarioId,
    int? productoId,
    int? cantidad,
    String? estado,
    DateTime? creadoAt,
  }) {
    return PedidoModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      estado: estado ?? this.estado,
      creadoAt: creadoAt ?? this.creadoAt,
    );
  }

  @override
  String toString() {
    return 'PedidoModel(id: $id, usuarioId: $usuarioId, productoId: $productoId, cantidad: $cantidad, estado: $estado)';
  }
}
