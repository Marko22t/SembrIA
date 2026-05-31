import 'package:flutter_test/flutter_test.dart';
import 'package:sembria/data/models/usuario_model.dart';
import 'package:sembria/data/models/resultado_diagnostico_model.dart';
import 'package:sembria/data/models/diagnostico_model.dart';
import 'package:sembria/data/models/producto_model.dart';
import 'package:sembria/data/models/pedido_model.dart';
import 'package:sembria/data/models/publicacion_p2p_model.dart';

void main() {
  group('Pruebas Unitarias de Modelos de Datos - SembrIA', () {
    test('UsuarioModel serialización y deserialización', () {
      final json = {
        'id': 'usuario-123-uuid',
        'nombre': 'Juan Rojas',
        'email': 'juan.rojas@gmail.com',
        'zona_santa_cruz': 'Montero',
        'cultivo_principal': 'Tomate',
        'plan': 'Premium',
        'diagnosticos_hoy': 2,
      };

      final model = UsuarioModel.fromJson(json);

      expect(model.id, 'usuario-123-uuid');
      expect(model.nombre, 'Juan Rojas');
      expect(model.zonaSantaCruz, 'Montero');
      expect(model.cultivoPrincipal, 'Tomate');
      expect(model.plan, 'Premium');
      expect(model.diagnosticosHoy, 2);

      final serializado = model.toJson();
      expect(serializado['id'], 'usuario-123-uuid');
      expect(serializado['zona_santa_cruz'], 'Montero');
      expect(serializado['diagnosticos_hoy'], 2);
    });

    test('ResultadoDiagnosticoModel serialización y deserialización (JSONB de Claude)', () {
      final json = {
        'diagnostico_principal': 'Pulgón verde (Myzus persicae)',
        'categoria': 'Insecto fitófago',
        'nivel_riesgo': 'Alto',
        'porcentaje_riesgo': 0.78,
        'detalles': 'Colonia de pulgón detectada en el envés.',
        'plan_accion': [
          'Aplicar insecticida de contacto en el envés.',
          'Repetir en 5 días.'
        ],
      };

      final model = ResultadoDiagnosticoModel.fromJson(json);

      expect(model.diagnosticoPrincipal, 'Pulgón verde (Myzus persicae)');
      expect(model.categoria, 'Insecto fitófago');
      expect(model.nivelRiesgo, 'Alto');
      expect(model.porcentajeRiesgo, 0.78);
      expect(model.planAccion.length, 2);
      expect(model.planAccion[0], 'Aplicar insecticida de contacto en el envés.');

      final serializado = model.toJson();
      expect(serializado['diagnostico_principal'], 'Pulgón verde (Myzus persicae)');
      expect(serializado['porcentaje_riesgo'], 0.78);
    });

    test('DiagnosticoModel serialización y deserialización', () {
      final json = {
        'id': 'diag-abc-uuid',
        'usuario_id': 'user-123',
        'imagen_url': 'https://supabase.co/storage/img.jpg',
        'descripcion_texto': 'Hojas amarillas con insectos',
        'resultado_json': {
          'diagnostico_principal': 'Pulgón verde',
          'categoria': 'Plaga',
          'nivel_riesgo': 'Alto',
          'porcentaje_riesgo': 0.78,
          'detalles': 'Monitoreo preventivo.',
          'plan_accion': ['Paso 1'],
        },
        'cultivo': 'Tomate',
        'zona': 'Warnes',
        'lat': -17.7833,
        'lon': -63.1821,
        'conversation': [
          {'role': 'system', 'content': 'Chat abierto'}
        ],
      };

      final model = DiagnosticoModel.fromJson(json);

      expect(model.id, 'diag-abc-uuid');
      expect(model.usuarioId, 'user-123');
      expect(model.cultivo, 'Tomate');
      expect(model.lat, -17.7833);
      expect(model.resultadoJson.diagnosticoPrincipal, 'Pulgón verde');
      expect(model.conversation?.first['content'], 'Chat abierto');

      final serializado = model.toJson();
      expect(serializado['id'], 'diag-abc-uuid');
      expect(serializado['resultado_json']['diagnostico_principal'], 'Pulgón verde');
      expect(serializado['lat'], -17.7833);
    });

    test('ProductoModel serialización y deserialización', () {
      final json = {
        'id': 45,
        'nombre': 'Fungicida Cobre Max',
        'descripcion': 'Fungicida sistémico contra roya',
        'precio_bob': 150.50,
        'categoria': 'Fungicidas',
        'imagen_url': 'https://supabase.co/storage/cobre.jpg',
        'vendedor': 'Agro Bolivia',
        'stock': 12,
        'zona_disponible': 'Santa Cruz de la Sierra',
      };

      final model = ProductoModel.fromJson(json);

      expect(model.id, 45);
      expect(model.nombre, 'Fungicida Cobre Max');
      expect(model.precioBob, 150.50);
      expect(model.vendedor, 'Agro Bolivia');
      expect(model.stock, 12);

      final serializado = model.toJson();
      expect(serializado['id'], 45);
      expect(serializado['precio_bob'], 150.50);
    });

    test('PedidoModel serialización y deserialización', () {
      final json = {
        'id': 'ped-123',
        'usuario_id': 'user-456',
        'producto_id': 45,
        'cantidad': 3,
        'estado': 'Entregado',
        'creado_at': '2026-05-31T12:00:00.000Z',
      };

      final model = PedidoModel.fromJson(json);

      expect(model.id, 'ped-123');
      expect(model.productoId, 45);
      expect(model.cantidad, 3);
      expect(model.estado, 'Entregado');
      expect(model.creadoAt.year, 2026);

      final serializado = model.toJson();
      expect(serializado['id'], 'ped-123');
      expect(serializado['producto_id'], 45);
    });

    test('PublicacionP2PModel serialización y deserialización', () {
      final json = {
        'id': 'p2p-789',
        'usuario_id': 'user-123',
        'titulo': 'Semilla de soya certificada',
        'descripcion': 'Intercambio por fertilizante',
        'precio_bob': 0.0,
        'es_gratis': true,
        'categoria': 'Semillas',
        'zona_santa_cruz': 'Okinawa',
        'whatsapp_numero': '+59177000000',
        'estado': 'Activo',
        'vistas': 42,
      };

      final model = PublicacionP2PModel.fromJson(json);

      expect(model.id, 'p2p-789');
      expect(model.titulo, 'Semilla de soya certificada');
      expect(model.esGratis, true);
      expect(model.zonaSantaCruz, 'Okinawa');
      expect(model.whatsappNumero, '+59177000000');
      expect(model.vistas, 42);

      final serializado = model.toJson();
      expect(serializado['id'], 'p2p-789');
      expect(serializado['es_gratis'], true);
    });
  });
}
