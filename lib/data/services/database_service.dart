import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/failure.dart';
import '../models/usuario_model.dart';
import '../models/producto_model.dart';
import '../models/pedido_model.dart';
import '../models/publicacion_p2p_model.dart';
import '../models/diagnostico_model.dart';
import '../models/resultado_diagnostico_model.dart';

class DatabaseService {
  final SupabaseClient? _supabaseClient;

  // In-Memory Database para modo Demo sin conexión a Internet
  static final List<DiagnosticoModel> _mockDiagnosticos = [];
  static final List<PedidoModel> _mockPedidos = [];
  static final List<PublicacionP2PModel> _mockPublicacionesP2P = [];
  static UsuarioModel _mockUsuario = const UsuarioModel(
    id: 'juan-rojas-demo-uuid',
    nombre: 'Juan Rojas',
    email: 'juan.rojas@gmail.com',
    zonaSantaCruz: 'Montero',
    cultivoPrincipal: 'Tomate',
    plan: 'Gratuito',
    diagnosticosHoy: 1,
  );

  static final List<ProductoModel> _mockProductos = [
    const ProductoModel(
      id: 1,
      nombre: 'Insecticida natural',
      descripcion: 'Insecticida orgánico ideal para pulgón, mosca blanca y ácaros.',
      precioBob: 125.0,
      categoria: 'Pesticidas',
      imagenUrl: 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&q=80&w=300',
      vendedor: 'GreenPro Bolivia',
      stock: 15,
      zonaDisponible: 'Santa Cruz (Montero)',
    ),
    const ProductoModel(
      id: 2,
      nombre: 'Fungicida cobre',
      descripcion: 'Preventivo de amplio espectro contra tizón, roya y oidio.',
      precioBob: 150.0,
      categoria: 'Fertiliz.',
      imagenUrl: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&q=80&w=300',
      vendedor: 'AgroMax S.R.L.',
      stock: 8,
      zonaDisponible: 'Santa Cruz (Warnes)',
    ),
    const ProductoModel(
      id: 3,
      nombre: 'Jabón potásico',
      descripcion: 'Jabón ecológico limpiador de melaza y combatiente de pulgones.',
      precioBob: 85.0,
      categoria: 'Pesticidas',
      imagenUrl: 'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?auto=format&fit=crop&q=80&w=300',
      vendedor: 'NaturCrop',
      stock: 20,
      zonaDisponible: 'Santa Cruz de la Sierra',
    ),
    const ProductoModel(
      id: 4,
      nombre: 'Neem orgánico',
      descripcion: 'Aceite de Neem prensado en frío, inhibidor de crecimiento de larvas.',
      precioBob: 105.0,
      categoria: 'Pesticidas',
      imagenUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&q=80&w=300',
      vendedor: 'BioAgro Santa Cruz',
      stock: 10,
      zonaDisponible: 'Santa Cruz (Okinawa)',
    ),
    const ProductoModel(
      id: 5,
      nombre: 'Fertilizante NPK',
      descripcion: 'Fórmula balanceada 15-15-15 para desarrollo vegetativo y floración.',
      precioBob: 165.0,
      categoria: 'Fertiliz.',
      imagenUrl: 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&q=80&w=300',
      vendedor: 'AgroVida Bolivia',
      stock: 25,
      zonaDisponible: 'Santa Cruz (Mineros)',
    ),
    const ProductoModel(
      id: 6,
      nombre: 'Pulverizador manual',
      descripcion: 'Pulverizador de presión previa de 2 litros, boquilla de bronce regulable.',
      precioBob: 245.0,
      categoria: 'Herram.',
      imagenUrl: 'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&q=80&w=300',
      vendedor: 'FieldTools Bolivia',
      stock: 5,
      zonaDisponible: 'Santa Cruz de la Sierra',
    ),
    const ProductoModel(
      id: 7,
      nombre: 'Semillas de tomate',
      descripcion: 'Variedad híbrida Santa Clara de alta productividad y resistencia.',
      precioBob: 60.0,
      categoria: 'Semillas',
      imagenUrl: 'https://images.unsplash.com/photo-1592417817098-8f3d6eb19675?auto=format&fit=crop&q=80&w=300',
      vendedor: 'SeedMaster Cruceño',
      stock: 50,
      zonaDisponible: 'Santa Cruz (Cotoca)',
    ),
  ];

