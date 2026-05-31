class ProductoModel {
  final int id;
  final String nombre;
  final String descripcion;
  final double precioBob;
  final String categoria;
  final String imagenUrl;
  final String vendedor;
  final int stock;
  final String zonaDisponible;

  const ProductoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioBob,
    required this.categoria,
    required this.imagenUrl,
    required this.vendedor,
    required this.stock,
    required this.zonaDisponible,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    return ProductoModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      precioBob: (json['precio_bob'] as num?)?.toDouble() ?? 0.0,
      categoria: json['categoria'] as String? ?? '',
      imagenUrl: json['imagen_url'] as String? ?? '',
      vendedor: json['vendedor'] as String? ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      zonaDisponible: json['zona_disponible'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_bob': precioBob,
      'categoria': categoria,
      'imagen_url': imagenUrl,
      'vendedor': vendedor,
      'stock': stock,
      'zona_disponible': zonaDisponible,
    };
  }

  ProductoModel copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    double? precioBob,
    String? categoria,
    String? imagenUrl,
    String? vendedor,
    int? stock,
    String? zonaDisponible,
  }) {
    return ProductoModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioBob: precioBob ?? this.precioBob,
      categoria: categoria ?? this.categoria,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      vendedor: vendedor ?? this.vendedor,
      stock: stock ?? this.stock,
      zonaDisponible: zonaDisponible ?? this.zonaDisponible,
    );
  }

  @override
  String toString() {
    return 'ProductoModel(id: $id, nombre: $nombre, precioBob: $precioBob, stock: $stock)';
  }
}
