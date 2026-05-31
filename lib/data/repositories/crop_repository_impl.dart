import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/crop_repository.dart';
import '../models/usuario_model.dart';
import '../models/diagnostico_model.dart';
import '../models/producto_model.dart';
import '../models/pedido_model.dart';
import '../models/publicacion_p2p_model.dart';
import '../services/database_service.dart';
import '../services/ai_diagnosis_service.dart';

class CropRepositoryImpl implements CropRepository {
  final DatabaseService _databaseService;
  final AiDiagnosisService _aiDiagnosisService;
  final SupabaseClient _supabaseClient;

  CropRepositoryImpl({
    DatabaseService? databaseService,
    AiDiagnosisService? aiDiagnosisService,
    SupabaseClient? supabaseClient,
  })  : _databaseService = databaseService ?? DatabaseService(),
        _aiDiagnosisService = aiDiagnosisService ?? AiDiagnosisService(),
        _supabaseClient = supabaseClient ?? Supabase.instance.client;

  // Generador de UUID v4 nativo en Dart para evitar dependencias extras en el hackathon
  String _generarUuidV4() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Versión 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variante RFC 4122
    
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  @override
  Future<UsuarioModel> obtenerPerfilUsuario(String usuarioId) async {
    return await _databaseService.obtenerUsuario(usuarioId);
  }

  @override
  Future<void> actualizarPerfilUsuario(UsuarioModel usuario) async {
    await _databaseService.actualizarUsuario(usuario);
  }

  @override
  Future<DiagnosticoModel> registrarDiagnostico({
    required String descripcion,
    required String imageAbsolutePath,
    Uint8List? imageBytes,
    required String cultivo,
    required String zona,
    double? lat,
    double? lon,
  }) async {
    // 1. Obtener ID de usuario autenticado
    final String? usuarioId = _supabaseClient.auth.currentUser?.id;
    if (usuarioId == null) {
      throw Exception('Usuario no autenticado para registrar un diagnóstico.');
    }

    // 2. Extraer extensión del archivo y subir imagen a Supabase Storage
    final String ext = imageAbsolutePath.split('.').last.toLowerCase();
    final String imagenUrl = await _databaseService.subirImagenDiagnostico(imageAbsolutePath, ext, bytes: imageBytes);

    // 3. Ejecutar análisis del cultivo con el servicio de Inteligencia Artificial (Claude)
    final resultadoAi = await _aiDiagnosisService.diagnosticarCultivo(
      imagenUrl: imagenUrl,
      descripcion: descripcion,
      cultivo: cultivo,
      zona: zona,
    );

    // 4. Crear el modelo de diagnóstico
    final diagnostico = DiagnosticoModel(
      id: _generarUuidV4(),
      usuarioId: usuarioId,
      imagenUrl: imagenUrl,
      descripcionTexto: descripcion,
      resultadoJson: resultadoAi,
      cultivo: cultivo,
      zona: zona,
      lat: lat,
      lon: lon,
      conversation: [
        {
          'role': 'system',
          'content': 'Has iniciado el chat de SembrIA para esta plaga.'
        }
      ],
    );

    // 5. Guardar diagnóstico en PostgreSQL de Supabase
    await _databaseService.guardarDiagnostico(diagnostico);

    // 6. Incrementar contador de diagnósticos diarios del usuario
    try {
      final perfil = await _databaseService.obtenerUsuario(usuarioId);
      final perfilActualizado = perfil.copyWith(
        diagnosticosHoy: perfil.diagnosticosHoy + 1,
      );
      await _databaseService.actualizarUsuario(perfilActualizado);
    } catch (e) {
      // Registrar error pero no interrumpir la experiencia de usuario
      print('No se pudo incrementar el contador de diagnósticos del usuario: $e');
    }

    return diagnostico;
  }

  @override
  Future<List<DiagnosticoModel>> obtenerHistorialDiagnosticos(String usuarioId) async {
    return await _databaseService.obtenerDiagnosticosDeUsuario(usuarioId);
  }

  @override
  Future<List<ProductoModel>> obtenerProductosMarketplace() async {
    return await _databaseService.obtenerProductos();
  }

  @override
  Future<void> crearPedido({required int productoId, required int cantidad}) async {
    final String? usuarioId = _supabaseClient.auth.currentUser?.id;
    if (usuarioId == null) {
      throw Exception('Usuario no autenticado para realizar un pedido.');
    }

    final pedido = PedidoModel(
      id: _generarUuidV4(),
      usuarioId: usuarioId,
      productoId: productoId,
      cantidad: cantidad,
      estado: 'Pendiente',
      creadoAt: DateTime.now(),
    );

    await _databaseService.crearPedido(pedido);
  }

  @override
  Future<List<PedidoModel>> obtenerPedidosDeUsuario(String usuarioId) async {
    return await _databaseService.obtenerPedidosDeUsuario(usuarioId);
  }

  @override
  Future<List<PublicacionP2PModel>> obtenerPublicacionesP2P() async {
    return await _databaseService.obtenerPublicacionesP2P();
  }

  @override
  Future<void> crearPublicacionP2P(PublicacionP2PModel publicacion) async {
    // Si la publicación viene sin ID, generamos uno
    final publicacionCompleta = publicacion.id.isEmpty
        ? publicacion.copyWith(id: _generarUuidV4())
        : publicacion;

    await _databaseService.crearPublicacionP2P(publicacionCompleta);
  }

  @override
  Future<void> registrarVistaP2P(String publicacionId) async {
    await _databaseService.incrementarVistasPublicacionP2P(publicacionId);
  }
}
