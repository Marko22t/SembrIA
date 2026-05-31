class ResultadoDiagnosticoModel {
  final String diagnosticoPrincipal;
  final String categoria;
  final String nivelRiesgo;
  final double porcentajeRiesgo;
  final String detalles;
  final List<String> planAccion;

  const ResultadoDiagnosticoModel({
    required this.diagnosticoPrincipal,
    required this.categoria,
    required this.nivelRiesgo,
    required this.porcentajeRiesgo,
    required this.detalles,
    required this.planAccion,
  });

  factory ResultadoDiagnosticoModel.fromJson(Map<String, dynamic> json) {
    return ResultadoDiagnosticoModel(
      diagnosticoPrincipal: json['diagnostico_principal'] as String? ?? 'Desconocido',
      categoria: json['categoria'] as String? ?? 'General',
      nivelRiesgo: json['nivel_riesgo'] as String? ?? 'Bajo',
      porcentajeRiesgo: (json['porcentaje_riesgo'] as num?)?.toDouble() ?? 0.0,
      detalles: json['detalles'] as String? ?? '',
      planAccion: (json['plan_accion'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diagnostico_principal': diagnosticoPrincipal,
      'categoria': categoria,
      'nivel_riesgo': nivelRiesgo,
      'porcentaje_riesgo': porcentajeRiesgo,
      'detalles': detalles,
      'plan_accion': planAccion,
    };
  }

  @override
  String toString() {
    return 'ResultadoDiagnosticoModel(diagnosticoPrincipal: $diagnosticoPrincipal, categoria: $categoria, nivelRiesgo: $nivelRiesgo, porcentajeRiesgo: $porcentajeRiesgo, detalles: $detalles, planAccion: $planAccion)';
  }
}