  DatabaseService({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? _tryGetClient() {
    _inicializarMocks();
  }

  static SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool forceOffline = false;
  bool get isOffline => _supabaseClient == null || forceOffline;

  void _inicializarMocks() {
    if (_mockDiagnosticos.isEmpty) {
      _mockDiagnosticos.addAll([
        DiagnosticoModel(
          id: 'mock-diag-1',
          usuarioId: 'juan-rojas-demo-uuid',
          imagenUrl: 'https://images.unsplash.com/photo-1592417817098-8f3d6eb19675?auto=format&fit=crop&q=80&w=300',
          descripcionTexto: 'Las hojas de mi cultivo de tomate tienen unos insectos pequeños verdes pegados en el envés de la hoja.',
          resultadoJson: const ResultadoDiagnosticoModel(
            diagnosticoPrincipal: 'Pulgón verde (Myzus persicae)',
            categoria: 'Insecto fitófago',
            nivelRiesgo: 'Alto',
            porcentajeRiesgo: 0.78,
            detalles: 'Se ha detectado una colonia activa de pulgones verdes alimentándose de la savia en las hojas inferiores. Esto deforma los brotes y excreta melaza, lo que favorece la aparición del hongo negrilla.',
            planAccion: [
              'Aplicar insecticida de contacto ecológico (aceite de neem o jabón potásico) en todo el follaje.',
              'Repetir la pulverización cada 5 días para controlar huevos y ninfas remanentes.',
              'Eliminar malezas circundantes para erradicar focos de infestación naturales.'
            ],
          ),
          cultivo: 'Tomate',
          zona: 'Montero',
          lat: -17.3392,
          lon: -63.3821,
          conversation: [
            {'role': 'system', 'content': 'Chat de SembrIA iniciado para el diagnóstico de Pulgón verde.'}
          ],
        ),
        DiagnosticoModel(
          id: 'mock-diag-2',
          usuarioId: 'juan-rojas-demo-uuid',
          imagenUrl: 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&q=80&w=300',
          descripcionTexto: 'Manchas negras circulares con círculos concéntricos amarillos en las hojas de soya.',
          resultadoJson: const ResultadoDiagnosticoModel(
            diagnosticoPrincipal: 'Tizón Temprano (Alternaria solani)',
            categoria: 'Hongo fitopatógeno',
            nivelRiesgo: 'Medio',
            porcentajeRiesgo: 0.52,
            detalles: 'Infección micótica temprana caracterizada por lesiones necróticas circulares. Si se expande, causará defoliación y mermará la fotosíntesis del cultivo.',
            planAccion: [
              'Podar y retirar las hojas con síntomas avanzados en la base de la planta.',
              'Aplicar fungicida sistémico de amplio espectro en dosis preventivas.',
              'Ajustar el riego para evitar anegamientos en las raíces durante la noche.'
            ],
          ),
          cultivo: 'Soya',
          zona: 'Okinawa',
          lat: -17.2201,
          lon: -63.0189,
          conversation: [
            {'role': 'system', 'content': 'Chat de SembrIA iniciado para el diagnóstico de Tizón Temprano.'}
          ],
        )
      ]);
    }

    if (_mockPublicacionesP2P.isEmpty) {
      _mockPublicacionesP2P.addAll([
        const PublicacionP2PModel(
          id: 'p2p-demo-1',
          usuarioId: 'Pablo',
          titulo: 'Semillas',
          descripcion: 'Semillas de Calabaza',
          precioBob: 25.0,
          esGratis: false,
          categoria: 'Cosecha',
          zonaSantaCruz: 'Norte Integrado',
          whatsappNumero: '59177000000',
          estado: 'Activo',
          vistas: 0,
          imagenUrl: 'https://images.unsplash.com/photo-1574316071802-0d684efa7bf5?auto=format&fit=crop&q=80&w=400',
        ),
        const PublicacionP2PModel(
          id: 'p2p-demo-2',
          usuarioId: 'Chanty',
          titulo: 'Tractor',
          descripcion: 'Como nuevo',
          precioBob: 0.0,
          esGratis: true,
          categoria: 'Herramientas',
          zonaSantaCruz: 'Chiquitanía',
          whatsappNumero: '59176333333',
          estado: 'Activo',
          vistas: 2,
          imagenUrl: 'https://images.unsplash.com/photo-1595273670150-bd0c3c392e46?auto=format&fit=crop&q=80&w=400',
        ),
        const PublicacionP2PModel(
          id: 'p2p-demo-3',
          usuarioId: 'Exson',
          titulo: 'Fumigadora',
          descripcion: 'nada',
          precioBob: 234.0,
          esGratis: false,
          categoria: 'Herramientas',
          zonaSantaCruz: 'Chiquitanía',
          whatsappNumero: '59178123456',
          estado: 'Activo',
          vistas: 2,
          imagenUrl: null, // Se renderizará con ícono de herramientas
        ),
      ]);
    }
  }

  // ----------------------------------------------------
  // USUARIOS
  // ----------------------------------------------------
  Future<UsuarioModel> obtenerUsuario(String id) async {
    if (isOffline) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_mockUsuario.id != id) {
        _mockUsuario = _mockUsuario.copyWith(id: id);
      }
      return _mockUsuario;
    }

    try {
      final response = await _supabaseClient!
          .from('usuarios')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        throw const ServerFailure('No se encontró el perfil de usuario.');
      }
      return UsuarioModel.fromJson(response);
    } catch (e) {
      throw ServerFailure('Error al obtener usuario: ${e.toString()}');
    }
  }

  Future<void> actualizarUsuario(UsuarioModel usuario) async {
    if (isOffline) {
      _mockUsuario = usuario;
      return;
    }

    try {
      await _supabaseClient!
          .from('usuarios')
          .update(usuario.toJson())
          .eq('id', usuario.id);
    } catch (e) {
      throw ServerFailure('Error al actualizar usuario: ${e.toString()}');
    }
  }

  // ----------------------------------------------------
  // DIAGNÓSTICOS
  // ----------------------------------------------------
  Future<List<DiagnosticoModel>> obtenerDiagnosticosDeUsuario(String usuarioId) async {
    if (isOffline) {
      return _mockDiagnosticos.where((d) => d.usuarioId == usuarioId).toList();
    }

    try {
      final List<dynamic> response = await _supabaseClient!
          .from('diagnosticos')
          .select()
          .eq('usuario_id', usuarioId)
          .order('id', ascending: false);

      return response.map((json) => DiagnosticoModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerFailure('Error al obtener diagnósticos: ${e.toString()}');
    }
  }

  Future<void> guardarDiagnostico(DiagnosticoModel diagnostico) async {
    if (isOffline) {
      _mockDiagnosticos.insert(0, diagnostico);
      return;
    }

    try {
      await _supabaseClient!.from('diagnosticos').insert(diagnostico.toJson());
    } catch (e) {
      throw ServerFailure('Error al guardar diagnóstico: ${e.toString()}');
    }
  }

  // ----------------------------------------------------
  // PRODUCTOS (MARKETPLACE)
  // ----------------------------------------------------
  Future<List<ProductoModel>> obtenerProductos() async {
    if (isOffline) {
      return _mockProductos;
    }

    try {
      final List<dynamic> response = await _supabaseClient!
          .from('productos')
          .select()
          .order('id', ascending: true);

      return response.map((json) => ProductoModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerFailure('Error al obtener productos: ${e.toString()}');
    }
  }

  // ----------------------------------------------------
  // PEDIDOS
  // ----------------------------------------------------
  Future<void> crearPedido(PedidoModel pedido) async {
    if (isOffline) {
      _mockPedidos.insert(0, pedido);
      
      // Descontar stock del producto in-memory
      final idx = _mockProductos.indexWhere((p) => p.id == pedido.productoId);
      if (idx != -1) {
        final p = _mockProductos[idx];
        if (p.stock >= pedido.cantidad) {
          _mockProductos[idx] = p.copyWith(stock: p.stock - pedido.cantidad);
        }
      }
      return;
    }

    try {
      await _supabaseClient!.from('pedidos').insert(pedido.toJson());
    } catch (e) {
      throw ServerFailure('Error al crear pedido: ${e.toString()}');
    }
  }

  Future<List<PedidoModel>> obtenerPedidosDeUsuario(String usuarioId) async {
    if (isOffline) {
      return _mockPedidos.where((p) => p.usuarioId == usuarioId).toList();
    }

    try {
      final List<dynamic> response = await _supabaseClient!
          .from('pedidos')
          .select()
          .eq('usuario_id', usuarioId)
          .order('creado_at', ascending: false);

      return response.map((json) => PedidoModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerFailure('Error al obtener pedidos: ${e.toString()}');
    }
  }

  // ----------------------------------------------------
  // PUBLICACIONES P2P
  // ----------------------------------------------------
  Future<List<PublicacionP2PModel>> obtenerPublicacionesP2P() async {
    if (isOffline) {
      return _mockPublicacionesP2P.where((p) => p.estado == 'Activo').toList();
    }

    try {
      final List<dynamic> response = await _supabaseClient!
          .from('publicaciones_p2p')
          .select()
          .eq('estado', 'Activo')
          .order('vistas', ascending: false);

      return response.map((json) => PublicacionP2PModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerFailure('Error al obtener publicaciones P2P: ${e.toString()}');
    }
  }

  Future<void> crearPublicacionP2P(PublicacionP2PModel publicacion) async {
    if (isOffline) {
      _mockPublicacionesP2P.insert(0, publicacion);
      return;
    }

    try {
      await _supabaseClient!.from('publicaciones_p2p').insert(publicacion.toJson());
    } catch (e) {
      throw ServerFailure('Error al crear publicación P2P: ${e.toString()}');
    }
  }

  Future<void> incrementarVistasPublicacionP2P(String id) async {
    if (isOffline) {
      final idx = _mockPublicacionesP2P.indexWhere((p) => p.id == id);
      if (idx != -1) {
        final p = _mockPublicacionesP2P[idx];
        _mockPublicacionesP2P[idx] = p.copyWith(vistas: p.vistas + 1);
      }
      return;
    }

    try {
      final response = await _supabaseClient!
          .from('publicaciones_p2p')
          .select('vistas')
          .eq('id', id)
          .single();
      
      final vistasActuales = (response['vistas'] as num?)?.toInt() ?? 0;
      
      await _supabaseClient!
          .from('publicaciones_p2p')
          .update({'vistas': vistasActuales + 1})
          .eq('id', id);
    } catch (e) {
      print('Error al incrementar vistas: $e');
    }
  }

  // ----------------------------------------------------
  // STORAGE (MOCK STORAGE PARA DIAGNÓSTICOS)
  // ----------------------------------------------------
  Future<String> subirImagenDiagnostico(String fileAbsolutePath, String ext, {Uint8List? bytes}) async {
    if (isOffline) {
      // Retornamos una hermosa imagen genérica de plantas desde Unsplash en modo offline
      await Future.delayed(const Duration(milliseconds: 500));
      final List<String> leafImages = [
        'https://images.unsplash.com/photo-1592417817098-8f3d6eb19675?auto=format&fit=crop&q=80&w=300',
        'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&q=80&w=300',
        'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&q=80&w=300',
      ];
      // Retorna una imagen según la marca de tiempo para simular variación
      return leafImages[DateTime.now().millisecond % leafImages.length];
    }

    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_diagnostico.$ext';
      final String path = 'usuario_uploads/$fileName';

      if (bytes != null) {
        // Carga binaria segura para Web y nativo sin interactuar con el sistema de archivos
        await _supabaseClient!.storage.from('diagnosticos').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
      } else {
        final File file = File(fileAbsolutePath);
        if (!await file.exists()) {
          throw const ServerFailure('El archivo de imagen no existe.');
        }

        await _supabaseClient!.storage.from('diagnosticos').upload(
              path,
              file,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
      }

      final String publicUrl = _supabaseClient!.storage.from('diagnosticos').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw ServerFailure('Error al subir imagen a Supabase Storage: ${e.toString()}');
    }
  }
}
