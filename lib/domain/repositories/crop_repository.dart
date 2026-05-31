import 'dart:typed_data';
import '../../data/models/usuario_model.dart';
import '../../data/models/diagnostico_model.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/pedido_model.dart';
import '../../data/models/publicacion_p2p_model.dart';

abstract class CropRepository {
  /// Obtiene los datos del perfil del agricultor actual.
  Future<UsuarioModel> obtenerPerfilUsuario(String usuarioId);

  /// Actualiza los datos del perfil del agricultor.
  Future<void> actualizarPerfilUsuario(UsuarioModel usuario);

  /// Sube la foto del cultivo, ejecuta el análisis con Claude AI y guarda el diagnóstico en la base de datos de Supabase.
  Future<DiagnosticoModel> registrarDiagnostico({
    required String descripcion,
    required String imageAbsolutePath,
    Uint8List? imageBytes,
    required String cultivo,
    required String zona,
    double? lat,
    double? lon,
  });

  /// Recupera el historial completo de diagnósticos de un usuario.
  Future<List<DiagnosticoModel>> obtenerHistorialDiagnosticos(String usuarioId);

  /// Obtiene los productos disponibles en el agro-marketplace.
  Future<List<ProductoModel>> obtenerProductosMarketplace();

  /// Genera un pedido o compra de un agro-producto del marketplace.
  Future<void> crearPedido({
    required int productoId,
    required int cantidad,
  });

  /// Obtiene la lista de pedidos realizados por el usuario.
  Future<List<PedidoModel>> obtenerPedidosDeUsuario(String usuarioId);

  /// Recupera todas las publicaciones activas del foro de trueques y comercio P2P.
  Future<List<PublicacionP2PModel>> obtenerPublicacionesP2P();

  /// Crea una nueva publicación P2P de trueque o venta libre en Santa Cruz.
  Future<void> crearPublicacionP2P(PublicacionP2PModel publicacion);

  /// Registra una visualización en una publicación P2P.
  Future<void> registrarVistaP2P(String publicacionId);
}
