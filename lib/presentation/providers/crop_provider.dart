import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/errors/failure.dart';
import '../../data/models/diagnostico_model.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/publicacion_p2p_model.dart';
import '../../domain/repositories/crop_repository.dart';
import '../../data/repositories/crop_repository_impl.dart';

class CropProvider extends ChangeNotifier {
  final CropRepository _cropRepository;

  List<DiagnosticoModel> _diagnosticos = [];
  List<ProductoModel> _productos = [];
  List<PublicacionP2PModel> _publicacionesP2P = [];
  
  DiagnosticoModel? _diagnosticoActivo;
  bool _isLoading = false;
  String? _errorMessage;

  CropProvider({CropRepository? cropRepository})
      : _cropRepository = cropRepository ?? CropRepositoryImpl();

  // Getters
  List<DiagnosticoModel> get diagnosticos => _diagnosticos;
  List<ProductoModel> get productos => _productos;
  List<PublicacionP2PModel> get publicacionesP2P => _publicacionesP2P;
  DiagnosticoModel? get diagnosticoActivo => _diagnosticoActivo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carga asíncronamente todos los datos iniciales necesarios del agricultor
  Future<void> cargarDatosIniciales(String usuarioId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      // Cargamos en paralelo para maximizar velocidad
      final resultados = await Future.wait([
        _cropRepository.obtenerHistorialDiagnosticos(usuarioId),
        _cropRepository.obtenerProductosMarketplace(),
        _cropRepository.obtenerPublicacionesP2P(),
      ]);

      _diagnosticos = resultados[0] as List<DiagnosticoModel>;
      _productos = resultados[1] as List<ProductoModel>;
      _publicacionesP2P = resultados[2] as List<PublicacionP2PModel>;
    } catch (e) {
      _errorMessage = e is Failure ? e.message : 'Error al sincronizar datos de la nube.';
    } finally {
      _setLoading(false);
    }
  }

  /// Carga solo el historial de diagnósticos
  Future<void> cargarDiagnosticos(String usuarioId) async {
    _errorMessage = null;
    try {
      _diagnosticos = await _cropRepository.obtenerHistorialDiagnosticos(usuarioId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e is Failure ? e.message : 'Error al obtener diagnósticos.';
      notifyListeners();
    }
  }

  Future<DiagnosticoModel?> analizarCultivo({
    required String descripcion,
    required String imageAbsolutePath,
    Uint8List? imageBytes,
    required String cultivo,
    required String zona,
    double? lat,
    double? lon,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _diagnosticoActivo = null;
    try {
      final nuevoDiagnostico = await _cropRepository.registrarDiagnostico(
        descripcion: descripcion,
        imageAbsolutePath: imageAbsolutePath,
        imageBytes: imageBytes,
        cultivo: cultivo,
        zona: zona,
        lat: lat,
        lon: lon,
      );

      // Agregar al inicio del historial de manera reactiva local sin re-consultar la base de datos
      _diagnosticos.insert(0, nuevoDiagnostico);
      _diagnosticoActivo = nuevoDiagnostico;
      
      return nuevoDiagnostico;
    } catch (e) {
      _errorMessage = e is Failure ? e.message : e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Compra un producto del marketplace
  Future<bool> comprarProducto({required int productoId, required int cantidad}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _cropRepository.crearPedido(productoId: productoId, cantidad: cantidad);
      return true;
    } catch (e) {
      _errorMessage = e is Failure ? e.message : 'Error al procesar la compra.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Carga la lista de productos actual del marketplace
  Future<void> cargarProductos() async {
    _errorMessage = null;
    try {
      _productos = await _cropRepository.obtenerProductosMarketplace();
      notifyListeners();
    } catch (e) {
      _errorMessage = e is Failure ? e.message : 'Error al cargar productos.';
      notifyListeners();
    }
  }

  /// Crea una nueva publicación P2P en el foro
  Future<bool> crearPublicacionP2P(PublicacionP2PModel publicacion) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _cropRepository.crearPublicacionP2P(publicacion);
      // Recargar lista P2P para incluir la nueva publicación
      _publicacionesP2P = await _cropRepository.obtenerPublicacionesP2P();
      return true;
    } catch (e) {
      _errorMessage = e is Failure ? e.message : 'Error al crear publicación P2P.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registra que un usuario vio una publicación P2P
  Future<void> verPublicacionP2P(String publicacionId) async {
    try {
      await _cropRepository.registrarVistaP2P(publicacionId);
      // Incrementa localmente el contador para feedback visual inmediato
      final idx = _publicacionesP2P.indexWhere((element) => element.id == publicacionId);
      if (idx != -1) {
        _publicacionesP2P[idx] = _publicacionesP2P[idx].copyWith(
          vistas: _publicacionesP2P[idx].vistas + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error al incrementar vistas localmente: $e');
    }
  }

  void seleccionarDiagnostico(DiagnosticoModel diagnostico) {
    _diagnosticoActivo = diagnostico;
    notifyListeners();
  }

  void limpiarErrores() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
