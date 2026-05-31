class UsuarioModel {
  final String id;
  final String nombre;
  final String email;
  final String zonaSantaCruz;
  final String cultivoPrincipal;
  final String plan;
  final int diagnosticosHoy;

  const UsuarioModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.zonaSantaCruz,
    required this.cultivoPrincipal,
    required this.plan,
    required this.diagnosticosHoy,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      zonaSantaCruz: json['zona_santa_cruz'] as String? ?? '',
      cultivoPrincipal: json['cultivo_principal'] as String? ?? '',
      plan: json['plan'] as String? ?? 'Gratuito',
      diagnosticosHoy: (json['diagnosticos_hoy'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'zona_santa_cruz': zonaSantaCruz,
      'cultivo_principal': cultivoPrincipal,
      'plan': plan,
      'diagnosticos_hoy': diagnosticosHoy,
    };
  }

  UsuarioModel copyWith({
    String? id,
    String? nombre,
    String? email,
    String? zonaSantaCruz,
    String? cultivoPrincipal,
    String? plan,
    int? diagnosticosHoy,
  }) {
    return UsuarioModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      zonaSantaCruz: zonaSantaCruz ?? this.zonaSantaCruz,
      cultivoPrincipal: cultivoPrincipal ?? this.cultivoPrincipal,
      plan: plan ?? this.plan,
      diagnosticosHoy: diagnosticosHoy ?? this.diagnosticosHoy,
    );
  }

  @override
  String toString() {
    return 'UsuarioModel(id: $id, nombre: $nombre, email: $email, zonaSantaCruz: $zonaSantaCruz, cultivoPrincipal: $cultivoPrincipal, plan: $plan, diagnosticosHoy: $diagnosticosHoy)';
  }
}
