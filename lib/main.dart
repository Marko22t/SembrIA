import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;

// Importaciones de la Arquitectura Limpia (Clean Architecture)
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/crop_provider.dart';
import 'data/models/usuario_model.dart';
import 'data/models/diagnostico_model.dart';
import 'data/models/producto_model.dart';
import 'data/models/pedido_model.dart';
import 'data/models/publicacion_p2p_model.dart';
import 'data/services/supabase_auth_service.dart';
import 'data/services/database_service.dart';

// ═══════════════════════════════════════════════════════════
//  SEMBRIA - APP COMPLETA
//  Pantallas: Home · IA · Resultado IA · Marketplace · Perfil
// ═══════════════════════════════════════════════════════════

// ─────────────────────────────────────────────
//  PALETA DE COLORES
// ─────────────────────────────────────────────
class SC {
  static const greenDark = Color(0xFF1B3A1F);
  static const greenMid = Color(0xFF2E7D32);
  static const greenBright = Color(0xFF43A047);
  static const greenLight = Color(0xFF66BB6A);
  static const greenPale = Color(0xFFC8E6C9);
  static const greenGhost = Color(0xFFE8F5E9);
  static const darkBg = Color(0xFF0F1F10);
  static const darkSurface = Color(0xFF1A2E1A);
  static const darkBorder = Color(0xFF2E4A2E);
  static const darkDeep = Color(0xFF0D2610);
  static const warnBg = Color(0xFFFFF8EC);
  static const warnBorder = Color(0xFFF5D98A);
  static const warnIcon = Color(0xFFE65100);
  static const warnIconDk = Color(0xFFEF9F27);
  static const warnBgDk = Color(0xFF2A1F0A);
  static const warnBorderDk = Color(0xFF4A3A10);
  static const textDim = Color(0xFF7A9A7A);
  static const textDimDk = Color(0xFF4A7A4A);
}

// ─────────────────────────────────────────────
//  MAIN
// ─────────────────────────────────────────────
void main() async {
  // Asegurar inicialización de bindings de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización global de Supabase Client en el Cliente de Flutter
  // Reemplazar estas credenciales simuladas por las de tu proyecto Supabase en la Hackathon
  await Supabase.initialize(
    url: 'https://cropdoctor-agro-supabase.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNyb3Bkb2N0b3ItYWdyby1zdXBhYmFzZSIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjc4MDAwMDAwLCJleHAiOjIwOTM1NjAwMDB9.EXAMPLE_KEY',
  );

  runApp(const SembriaApp());
}

class SembriaApp extends StatefulWidget {
  const SembriaApp({super.key});
  @override
  State<SembriaApp> createState() => _SembriaAppState();
}

class _SembriaAppState extends State<SembriaApp> {
  bool _isDark = false;
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CropProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'SembrIA',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(brightness: Brightness.light, fontFamily: 'Roboto'),
            darkTheme: ThemeData(brightness: Brightness.dark, fontFamily: 'Roboto'),
            themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
            home: authProvider.usuarioActual != null
                ? MainShell(
                    isDark: _isDark,
                    onToggle: () => setState(() => _isDark = !_isDark),
                  )
                : AuthScreen(
                    isDark: _isDark,
                    onToggleTheme: () => setState(() => _isDark = !_isDark),
                  ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MAIN SHELL - Navegación entre pantallas
// ─────────────────────────────────────────────
class MainShell extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;
  const MainShell({super.key, required this.isDark, required this.onToggle});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    // Ejecuta la carga inicial asíncrona de datos desde Supabase / Memoria
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().usuarioActual;
      if (user != null) {
        context.read<CropProvider>().cargarDatosIniciales(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dk = widget.isDark;
    final screens = [
      HomeScreen(isDark: dk, onToggle: widget.onToggle),
      IAScreen(isDark: dk),
      MarketplaceScreen(isDark: dk),
      ProfileScreen(isDark: dk),
    ];

    return Scaffold(
      backgroundColor: dk ? SC.darkBg : const Color(0xFFF7FAF7),
      body: screens[_idx],
      bottomNavigationBar: _BottomNav(
        isDark: dk,
        selectedIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  1. HOME SCREEN
// ═══════════════════════════════════════════════════════════
class HomeScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  const HomeScreen({super.key, required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final dk = isDark;
    
    // Obtenemos los datos del usuario en tiempo real
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.usuarioActual;
    final nombreUsuario = user?.nombre ?? 'Agricultor';
    
    // Iniciales para el avatar
    final partes = nombreUsuario.split(' ');
    final iniciales = partes.length > 1 
        ? '${partes[0][0]}${partes[1][0]}'.toUpperCase() 
        : partes[0].substring(0, 2).toUpperCase();

    return Column(
      children: [
        // Header
        Container(
          color: dk ? SC.darkBg : SC.greenDark,
          padding: const EdgeInsets.fromLTRB(18, 52, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SembriaLogo(),
                  Row(
                    children: [
                      // Botón toggle dark/light (demo)
                      GestureDetector(
                        onTap: onToggle,
                        child: Icon(
                          dk ? Icons.light_mode : Icons.dark_mode,
                          color: SC.greenLight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      UserAvatar(initials: iniciales),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Buenas tardes,',
                style: TextStyle(fontSize: 13, color: SC.greenLight),
              ),
              const SizedBox(height: 2),
              Text(
                nombreUsuario,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: Container(
            color: dk ? SC.darkBg : const Color(0xFFF7FAF7),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(text: 'Alertas de hoy', isDark: dk),
                  const SizedBox(height: 10),
                  AlertCard(
                    isDark: dk,
                    isWarn: true,
                    icon: Icons.warning_amber_rounded,
                    title: 'Plaga en sector B',
                    description:
                        'La IA detecto pulgon en tu cultivo de tomate. Actua en las proximas 48h.',
                    linkText: 'Ver recomendacion →',
                  ),
                  const SizedBox(height: 10),
                  AlertCard(
                    isDark: dk,
                    isWarn: false,
                    icon: Icons.water_drop_outlined,
                    title: 'Lluvia manana',
                    description:
                        'Puedes suspender el riego programado sin problema.',
                  ),
                  const SizedBox(height: 18),
                  SectionLabel(text: 'Resumen del dia', isDark: dk),
                  const SizedBox(height: 10),
                  StatsGrid(isDark: dk),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  2. IA SCREEN - Subir imagen + historial
// ═══════════════════════════════════════════════════════════
class IAScreen extends StatefulWidget {
  final bool isDark;
  const IAScreen({super.key, required this.isDark});
  @override
  State<IAScreen> createState() => _IAScreenState();
}

class _IAScreenState extends State<IAScreen> {
  bool _showResult = false;
  final TextEditingController _sintomasController = TextEditingController();
  final TextEditingController _otroCultivoController = TextEditingController();
  String _cultivoSeleccionado = 'Tomate';
  XFile? _selectedFile;
  Uint8List? _selectedFileBytes;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedFile = file;
          _selectedFileBytes = bytes;
        });
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo acceder a la ${source == ImageSource.camera ? 'cámara' : 'galería'}.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarSelectorOrigen(BuildContext context) {
    final dk = widget.isDark;
    showModalBottomSheet(
      context: context,
      backgroundColor: dk ? SC.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seleccionar foto del cultivo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: dk ? Colors.white : SC.greenDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Elige el origen de la imagen para que Claude AI la analice',
                style: TextStyle(
                  fontSize: 12,
                  color: dk ? SC.textDimDk : SC.textDim,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(bCtx);
                        _pickImage(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: dk ? SC.darkBorder : SC.greenPale,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.camera_alt_outlined, size: 28, color: SC.greenMid),
                            const SizedBox(height: 8),
                            Text(
                              'Tomar Foto',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: dk ? Colors.white : SC.greenDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(bCtx);
                        _pickImage(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: dk ? SC.darkBorder : SC.greenPale,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.photo_library_outlined, size: 28, color: SC.greenMid),
                            const SizedBox(height: 8),
                            Text(
                              'Subir Galería',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: dk ? Colors.white : SC.greenDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sintomasController.dispose();
    _otroCultivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dk = widget.isDark;
    final cropProvider = context.watch<CropProvider>();
    final authProvider = context.watch<AuthProvider>();

    return _showResult
        ? IAResultScreen(
            isDark: dk,
            onBack: () => setState(() => _showResult = false),
          )
        : Stack(
            children: [
              Column(
                children: [
                  // Header
                  Container(
                    color: dk ? SC.darkBg : SC.greenDark,
                    padding: const EdgeInsets.fromLTRB(18, 52, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SembriaLogo(),
                            const Icon(
                              Icons.info_outline,
                              color: SC.greenLight,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Describe tu cultivo y toma una foto para que Claude AI lo analice',
                          style: TextStyle(fontSize: 12, color: SC.greenLight),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Expanded(
                    child: Container(
                      color: dk ? SC.darkBg : const Color(0xFFF7FAF7),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Selector de Cultivo
                            const Text(
                              '1. CULTIVO A EVALUAR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: SC.greenMid,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildCropChip('Tomate', '🍅 Tomate'),
                                const SizedBox(width: 8),
                                _buildCropChip('Soya', '🌱 Soya'),
                                const SizedBox(width: 8),
                                _buildCropChip('Maiz', '🌽 Maíz'),
                                const SizedBox(width: 8),
                                _buildCropChip('Otros', '🔍 Otros'),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (_cultivoSeleccionado == 'Otros') ...[
                              const Text(
                                'ESPECIFICA EL CULTIVO (OPCIONAL)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: SC.greenMid,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: dk ? SC.darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: dk ? SC.darkBorder : SC.greenPale,
                                    width: 0.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: _otroCultivoController,
                                  style: TextStyle(
                                    color: dk ? Colors.white : SC.greenDark,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Ej. Papa, Cebolla... o dejar vacío si se desconoce',
                                    hintStyle: TextStyle(
                                      color: dk ? SC.textDimDk : SC.textDim,
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 2. Descripción de síntomas
                            const Text(
                              '2. ¿QUÉ SÍNTOMAS OBSERVAS?',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: SC.greenMid,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: dk ? SC.darkSurface : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: dk ? SC.darkBorder : SC.greenPale,
                                  width: 0.5,
                                ),
                              ),
                              child: TextField(
                                controller: _sintomasController,
                                maxLines: 2,
                                style: TextStyle(
                                  color: dk ? Colors.white : SC.greenDark,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ej. Hojas con manchas circulares secas...',
                                  hintStyle: TextStyle(
                                    color: dk ? SC.textDimDk : SC.textDim,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 3. Zona de carga & Diagnóstico
                            const Text(
                              '3. ADJUNTAR FOTO Y DIAGNOSTICAR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: SC.greenMid,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _selectedFileBytes == null
                                ? GestureDetector(
                                    onTap: () => _mostrarSelectorOrigen(context),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 24,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: dk ? SC.darkDeep : SC.greenGhost,
                                        border: Border.all(
                                          color: dk ? SC.greenMid : SC.greenBright,
                                          width: 1.5,
                                          style: BorderStyle.solid,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              // Camera card option
                                              Column(
                                                children: [
                                                  Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: dk ? SC.darkSurface : Colors.white,
                                                      borderRadius: BorderRadius.circular(14),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.04),
                                                          blurRadius: 6,
                                                        )
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                      Icons.camera_alt_outlined,
                                                      size: 24,
                                                      color: SC.greenMid,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Usar Cámara',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: dk ? Colors.white70 : SC.greenDark,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Gallery card option
                                              Column(
                                                children: [
                                                  Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: dk ? SC.darkSurface : Colors.white,
                                                      borderRadius: BorderRadius.circular(14),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.04),
                                                          blurRadius: 6,
                                                        )
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                      Icons.photo_library_outlined,
                                                      size: 24,
                                                      color: SC.greenMid,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Subir Galería',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: dk ? Colors.white70 : SC.greenDark,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Toca aquí para seleccionar o tomar una foto',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: dk ? SC.greenLight : SC.greenMid,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            height: 200,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.06),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: dk ? SC.greenMid : SC.greenBright,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(14),
                                              child: Image.memory(
                                                _selectedFileBytes!,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedFile = null;
                                                  _selectedFileBytes = null;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(5),
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => _mostrarSelectorOrigen(context),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black87,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.sync, color: Colors.white, size: 10),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Cambiar',
                                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final String cultivoElegido = _cultivoSeleccionado == 'Otros'
                                                ? (_otroCultivoController.text.trim().isNotEmpty
                                                    ? _otroCultivoController.text.trim()
                                                    : 'Desconocido')
                                                : _cultivoSeleccionado;

                                            final desc = _sintomasController.text.trim();
                                            final textToAnalyze = desc.isNotEmpty 
                                                ? desc 
                                                : 'Tengo síntomas sospechosos en las hojas de mi planta de $cultivoElegido';
                                            
                                            final userZone = authProvider.usuarioActual?.zonaSantaCruz ?? 'Santa Cruz';

                                            final diag = await cropProvider.analizarCultivo(
                                              descripcion: textToAnalyze,
                                              imageAbsolutePath: _selectedFile?.path ?? 'camara_captura.jpg',
                                              imageBytes: _selectedFileBytes,
                                              cultivo: cultivoElegido,
                                              zona: userZone,
                                            );

                                            if (diag != null) {
                                              _sintomasController.clear();
                                              _otroCultivoController.clear();
                                              setState(() {
                                                _selectedFile = null;
                                                _selectedFileBytes = null;
                                                _showResult = true;
                                              });
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: SC.greenMid,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            elevation: 0,
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.psychology, size: 16),
                                              SizedBox(width: 6),
                                              Text(
                                                'Iniciar Diagnóstico con Claude AI',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: 20),

                            // 4. Historial
                            SectionLabel(text: 'Análisis recientes', isDark: dk),
                            const SizedBox(height: 10),

                            cropProvider.diagnosticos.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'No tienes diagnósticos previos.',
                                        style: TextStyle(color: dk ? SC.textDimDk : SC.textDim),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: cropProvider.diagnosticos.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (ctx, idx) {
                                      final item = cropProvider.diagnosticos[idx];
                                      final isHighRisk = item.resultadoJson.nivelRiesgo.toLowerCase() == 'alto' ||
                                                         item.resultadoJson.nivelRiesgo.toLowerCase() == 'crítico' ||
                                                         item.resultadoJson.nivelRiesgo.toLowerCase() == 'critico';
                                      return GestureDetector(
                                        onTap: () {
                                          cropProvider.seleccionarDiagnostico(item);
                                          setState(() => _showResult = true);
                                        },
                                        child: _HistorialItem(
                                          isDark: dk,
                                          isWarn: isHighRisk,
                                          icon: isHighRisk ? Icons.bug_report_outlined : Icons.eco_outlined,
                                          cultivo: '${item.cultivo} · ${item.zona}',
                                          resultado: '${isHighRisk ? '⚠' : '✓'} ${item.resultadoJson.diagnosticoPrincipal}',
                                          fecha: 'Reciente',
                                        ),
                                      );
                                    },
                                  ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Spinner Loader cuando está analizando con Claude
              if (cropProvider.isLoading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: dk ? SC.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(SC.greenMid)),
                          const SizedBox(height: 16),
                          Text(
                            'Claude AI procesando cultivo...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: dk ? Colors.white : SC.greenDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Analizando estructura foliar y patógenos...',
                            style: TextStyle(
                              fontSize: 11,
                              color: dk ? SC.textDimDk : SC.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
  }

  Widget _buildCropChip(String val, String text) {
    final active = _cultivoSeleccionado == val;
    final dk = widget.isDark;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _cultivoSeleccionado = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active 
                ? (dk ? SC.darkDeep : SC.greenGhost) 
                : (dk ? SC.darkSurface : Colors.white),
            border: Border.all(
              color: active ? SC.greenMid : (dk ? SC.darkBorder : SC.greenPale),
              width: active ? 1.5 : 0.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active 
                  ? (dk ? SC.greenLight : SC.greenMid) 
                  : (dk ? Colors.white70 : SC.greenDark),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistorialItem extends StatelessWidget {
  final bool isDark, isWarn;
  final IconData icon;
  final String cultivo, resultado, fecha;
  const _HistorialItem({
    required this.isDark,
    required this.isWarn,
    required this.icon,
    required this.cultivo,
    required this.resultado,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    final dk = isDark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dk ? SC.darkSurface : Colors.white,
        border: Border.all(
          color: dk ? SC.darkBorder : SC.greenPale,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isWarn
                  ? (dk ? const Color(0xFF2A1800) : const Color(0xFFFFF3E0))
                  : (dk ? SC.darkDeep : SC.greenGhost),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isWarn
                  ? (dk ? SC.warnIconDk : SC.warnIcon)
                  : (dk ? SC.greenLight : SC.greenMid),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cultivo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: dk ? Colors.white : SC.greenDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  resultado,
                  style: TextStyle(
                    fontSize: 11,
                    color: isWarn
                        ? (dk ? SC.warnIconDk : SC.warnIcon)
                        : (dk ? SC.greenLight : SC.greenBright),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fecha,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 16,
            color: dk ? SC.darkBorder : SC.greenPale,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  3. IA RESULT SCREEN - Resultado del diagnóstico
// ═══════════════════════════════════════════════════════════
class IAResultScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onBack;
  const IAResultScreen({super.key, required this.isDark, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final dk = isDark;
    final cropProvider = context.watch<CropProvider>();
    
    // Obtenemos el diagnóstico activo, o usamos el primero por defecto si está vacío
    final DiagnosticoModel? diag = cropProvider.diagnosticoActivo ?? 
        (cropProvider.diagnosticos.isNotEmpty ? cropProvider.diagnosticos.first : null);

    if (diag == null) {
      return Scaffold(
        backgroundColor: dk ? SC.darkBg : const Color(0xFFF7FAF7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No hay diagnóstico seleccionado',
                style: TextStyle(color: dk ? Colors.white : SC.greenDark),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(backgroundColor: SC.greenMid),
                child: const Text('Volver atrás'),
              ),
            ],
          ),
        ),
      );
    }

    final resultadoAi = diag.resultadoJson;
    final isHighRisk = resultadoAi.nivelRiesgo.toLowerCase() == 'alto' || 
                       resultadoAi.nivelRiesgo.toLowerCase() == 'crítico' ||
                       resultadoAi.nivelRiesgo.toLowerCase() == 'critico';

    // Filtrar un par de productos recomendados según la categoría
    final productosRecomendados = cropProvider.productos.take(2).toList();

    return Column(
      children: [
        // Header con botón atrás
        Container(
          color: dk ? SC.darkBg : SC.greenDark,
          padding: const EdgeInsets.fromLTRB(18, 52, 18, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: const Icon(
                  Icons.arrow_back,
                  color: SC.greenLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Resultado ',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE8F5E9),
                      ),
                    ),
                    TextSpan(
                      text: 'IA',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: SC.greenLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Body scrolleable
        Expanded(
          child: Container(
            color: dk ? SC.darkBg : const Color(0xFFF7FAF7),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen analizada
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: dk ? SC.darkBorder : SC.greenPale,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(13),
                          ),
                          child: Image.network(
                            diag.imagenUrl,
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 110,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: dk
                                        ? [SC.darkDeep, SC.greenDark]
                                        : [SC.greenPale, SC.greenGhost],
                                  ),
                                ),
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 44,
                                  color: (dk ? SC.greenBright : SC.greenMid)
                                      .withOpacity(0.4),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: dk ? SC.darkSurface : Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(13),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'cultivo_${diag.cultivo.toLowerCase()}_captura.jpg',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: dk ? Colors.white : SC.greenDark,
                                ),
                              ),
                              Text(
                                'Sector ${diag.zona}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Diagnóstico
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: dk ? SC.darkSurface : Colors.white,
                      border: Border.all(
                        color: dk ? SC.darkBorder : SC.greenPale,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isHighRisk
                                    ? (dk ? const Color(0xFF2A1800) : const Color(0xFFFFF3E0))
                                    : (dk ? SC.darkDeep : SC.greenGhost),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isHighRisk ? Icons.bug_report_outlined : Icons.eco_outlined,
                                size: 22,
                                color: isHighRisk ? (dk ? SC.warnIconDk : SC.warnIcon) : SC.greenMid,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resultadoAi.diagnosticoPrincipal,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: dk ? Colors.white : SC.greenDark,
                                    ),
                                  ),
                                  Text(
                                    resultadoAi.categoria,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: dk ? SC.textDimDk : SC.textDim,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Barra de riesgo
                        Row(
                          children: [
                            Text(
                              'Riesgo',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: dk ? SC.textDimDk : SC.textDim),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: resultadoAi.porcentajeRiesgo,
                                  minHeight: 7,
                                  backgroundColor: dk ? SC.darkDeep : SC.greenGhost,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isHighRisk ? SC.warnIcon : SC.greenMid,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isHighRisk
                                    ? (dk ? const Color(0xFF2A1800) : const Color(0xFFFFF3E0))
                                    : (dk ? SC.darkDeep : SC.greenGhost),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                resultadoAi.nivelRiesgo,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isHighRisk ? (dk ? SC.warnIconDk : SC.warnIcon) : SC.greenMid,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          resultadoAi.detalles,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: dk ? Colors.white70 : SC.greenDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Plan de acción
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: dk ? SC.darkDeep : SC.greenDark,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.checklist,
                              color: SC.greenLight,
                              size: 18,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Plan de acción recomendado por Claude',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Mapeo dinámico de los pasos de Claude AI
                        if (resultadoAi.planAccion.isEmpty)
                          const Text('No hay pasos prescritos.', style: TextStyle(color: Colors.white70, fontSize: 11))
                        else
                          Column(
                            children: List.generate(
                              resultadoAi.planAccion.length,
                              (idx) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _SolStep(
                                  num: '${idx + 1}',
                                  text: resultadoAi.planAccion[idx],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Productos recomendados
                  SectionLabel(text: 'Productos recomendados', isDark: dk),
                  const SizedBox(height: 10),
                  
                  if (productosRecomendados.isEmpty)
                    const Text('No hay productos disponibles.')
                  else
                    Column(
                      children: productosRecomendados.map((prod) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: dk ? SC.darkSurface : Colors.white,
                              border: Border.all(
                                color: dk ? SC.darkBorder : SC.greenPale,
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    prod.imagenUrl,
                                    width: 42,
                                    height: 42,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 42,
                                      height: 42,
                                      color: SC.greenGhost,
                                      child: const Icon(Icons.shopping_bag_outlined, size: 20, color: SC.greenMid),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prod.nombre,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: dk ? Colors.white : SC.greenDark,
                                        ),
                                      ),
                                      Text(
                                        prod.vendedor,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: dk ? SC.textDimDk : SC.textDim,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${prod.precioBob.toInt()} BOB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: dk ? SC.greenLight : SC.greenMid,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        final exito = await cropProvider.comprarProducto(
                                          productoId: prod.id,
                                          cantidad: 1,
                                        );
                                        if (exito && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('¡Has ordenado ${prod.nombre} con éxito!'),
                                              backgroundColor: SC.greenMid,
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: SC.greenMid,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Pedir',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 14),

                  // Botón carrito general
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Procesar un pedido por todos los insumos recomendados de una sola vez
                        for (var prod in productosRecomendados) {
                          await cropProvider.comprarProducto(productoId: prod.id, cantidad: 1);
                        }
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('🛒 Carrito SembrIA'),
                              content: const Text('¡Se han generado los pedidos para los insumos recomendados! Nuestro vendedor asociado en Santa Cruz se contactará contigo para coordinar la entrega.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Excelente', style: TextStyle(color: SC.greenMid)),
                                )
                              ],
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Comprar todo el plan de insumos',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SC.greenMid,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SolStep extends StatelessWidget {
  final String num, text;
  const _SolStep({required this.num, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: SC.greenMid, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            num,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: SC.greenLight,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  4. MARKETPLACE SCREEN
// ═══════════════════════════════════════════════════════════
class MarketplaceScreen extends StatefulWidget {
  final bool isDark;
  const MarketplaceScreen({super.key, required this.isDark});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  // Navigation: Tienda Oficial vs Entre Agricultores
  bool _isP2P = true; // Selected by default as per screenshot

  // Tienda Oficial state
  int _catIdx = 0;
  String _searchQuery = '';
  final _cats = [
    {'icon': Icons.water_drop_outlined, 'label': 'Pesticidas', 'key': 'pesticidas'},
    {'icon': Icons.science_outlined, 'label': 'Fertilizantes', 'key': 'fertiliz'},
    {'icon': Icons.construction_outlined, 'label': 'Herramientas', 'key': 'herram'},
    {'icon': Icons.grass_outlined, 'label': 'Semillas', 'key': 'semill'},
  ];

  // Entre Agricultores (P2P) state
  int _p2pCatIdx = 0;
  String _p2pSearchQuery = '';
  final _p2pCats = [
    'Todos',
    'Cosecha',
    'Semillas',
    'Herramientas',
    'Animales',
    'Terrenos',
    'Services', // Labeled "Servicios" in display
    'Otros'
  ];

  // Map Spanish display labels
  String _getP2PDisplayLabel(String key) {
    if (key == 'Services') return 'Servicios';
    return key;
  }

  // Image upload state inside modal
  XFile? _p2pFile;
  Uint8List? _p2pFileBytes;

  Future<void> _pickP2PImage(ImageSource source, StateSetter modalSetState) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        modalSetState(() {
          _p2pFile = file;
          _p2pFileBytes = bytes;
        });
      }
    } catch (e) {
      print('Error al seleccionar imagen P2P: $e');
    }
  }

  void _mostrarSelectorOrigenP2P(BuildContext context, StateSetter modalSetState) {
    final dk = widget.isDark;
    showModalBottomSheet(
      context: context,
      backgroundColor: dk ? SC.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seleccionar foto del producto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: dk ? Colors.white : SC.greenDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Elige el origen de la imagen para tu publicación P2P',
                style: TextStyle(
                  fontSize: 12,
                  color: dk ? SC.textDimDk : SC.textDim,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(bCtx);
                        _pickP2PImage(ImageSource.camera, modalSetState);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: dk ? SC.darkBorder : SC.greenPale,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.camera_alt_outlined, size: 28, color: SC.greenMid),
                            const SizedBox(height: 8),
                            Text(
                              'Tomar Foto',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: dk ? Colors.white : SC.greenDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(bCtx);
                        _pickP2PImage(ImageSource.gallery, modalSetState);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: dk ? SC.darkBorder : SC.greenPale,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.photo_library_outlined, size: 28, color: SC.greenMid),
                            const SizedBox(height: 8),
                            Text(
                              'Subir Galería',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: dk ? Colors.white : SC.greenDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarPublicarP2PModal(BuildContext context) {
    final dk = widget.isDark;
    final authProvider = context.read<AuthProvider>();
    final cropProvider = context.read<CropProvider>();
    final String defaultUser = authProvider.usuarioActual?.nombre ?? 'Agricultor';

    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final whatsappCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    String catSel = 'Cosecha';
    String zonaSel = 'Norte Integrado';
    bool gratisSel = false;

    setState(() {
      _p2pFile = null;
      _p2pFileBytes = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dk ? SC.darkBg : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (mCtx) => StatefulBuilder(
        builder: (context, modalSetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Banner header matching the screenshot
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: dk ? const Color(0xFF2C2419) : const Color(0xFFFFFDF4),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Publicar en el mercado P2P',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: dk ? const Color(0xFFFFD54F) : const Color(0xFF4E342E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Los compradores te contactarán por WhatsApp',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: dk ? Colors.yellow[300] : const Color(0xFFEF6C00),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TÍTULO Label
                      _buildFormLabel('TÍTULO'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: tituloCtrl,
                        style: TextStyle(color: dk ? Colors.white : Colors.black87, fontSize: 13),
                        decoration: _buildFormInputDecoration(
                          hintText: 'Ej. 10 qq de soya cosechada',
                          dk: dk,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // DESCRIPCIÓN Label
                      _buildFormLabel('DESCRIPCIÓN'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descCtrl,
                        maxLines: 4,
                        style: TextStyle(color: dk ? Colors.white : Colors.black87, fontSize: 13),
                        decoration: _buildFormInputDecoration(
                          hintText: '',
                          dk: dk,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // FOTO DEL PRODUCTO Label with custom dashed border matching screenshot
                      _buildFormLabel('FOTO DEL PRODUCTO (OPCIONAL)'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _mostrarSelectorOrigenP2P(context, modalSetState),
                        child: CustomPaint(
                          painter: _DashedBorderPainter(
                            color: dk ? const Color(0xFFFFD54F) : const Color(0xFFFFB74D),
                            borderRadius: 16.0,
                            strokeWidth: 1.2,
                            gap: 4.0,
                            dashLength: 6.0,
                          ),
                          child: Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: dk ? const Color(0xFF2A2A19) : const Color(0xFFFFFDF4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _p2pFileBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Image.memory(
                                            _p2pFileBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () {
                                              modalSetState(() {
                                                _p2pFile = null;
                                                _p2pFileBytes = null;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.06),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_outlined,
                                          color: Color(0xFFEF6C00),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Toca para subir foto',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: dk ? Colors.yellow[300] : const Color(0xFF5D4037),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'JPG, PNG — máx. 5 MB',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: dk ? Colors.yellow[100]!.withOpacity(0.6) : const Color(0xFF8D6E63),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // CATEGORÍA / ZONA row side by side matching screenshot
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormLabel('CATEGORÍA'),
                                const SizedBox(height: 6),
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: dk ? SC.darkSurface : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: dk ? SC.darkBorder : Colors.grey[300]!,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: catSel,
                                      isExpanded: true,
                                      dropdownColor: dk ? SC.darkSurface : Colors.white,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: dk ? Colors.grey[400] : Colors.black87,
                                        size: 20,
                                      ),
                                      style: TextStyle(
                                        color: dk ? Colors.white : Colors.black87,
                                        fontSize: 13,
                                      ),
                                      items: _p2pCats
                                          .where((c) => c != 'Todos')
                                          .map((c) => DropdownMenuItem<String>(
                                                value: _getP2PDisplayLabel(c),
                                                child: Text(_getP2PDisplayLabel(c)),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          modalSetState(() => catSel = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormLabel('ZONA SANTA CRUZ'),
                                const SizedBox(height: 6),
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: dk ? SC.darkSurface : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: dk ? SC.darkBorder : Colors.grey[300]!,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: zonaSel,
                                      isExpanded: true,
                                      dropdownColor: dk ? SC.darkSurface : Colors.white,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: dk ? Colors.grey[400] : Colors.black87,
                                        size: 20,
                                      ),
                                      style: TextStyle(
                                        color: dk ? Colors.white : Colors.black87,
                                        fontSize: 13,
                                      ),
                                      items: const [
                                        'Norte Integrado',
                                        'Chiquitanía',
                                        'Valles Cruceños',
                                        'Montero',
                                        'Warnes',
                                        'Okinawa',
                                        'Cotoca',
                                        'Mineros',
                                        'Santa Cruz de la Sierra'
                                      ].map((z) => DropdownMenuItem<String>(
                                                value: z,
                                                child: Text(z),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          modalSetState(() => zonaSel = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // WHATSAPP Label
                      _buildFormLabel('WHATSAPP (CON CÓDIGO 591)'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: whatsappCtrl,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: dk ? Colors.white : Colors.black87, fontSize: 13),
                        decoration: _buildFormInputDecoration(
                          hintText: '59171234567',
                          dk: dk,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Checkbox Gratis matching screenshot
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: gratisSel,
                              activeColor: const Color(0xFFEF6C00),
                              checkColor: Colors.white,
                              side: BorderSide(
                                color: dk ? Colors.grey[600]! : Colors.grey[400]!,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  modalSetState(() {
                                    gratisSel = val;
                                    if (gratisSel) {
                                      precioCtrl.text = '0';
                                    } else {
                                      precioCtrl.clear();
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              modalSetState(() {
                                gratisSel = !gratisSel;
                                if (gratisSel) {
                                  precioCtrl.text = '0';
                                } else {
                                  precioCtrl.clear();
                                }
                              });
                            },
                            child: Text(
                              'Es gratis / trueque',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: dk ? const Color(0xFFCFD8DC) : const Color(0xFF37474F),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // PRECIO Label
                      if (!gratisSel) ...[
                        _buildFormLabel('PRECIO (BOB)'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: precioCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: dk ? Colors.white : Colors.black87, fontSize: 13),
                          decoration: _buildFormInputDecoration(
                            hintText: '',
                            dk: dk,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      const SizedBox(height: 4),
                      
                      // Cancelar / Publicar buttons row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(mCtx),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: dk ? SC.darkBorder : Colors.grey[300]!),
                                backgroundColor: dk ? SC.darkSurface : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: dk ? Colors.white70 : const Color(0xFF37474F),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final title = tituloCtrl.text.trim();
                                final desc = descCtrl.text.trim();
                                final phone = whatsappCtrl.text.trim();
                                final priceText = precioCtrl.text.trim();
                                final double price = gratisSel ? 0.0 : (double.tryParse(priceText) ?? 0.0);

                                if (title.isEmpty || desc.isEmpty || phone.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Por favor, rellena todos los campos.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                String? imageToSave;
                                if (_p2pFileBytes != null) {
                                  imageToSave = catSel.contains('Herramientas')
                                      ? 'https://images.unsplash.com/photo-1595273670150-bd0c3c392e46?auto=format&fit=crop&q=80&w=400'
                                      : 'https://images.unsplash.com/photo-1574316071802-0d684efa7bf5?auto=format&fit=crop&q=80&w=400';
                                }

                                final newP2P = PublicacionP2PModel(
                                  id: 'p2p-${DateTime.now().millisecondsSinceEpoch}',
                                  usuarioId: defaultUser,
                                  titulo: title,
                                  descripcion: desc,
                                  precioBob: price,
                                  esGratis: gratisSel || price == 0.0,
                                  categoria: catSel,
                                  zonaSantaCruz: zonaSel,
                                  whatsappNumero: phone,
                                  estado: 'Activo',
                                  vistas: 0,
                                  imagenUrl: imageToSave,
                                );

                                final ok = await cropProvider.crearPublicacionP2P(newP2P);
                                if (ok && context.mounted) {
                                  Navigator.pop(mCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('¡Producto publicado con éxito en el mercado P2P!'),
                                      backgroundColor: SC.greenMid,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF6C00),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Publicar',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    final dk = widget.isDark;
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: dk ? const Color(0xFFCFD8DC) : const Color(0xFF37474F),
      ),
    );
  }

  InputDecoration _buildFormInputDecoration({required String hintText, required bool dk}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: dk ? SC.textDimDk : Colors.grey[400],
        fontSize: 12,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!, width: 0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFEF6C00), width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  void _contactarWhatsApp(String telefono, String titulo) async {
    final String message = Uri.encodeComponent('Hola! Estoy interesado en tu publicación de "$titulo" en SembrIA.');
    final String url = 'https://wa.me/$telefono?text=$message';
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('No se pudo abrir WhatsApp: $url');
      }
    } catch (e) {
      print('Error al contactar por WhatsApp: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dk = widget.isDark;
    final cropProvider = context.watch<CropProvider>();

    return Column(
      children: [
        // Tab switcher (Tienda Oficial vs Entre Agricultores)
        Container(
          color: dk ? SC.darkBg : SC.greenDark,
          padding: const EdgeInsets.fromLTRB(18, 52, 18, 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SembriaLogo(),
                  if (!_isP2P) ...[
                    GestureDetector(
                      onTap: () {
                        // Show orders
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('📋 Pedidos en Curso'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: cropProvider.productos.any((p) => p.stock < 15)
                                  ? ListView(
                                      shrinkWrap: true,
                                      children: cropProvider.productos
                                          .where((p) => p.stock < 15)
                                          .map((p) => ListTile(
                                                leading: const Icon(Icons.check_circle, color: SC.greenMid),
                                                title: Text(p.nombre, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                subtitle: Text('Estado: Pendiente de entrega', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                                                trailing: Text('${p.precioBob.toInt()} BOB', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              ))
                                          .toList(),
                                    )
                                  : const Text('No has realizado pedidos hoy.'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cerrar', style: TextStyle(color: SC.greenMid)),
                              )
                            ],
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            color: SC.greenLight,
                            size: 24,
                          ),
                          if (cropProvider.productos.where((p) => p.stock < 15).isNotEmpty)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: SC.greenLight,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${cropProvider.productos.where((p) => p.stock < 15).length}',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: SC.greenDark,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              // Segmented Double Tab matching the Screenshot
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: dk ? SC.darkSurface : Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        // Tienda Oficial Tab
                        GestureDetector(
                          onTap: () => setState(() => _isP2P = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isP2P
                                  ? (dk ? SC.greenMid : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                              border: !_isP2P
                                  ? Border.all(color: dk ? SC.greenLight : Colors.black87, width: 1.0)
                                  : null,
                              boxShadow: !_isP2P
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                const Text('🏬 ', style: TextStyle(fontSize: 14)),
                                Text(
                                  'Tienda Oficial',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: !_isP2P
                                        ? (dk ? Colors.white : SC.greenDark)
                                        : (dk ? Colors.white70 : Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Entre Agricultores Tab
                        GestureDetector(
                          onTap: () => setState(() => _isP2P = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isP2P
                                  ? (dk ? SC.greenMid : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                              border: _isP2P
                                  ? Border.all(color: dk ? SC.greenLight : Colors.black87, width: 1.2)
                                  : null,
                              boxShadow: _isP2P
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                const Text('🤝 ', style: TextStyle(fontSize: 14)),
                                Text(
                                  'Entre Agricultores',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isP2P
                                        ? (dk ? Colors.white : SC.greenDark)
                                        : (dk ? Colors.white70 : Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Body area
        Expanded(
          child: Container(
            color: dk ? SC.darkBg : const Color(0xFFF7FAF7),
            child: !_isP2P
                ? _buildOfficialShop(context, dk, cropProvider)
                : _buildP2PForum(context, dk, cropProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildOfficialShop(BuildContext context, bool dk, CropProvider cropProvider) {
    // Official marketplace filter logic
    final todosProductos = cropProvider.productos;
    final catKey = _cats[_catIdx]['key'] as String;
    var filtrados = todosProductos.where((p) => p.categoria.toLowerCase().contains(catKey)).toList();

    if (_searchQuery.isNotEmpty) {
      filtrados = filtrados.where((p) {
        return p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               p.descripcion.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    final destacados = filtrados.take(2).toList();
    final restantes = filtrados.skip(2).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: dk ? SC.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: dk ? SC.darkBorder : SC.greenPale, width: 0.5),
            ),
            child: TextField(
              style: TextStyle(color: dk ? Colors.white : SC.greenDark, fontSize: 13),
              onChanged: (text) => setState(() => _searchQuery = text),
              decoration: InputDecoration(
                icon: const Icon(Icons.search, color: SC.greenMid, size: 17),
                hintText: 'Buscar agro-insumos...',
                hintStyle: TextStyle(fontSize: 13, color: dk ? SC.textDimDk : SC.textDim),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Categories
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final active = i == _catIdx;
                return GestureDetector(
                  onTap: () => setState(() => _catIdx = i),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: active
                              ? (dk ? SC.darkDeep : SC.greenGhost)
                              : (dk ? SC.darkSurface : Colors.white),
                          border: Border.all(
                            color: active ? SC.greenMid : (dk ? SC.darkBorder : SC.greenPale),
                            width: active ? 1.5 : 0.5,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _cats[i]['icon'] as IconData,
                          size: 22,
                          color: active
                              ? (dk ? SC.greenLight : SC.greenMid)
                              : (dk ? SC.textDimDk : SC.textDim),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _cats[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          color: active ? (dk ? SC.greenLight : SC.greenMid) : (dk ? SC.textDimDk : SC.textDim),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Destacados
          SectionLabel(text: 'Destacados', isDark: dk),
          const SizedBox(height: 10),
          
          filtrados.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: dk ? SC.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No hay insumos en esta categoría.',
                      style: TextStyle(color: dk ? SC.textDimDk : SC.textDim),
                    ),
                  ),
                )
              : GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.82,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: destacados.map((prod) {
                    return _DestCard(
                      dk: dk,
                      icon: _cats[_catIdx]['icon'] as IconData,
                      name: prod.nombre,
                      sub: prod.vendedor,
                      price: '${prod.precioBob.toInt()} BOB',
                      onTapAdd: () async {
                        final ok = await cropProvider.comprarProducto(productoId: prod.id, cantidad: 1);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('¡${prod.nombre} agregado al pedido!'),
                              backgroundColor: SC.greenMid,
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
          const SizedBox(height: 16),

          // Restantes
          if (restantes.isNotEmpty) ...[
            SectionLabel(text: 'Más productos', isDark: dk),
            const SizedBox(height: 10),
            Column(
              children: restantes.map((prod) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: GestureDetector(
                    onTap: () async {
                      final ok = await cropProvider.comprarProducto(productoId: prod.id, cantidad: 1);
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('¡${prod.nombre} agregado al pedido!'),
                            backgroundColor: SC.greenMid,
                          ),
                        );
                      }
                    },
                    child: _ProductListCard(
                      isDark: dk,
                      icon: _cats[_catIdx]['icon'] as IconData,
                      name: prod.nombre,
                      sub: prod.vendedor,
                      price: '${prod.precioBob.toInt()} BOB',
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildP2PForum(BuildContext context, bool dk, CropProvider cropProvider) {
    final todosP2P = cropProvider.publicacionesP2P;
    
    // 1. Filtrar por categoría de chip
    var filtrados = todosP2P;
    if (_p2pCatIdx > 0) {
      final String filterCat = _getP2PDisplayLabel(_p2pCats[_p2pCatIdx]);
      filtrados = filtrados.where((p) => p.categoria.toLowerCase() == filterCat.toLowerCase()).toList();
    }

    // 2. Filtrar por búsqueda
    if (_p2pSearchQuery.isNotEmpty) {
      filtrados = filtrados.where((p) {
        return p.titulo.toLowerCase().contains(_p2pSearchQuery.toLowerCase()) ||
               p.descripcion.toLowerCase().contains(_p2pSearchQuery.toLowerCase());
      }).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador + Botón "Vende tu Producto" Row matching the Screenshot
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: dk ? SC.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: dk ? SC.darkBorder : Colors.grey[300]!,
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    style: TextStyle(color: dk ? Colors.white : SC.greenDark, fontSize: 13),
                    onChanged: (text) => setState(() => _p2pSearchQuery = text),
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: dk ? SC.greenLight : Colors.grey[400]!, size: 18),
                      hintText: 'Buscar cosechas, herramientas...',
                      hintStyle: TextStyle(fontSize: 13, color: dk ? SC.textDimDk : Colors.grey[400]!),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Megaphone orange button
              ElevatedButton(
                onPressed: () => _mostrarPublicarP2PModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C00), // Orange color from mockup
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('📣 ', style: TextStyle(fontSize: 12)),
                    Text(
                      'Vende tu Producto',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal Categories row matching the Screenshot
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _p2pCats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final cat = _p2pCats[idx];
                final displayLabel = _getP2PDisplayLabel(cat);
                final active = idx == _p2pCatIdx;
                return GestureDetector(
                  onTap: () => setState(() => _p2pCatIdx = idx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFEF6C00) : (dk ? SC.darkSurface : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? const Color(0xFFEF6C00) : (dk ? SC.darkBorder : Colors.grey[200]!),
                        width: 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      displayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        color: active ? Colors.white : (dk ? Colors.white70 : Colors.grey[700]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Grid list of products matching the Screenshot
          filtrados.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: dk ? SC.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No hay publicaciones en esta categoría.',
                      style: TextStyle(color: dk ? SC.textDimDk : SC.textDim),
                    ),
                  ),
                )
              : GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.72,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: filtrados.map((item) {
                    return _P2PProductCard(
                      dk: dk,
                      prod: item,
                      onWhatsApp: () {
                        // Increment local views
                        cropProvider.verPublicacionP2P(item.id);
                        _contactarWhatsApp(item.whatsappNumero, item.titulo);
                      },
                      onTap: () {
                        cropProvider.verPublicacionP2P(item.id);
                      },
                    );
                  }).toList(),
                ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _P2PProductCard extends StatelessWidget {
  final bool dk;
  final PublicacionP2PModel prod;
  final VoidCallback onWhatsApp;
  final VoidCallback onTap;
  const _P2PProductCard({
    required this.dk,
    required this.prod,
    required this.onWhatsApp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFree = prod.esGratis || prod.precioBob == 0.0;
    
    // Categoría color mapping
    Color catTextColor = Colors.brown[700]!;
    if (prod.categoria == 'Herramientas') {
      catTextColor = Colors.orange[700]!;
    } else if (prod.categoria == 'Semillas') {
      catTextColor = Colors.green[700]!;
    }

    return Container(
      decoration: BoxDecoration(
        color: dk ? SC.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dk ? SC.darkBorder : Colors.grey[200]!,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Area with Overlays
          Expanded(
            child: Stack(
              children: [
                // Image
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: dk ? SC.darkDeep : SC.greenGhost,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: prod.imagenUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          child: Image.network(
                            prod.imagenUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_outlined, size: 28, color: SC.greenMid),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.construction_outlined,
                            size: 36,
                            color: Color(0xFFBCAAA4),
                          ),
                        ),
                ),
                // Category Tag overlay (Top Left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Text(
                      prod.categoria,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: catTextColor,
                      ),
                    ),
                  ),
                ),
                // GRATIS tag overlay (Top Right)
                if (isFree)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676), // Bright Green
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'GRATIS',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Body Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prod.titulo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: dk ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  prod.descripcion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: dk ? SC.textDimDk : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price tag
                    Text(
                      isFree ? 'Gratis' : '${prod.precioBob.toInt()} BOB',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isFree ? const Color(0xFF00C853) : const Color(0xFFEF6C00),
                      ),
                    ),
                    // Vendor details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          prod.usuarioId, // Vendor name
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: dk ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${prod.vistas} vistas',
                          style: TextStyle(
                            fontSize: 9,
                            color: dk ? SC.textDimDk : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // WhatsApp Button
                GestureDetector(
                  onTap: onWhatsApp,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676), // Bright Green WhatsApp
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_outlined,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Contactar por WhatsApp',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DestCard extends StatelessWidget {
  final bool dk;
  final IconData icon;
  final String name, sub, price;
  final VoidCallback onTapAdd;
  const _DestCard({
    required this.dk,
    required this.icon,
    required this.name,
    required this.sub,
    required this.price,
    required this.onTapAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dk ? SC.darkSurface : Colors.white,
        border: Border.all(
          color: dk ? SC.darkBorder : SC.greenPale,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: dk ? SC.darkDeep : SC.greenGhost,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 32,
                  color: dk ? SC.greenLight : SC.greenMid,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: dk ? Colors.white : SC.greenDark,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: dk ? SC.textDimDk : SC.textDim,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: dk ? SC.greenLight : SC.greenMid,
                      ),
                    ),
                    GestureDetector(
                      onTap: onTapAdd,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: SC.greenMid,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  5. PROFILE SCREEN
// ═══════════════════════════════════════════════════════════
class ProfileScreen extends StatelessWidget {
  final bool isDark;
  const ProfileScreen({super.key, required this.isDark});

  void _mostrarUpgradeModal(BuildContext context, AuthProvider authProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SuscripcionesScreen(isDark: isDark),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9C4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: SC.warnIcon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dk = isDark;
    
    // Obtenemos los datos del provider de autenticación
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.usuarioActual;
    
    // Obtenemos los datos de cultivos del crop provider
    final cropProvider = context.watch<CropProvider>();

    final nombreUsuario = user?.nombre ?? 'Juan Rojas';
    final cultivoActual = user?.cultivoPrincipal ?? 'Tomate';
    final planActual = user?.plan ?? 'Gratuito';
    final zonaUsuario = user?.zonaSantaCruz ?? 'Montero, Santa Cruz';

    final String nombreConIcono = planActual.contains('Pro') 
        ? '$nombreUsuario 👑' 
        : planActual.contains('Empresa') 
            ? '$nombreUsuario 🏢' 
            : nombreUsuario;

    // Iniciales dinámicas
    final partes = nombreUsuario.split(' ');
    final iniciales = partes.length > 1 
        ? '${partes[0][0]}${partes[1][0]}'.toUpperCase() 
        : partes[0].substring(0, 2).toUpperCase();

    // Estadísticas dinámicas
    final countCultivos = cropProvider.diagnosticos.map((d) => d.cultivo.toLowerCase().trim()).toSet().length;
    final countDiagnosticos = cropProvider.diagnosticos.length;
    final countPedidos = cropProvider.productos.where((p) => p.stock < 15).length; // Sesión pedidos

    return Column(
      children: [
        // Header
        Container(
          color: dk ? SC.darkBg : SC.greenDark,
          padding: const EdgeInsets.fromLTRB(18, 52, 18, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SembriaLogo(),
                  const Icon(
                    Icons.settings_outlined,
                    color: SC.greenLight,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: SC.greenMid,
                    child: Text(
                      iniciales,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreConIcono,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: SC.greenLight,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              zonaUsuario,
                              style: const TextStyle(
                                fontSize: 12,
                                color: SC.greenLight,
                              ),
                            ),
                          ],
                        ),
                        // Plan Pill Badge
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: planActual.contains('Pro') 
                                ? const Color(0xFFFFD54F)
                                : planActual.contains('Empresa')
                                    ? const Color(0xFF2979FF)
                                    : SC.greenMid,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PLAN: ${planActual.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: planActual.contains('Pro') || planActual.contains('Empresa')
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '✏ Editar',
                      style: TextStyle(fontSize: 12, color: SC.greenLight),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: Container(
            color: dk ? SC.darkBg : const Color(0xFFF7FAF7),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats strip dinámico
                  Row(
                    children: [
                      Expanded(
                        child: _StatPill(
                          dk: dk,
                          icon: Icons.eco_outlined,
                          value: '${countCultivos == 0 ? 1 : countCultivos}',
                          label: 'Cultivos',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatPill(
                          dk: dk,
                          icon: Icons.psychology_outlined,
                          value: '$countDiagnosticos',
                          label: 'Análisis IA',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatPill(
                          dk: dk,
                          icon: Icons.shopping_bag_outlined,
                          value: '$countPedidos',
                          label: 'Pedidos',
                        ),
                      ),
                    ],
                  ),
                  
                  // Banner de Upgrade
                  if (!planActual.contains('Pro') && !planActual.contains('Empresa')) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: SC.greenMid.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bolt, color: Color(0xFFFFD54F), size: 22),
                              SizedBox(width: 6),
                              Text(
                                'Mejora tu plan en SembrIA 👑',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Acceso a diagnósticos ilimitados con Claude AI, historial completo, soporte prioritario, múltiples usuarios y reportes avanzados.',
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9), height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _mostrarUpgradeModal(context, authProvider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD54F),
                                foregroundColor: SC.greenDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                elevation: 0,
                              ),
                              child: const Text(
                                '🚀 Ver Planes de Suscripción',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: dk ? SC.darkSurface : Colors.white,
                        border: Border.all(
                          color: planActual.contains('Empresa') ? const Color(0xFF2979FF) : const Color(0xFFFFD54F),
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            planActual.contains('Empresa') ? Icons.business : Icons.workspace_premium,
                            color: planActual.contains('Empresa') ? const Color(0xFF2979FF) : const Color(0xFFFFD54F),
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Suscripción $planActual Activa 🌾',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFD54F),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tienes diagnósticos ilimitados con Claude AI habilitados.',
                                  style: TextStyle(fontSize: 10, color: dk ? Colors.white70 : Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  SectionLabel(text: 'Mi cuenta', isDark: dk),
                  const SizedBox(height: 8),
                  _MenuGroup(
                    dk: dk,
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline,
                        label: 'Datos personales',
                        sub: 'Nombre: $nombreUsuario · Cultivo: $cultivoActual',
                      ),
                      _MenuItem(
                        icon: Icons.location_on_outlined,
                        label: 'Mis direcciones',
                        sub: 'Para envíos del marketplace',
                      ),
                      _MenuItem(
                        icon: Icons.credit_card_outlined,
                        label: 'Métodos de pago',
                        sub: 'Tarjetas y billeteras',
                      ),
                      _MenuItem(
                        icon: Icons.star_border,
                        label: 'Gestionar mi suscripción',
                        sub: 'Tu plan: $planActual',
                        onTap: () => _mostrarUpgradeModal(context, authProvider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SectionLabel(text: 'Actividad', isDark: dk),
                  const SizedBox(height: 8),
                  _MenuGroup(
                    dk: dk,
                    items: [
                      _MenuItem(
                        icon: Icons.history,
                        label: 'Historial de análisis',
                        sub: '$countDiagnosticos diagnósticos realizados',
                        badge: '$countDiagnosticos',
                      ),
                      _MenuItem(
                        icon: Icons.receipt_outlined,
                        label: 'Mis pedidos',
                        sub: '$countPedidos pedidos en camino',
                        badge: '$countPedidos',
                        badgeWarn: countPedidos > 0,
                      ),
                      _MenuItem(
                        icon: Icons.favorite_outline,
                        label: 'Favoritos',
                        sub: 'Productos guardados',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SectionLabel(text: 'Configuración', isDark: dk),
                  const SizedBox(height: 8),
                  _MenuGroup(
                    dk: dk,
                    items: [
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notificaciones',
                        sub: 'Alertas y avisos',
                      ),
                      _MenuItem(
                        icon: Icons.lock_outline,
                        label: 'Seguridad',
                        sub: 'Contraseña y acceso',
                      ),
                      _MenuItem(
                        icon: Icons.help_outline,
                        label: 'Ayuda y soporte',
                        sub: 'Preguntas frecuentes',
                        iconColor: SC.warnIcon,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cerrar sesión
                  GestureDetector(
                    onTap: () async {
                      await authProvider.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sesión cerrada con éxito.')),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: dk ? const Color(0xFF1A0D0D) : Colors.white,
                        border: Border.all(
                          color: const Color(0xFFFCE8E8),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            size: 18,
                            color: Color(0xFFC62828),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Cerrar sesión',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFC62828),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final bool dk;
  final IconData icon;
  final String value, label;
  const _StatPill({
    required this.dk,
    required this.icon,
    required this.value,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: dk ? SC.darkSurface : Colors.white,
        border: Border.all(
          color: dk ? SC.darkBorder : SC.greenPale,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: dk ? SC.greenLight : SC.greenMid),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: dk ? Colors.white : SC.greenDark,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: dk ? SC.textDimDk : SC.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label, sub;
  final String? badge;
  final bool badgeWarn;
  final Color? iconColor;
  final VoidCallback? onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.sub,
    this.badge,
    this.badgeWarn = false,
    this.iconColor,
    this.onTap,
  });
}

class _MenuGroup extends StatelessWidget {
  final bool dk;
  final List<_MenuItem> items;
  const _MenuGroup({required this.dk, required this.items});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dk ? SC.darkSurface : Colors.white,
        border: Border.all(
          color: dk ? SC.darkBorder : SC.greenPale,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return GestureDetector(
            onTap: item.onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.iconColor != null
                            ? const Color(0xFFFFF3E0)
                            : (dk ? SC.darkDeep : SC.greenGhost),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        item.icon,
                        size: 17,
                        color:
                            item.iconColor ??
                            (dk ? SC.greenLight : SC.greenMid),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: dk ? Colors.white : SC.greenDark,
                            ),
                          ),
                          Text(
                            item.sub,
                            style: TextStyle(
                              fontSize: 10,
                              color: dk ? SC.textDimDk : SC.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.badge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.badgeWarn
                              ? const Color(0xFFFFF3E0)
                              : SC.greenGhost,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.badge!,
                          style: TextStyle(
                            fontSize: 10,
                            color: item.badgeWarn ? SC.warnIcon : SC.greenMid,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: dk ? SC.darkBorder : SC.greenPale,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: dk ? SC.darkBorder : SC.greenGhost,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  COMPONENTES COMPARTIDOS
// ═══════════════════════════════════════════════════════════

class SembriaLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomPaint(size: const Size(16, 20), painter: _LeafPainter()),
        const SizedBox(width: 7),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Sembr',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE8F5E9),
                ),
              ),
              TextSpan(
                text: 'IA',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: SC.greenLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String initials;
  const UserAvatar({super.key, required this.initials});
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 17,
      backgroundColor: SC.greenMid,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const SectionLabel({super.key, required this.text, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
        color: isDark ? SC.greenBright : SC.textDim,
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final bool isDark, isWarn;
  final IconData icon;
  final String title, description;
  final String? linkText;
  final VoidCallback? onTap;
  const AlertCard({
    super.key,
    required this.isDark,
    required this.isWarn,
    required this.icon,
    required this.title,
    required this.description,
    this.linkText,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final dk = isDark;
    final cardBg = isWarn
        ? (dk ? SC.warnBgDk : SC.warnBg)
        : (dk ? SC.darkSurface : Colors.white);
    final borderColor = isWarn
        ? (dk ? SC.warnBorderDk : SC.warnBorder)
        : (dk ? SC.darkBorder : SC.greenPale);
    final iconBg = isWarn
        ? (dk ? const Color(0xFF2A1800) : const Color(0xFFFFF3E0))
        : (dk ? SC.darkDeep : SC.greenGhost);
    final iconColor = isWarn
        ? (dk ? SC.warnIconDk : SC.warnIcon)
        : (dk ? SC.greenLight : SC.greenMid);
    final titleColor = isWarn
        ? (dk ? const Color(0xFFFAC775) : const Color(0xFF7A4A00))
        : (dk ? const Color(0xFFE8F5E9) : SC.greenDark);
    final descColor = isWarn
        ? (dk ? const Color(0xFF8A6020) : const Color(0xFFA07030))
        : (dk ? SC.textDimDk : SC.textDim);
    final linkColor = isWarn
        ? (dk ? SC.warnIconDk : SC.warnIcon)
        : (dk ? SC.greenLight : SC.greenMid);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: borderColor, width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: descColor,
                      height: 1.4,
                    ),
                  ),
                  if (linkText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      linkText!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: linkColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsGrid extends StatelessWidget {
  final bool isDark;
  const StatsGrid({super.key, required this.isDark});
  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado dinámico de los proveedores
    final cropProvider = context.watch<CropProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.usuarioActual;

    // Calcular cultivos únicos a partir de los diagnósticos
    final cultivosUnicos = cropProvider.diagnosticos.map((d) => d.cultivo.toLowerCase().trim()).toSet();
    final countCultivos = cultivosUnicos.isEmpty ? 1 : cultivosUnicos.length;

    // Calcular alertas reales con riesgo Alto o Crítico
    final countAlertas = cropProvider.diagnosticos
        .where((d) => d.resultadoJson.nivelRiesgo.toLowerCase() == 'alto' || 
                      d.resultadoJson.nivelRiesgo.toLowerCase() == 'crítico' ||
                      d.resultadoJson.nivelRiesgo.toLowerCase() == 'critico')
        .length;

    final stats = [
      {
        'icon': Icons.eco_outlined,
        'value': '$countCultivos',
        'label': 'Cultivos activos',
      },
      {
        'icon': Icons.warning_amber_outlined,
        'value': '$countAlertas',
        'label': 'Alertas IA',
      },
      {
        'icon': Icons.star_border_outlined,
        'value': user?.plan ?? 'Gratuito',
        'label': 'Mi Plan',
      },
      {
        'icon': Icons.psychology_outlined,
        'value': '${user?.diagnosticosHoy ?? 0}',
        'label': 'Consultas hoy',
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: stats.map((s) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? SC.darkSurface : Colors.white,
            border: Border.all(
              color: isDark ? SC.darkBorder : SC.greenPale,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(
                s['icon'] as IconData,
                size: 20,
                color: isDark ? SC.greenLight : SC.greenMid,
              ),
              Text(
                s['value'] as String,
                style: TextStyle(
                  fontSize: 18, // Reducido un poco para evitar desbordes en textos largos como "Premium"
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE8F5E9) : SC.greenDark,
                  height: 1,
                ),
              ),
              Text(
                s['label'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? SC.textDimDk : SC.textDim,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ProductListCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String name, sub, price;
  const _ProductListCard({
    this.isDark = false,
    required this.icon,
    required this.name,
    required this.sub,
    required this.price,
  });
  @override
  Widget build(BuildContext context) {
    final dk = isDark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dk ? SC.darkSurface : Colors.white,
        border: Border.all(
          color: dk ? SC.darkBorder : SC.greenPale,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: dk ? SC.darkDeep : SC.greenGhost,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 21,
              color: dk ? SC.greenLight : SC.greenMid,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: dk ? Colors.white : SC.greenDark,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 10,
                    color: dk ? SC.textDimDk : SC.textDim,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: dk ? SC.greenLight : SC.greenMid,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: SC.greenMid,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ── BOTTOM NAV ───────────────────────────────
class _BottomNav extends StatelessWidget {
  final bool isDark;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({
    required this.isDark,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dk = isDark;
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Inicio'},
      {'icon': Icons.psychology_outlined, 'label': 'IA'},
      {'icon': Icons.shopping_bag_outlined, 'label': 'Tienda'},
      {'icon': Icons.person_outline, 'label': 'Perfil'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: dk ? SC.darkBg : Colors.white,
        border: Border(
          top: BorderSide(color: dk ? SC.darkBorder : SC.greenPale, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        0,
        10,
        0,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = i == selectedIndex;
          final color = active
              ? (dk ? SC.greenLight : SC.greenMid)
              : (dk ? SC.darkBorder : Colors.grey[400]!);
          return GestureDetector(
            onTap: () => onTap(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(items[i]['icon'] as IconData, color: color, size: 22),
                const SizedBox(height: 3),
                Text(
                  items[i]['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── LEAF PAINTER (logo) ──────────────────────
class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Oval Shadow at the very bottom
    final shadowPaint = Paint()
      ..color = const Color(0xFF1B3A1F).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(w * 0.2, h * 0.9, w * 0.6, h * 0.1),
      shadowPaint,
    );

    // 2. Stem Paint
    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    // Draw the stem from bulbous base up to 40% height
    canvas.drawLine(
      Offset(w * 0.5, h * 0.8),
      Offset(w * 0.5, h * 0.4),
      stemPaint,
    );

    // 3. Bulbous Circle Base at the bottom of the stem
    final basePaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.8),
      w * 0.12,
      basePaint,
    );

    // 4. Left Leaf (Dark Green)
    final leftLeafPaint = Paint()
      ..color = const Color(0xFF1B3A1F) // Forest green
      ..style = PaintingStyle.fill;
    final leftPath = Path()
      ..moveTo(w * 0.5, h * 0.68)
      ..quadraticBezierTo(
        w * 0.05,
        h * 0.55,
        w * 0.12,
        h * 0.28,
      )
      ..quadraticBezierTo(
        w * 0.45,
        h * 0.38,
        w * 0.5,
        h * 0.68,
      );
    canvas.drawPath(leftPath, leftLeafPaint);

    // 5. Right Leaf (Light Green)
    final rightLeafPaint = Paint()
      ..color = const Color(0xFF66BB6A) // Light green
      ..style = PaintingStyle.fill;
    final rightPath = Path()
      ..moveTo(w * 0.5, h * 0.52)
      ..quadraticBezierTo(
        w * 0.95,
        h * 0.38,
        w * 0.88,
        h * 0.12,
      )
      ..quadraticBezierTo(
        w * 0.55,
        h * 0.22,
        w * 0.5,
        h * 0.52,
      );
    canvas.drawPath(rightPath, rightLeafPaint);
  }

  @override
  bool shouldRepaint(_LeafPainter o) => false;
}

// ═══════════════════════════════════════════════════════════
//  6. AUTH SCREEN (LOGIN & REGISTER)
// ═══════════════════════════════════════════════════════════
class AuthScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  const AuthScreen({super.key, required this.isDark, required this.onToggleTheme});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();

  String _zonaSantaCruz = 'Montero';
  String _cultivoPrincipal = 'Tomate';

  final List<String> _zonas = [
    'Montero',
    'Warnes',
    'Okinawa',
    'Cotoca',
    'Mineros',
    'Santa Cruz de la Sierra'
  ];

  final List<String> _cultivos = ['Tomate', 'Soya', 'Maiz'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    bool success = false;

    if (_isLogin) {
      success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nombre: _nombreController.text.trim(),
        zonaSantaCruz: _zonaSantaCruz,
        cultivoPrincipal: _cultivoPrincipal,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLogin ? '¡Bienvenido de vuelta!' : '¡Cuenta registrada con éxito!'),
          backgroundColor: SC.greenMid,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dk = widget.isDark;
    final auth = context.watch<AuthProvider>();
    final isOffline = SupabaseAuthService().isOffline;

    return Scaffold(
      backgroundColor: dk ? SC.darkBg : const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              dk ? Icons.light_mode : Icons.dark_mode,
              color: dk ? SC.greenLight : SC.greenDark,
            ),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Vertical de SembrIA
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomPaint(
                    size: const Size(56, 70),
                    painter: _LeafPainter(),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Sembr',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: dk ? Colors.white : const Color(0xFF1B3A1F),
                          ),
                        ),
                        TextSpan(
                          text: 'IA',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: SC.greenLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'INTELIGENCIA AGRÍCOLA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      color: dk ? SC.greenLight : const Color(0xFF1B3A1F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Diagnóstico inteligente y mercado colaborativo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: dk ? SC.textDimDk : SC.textDim,
                ),
              ),
              const SizedBox(height: 12),
              
              // Badge de Estado (Conectado / Demo)
              GestureDetector(
                onTap: () {
                  setState(() {
                    DatabaseService.forceOffline = !DatabaseService.forceOffline;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(DatabaseService.forceOffline
                          ? 'Modo Demo (Offline) forzado manualmente.'
                          : 'Modo Supabase en línea restablecido.'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: SC.greenMid,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOffline 
                        ? (dk ? const Color(0xFF2A1F0A) : const Color(0xFFFFF8EC))
                        : (dk ? const Color(0xFF0F2610) : const Color(0xFFE8F5E9)),
                    border: Border.all(
                      color: isOffline ? SC.warnBorder : SC.greenLight,
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOffline ? SC.warnIcon : SC.greenMid,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOffline 
                            ? 'Modo Demo (Offline)' 
                            : 'Conectado a Supabase (Pulsa para alternar modo demo)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOffline ? SC.warnIcon : SC.greenMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Contenedor principal con Glassmorphism / Sombra
              Container(
                decoration: BoxDecoration(
                  color: dk ? SC.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: dk ? SC.darkBorder : SC.greenPale,
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: dk ? Colors.white : SC.greenDark,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nombre (solo en Register)
                      if (!_isLogin) ...[
                        TextFormField(
                          controller: _nombreController,
                          style: TextStyle(color: dk ? Colors.white : SC.greenDark, fontSize: 14),
                          decoration: _buildInputDecoration(
                            labelText: 'Nombre Completo',
                            icon: Icons.person_outline,
                            dk: dk,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 3) {
                              return 'El nombre debe tener al menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: dk ? Colors.white : SC.greenDark, fontSize: 14),
                        decoration: _buildInputDecoration(
                          labelText: 'Correo Electrónico',
                          icon: Icons.email_outlined,
                          dk: dk,
                        ),
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Ingresa un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: dk ? Colors.white : SC.greenDark, fontSize: 14),
                        decoration: _buildInputDecoration(
                          labelText: 'Contraseña',
                          icon: Icons.lock_outline,
                          dk: dk,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: dk ? SC.greenLight : SC.greenMid,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      
                      // Campos Adicionales del Agricultor (solo en Register)
                      if (!_isLogin) ...[
                        const SizedBox(height: 16),
                        // Dropdown de Zonas de Santa Cruz
                        DropdownButtonFormField<String>(
                          value: _zonaSantaCruz,
                          dropdownColor: dk ? SC.darkSurface : Colors.white,
                          style: TextStyle(color: dk ? Colors.white : SC.greenDark, fontSize: 14),
                          decoration: _buildInputDecoration(
                            labelText: 'Zona en Santa Cruz, Bolivia',
                            icon: Icons.location_on_outlined,
                            dk: dk,
                          ),
                          items: _zonas.map((zona) {
                            return DropdownMenuItem<String>(
                              value: zona,
                              child: Text(zona),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _zonaSantaCruz = val);
                          },
                        ),
                        const SizedBox(height: 16),
                        // Dropdown de Cultivo Principal
                        DropdownButtonFormField<String>(
                          value: _cultivoPrincipal,
                          dropdownColor: dk ? SC.darkSurface : Colors.white,
                          style: TextStyle(color: dk ? Colors.white : SC.greenDark, fontSize: 14),
                          decoration: _buildInputDecoration(
                            labelText: 'Cultivo Principal',
                            icon: Icons.eco_outlined,
                            dk: dk,
                          ),
                          items: _cultivos.map((cultivo) {
                            return DropdownMenuItem<String>(
                              value: cultivo,
                              child: Text(cultivo),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _cultivoPrincipal = val);
                          },
                        ),
                      ],

                      // Mensaje de Error
                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: dk ? const Color(0xFF2A0D0D) : const Color(0xFFFCE8E8),
                            border: Border.all(color: const Color(0xFFE57373), width: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFE57373), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFE57373),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Botón Principal
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SC.greenMid,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Iniciar Sesión' : 'Registrarse y Entrar',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botón para alternar Login vs. Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? '¿No tienes una cuenta?' : '¿Ya tienes una cuenta?',
                    style: TextStyle(
                      fontSize: 13,
                      color: dk ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                              auth.limpiarErrores();
                            });
                          },
                    child: Text(
                      _isLogin ? 'Regístrate aquí' : 'Inicia sesión',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: dk ? SC.greenLight : SC.greenMid,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData icon,
    required bool dk,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: dk ? SC.greenLight : SC.greenMid,
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: dk ? SC.greenLight : SC.greenMid,
        size: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: dk ? SC.darkBorder : SC.greenPale,
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: SC.greenMid,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 0.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
      filled: true,
      fillColor: dk ? SC.darkBg : Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

// ─────────────────────────────────────────────
//  PLANES DE SUSCRIPCIÓN - DEDICADO
// ─────────────────────────────────────────────
class SuscripcionesScreen extends StatelessWidget {
  final bool isDark;
  const SuscripcionesScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dk = isDark;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.usuarioActual;
    final planActual = user?.plan ?? 'Gratuito';

    return Scaffold(
      backgroundColor: dk ? SC.darkBg : const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: const Text(
          'Planes de Suscripción',
          style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold),
        ),
        backgroundColor: dk ? SC.darkSurface : SC.greenDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            // Header: Tu plan actual
            Center(
              child: Column(
                children: [
                  Text(
                    'Tu plan actual: $planActual',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: dk ? Colors.white : SC.greenDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Elige el plan con los superpoderes que necesitas para tus cultivos',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Horizontal / scrollable cards (or list depending on screen width)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPlanCard(context, authProvider, planActual, 'Gratuito', 'Gratis', '', [
                        '10 diagnósticos por mes',
                        'Marketplace básico',
                        'Clima en tiempo real',
                        'Mapa de plagas (lectura)',
                      ], dk)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildPlanCard(context, authProvider, planActual, 'Pro 👑', 'Pro', 'Bs 49/mes', [
                        'Diagnósticos ilimitados',
                        'Historial completo',
                        'Soporte prioritario',
                        'Coronita en tu perfil 👑',
                      ], dk, hasCrown: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildPlanCard(context, authProvider, planActual, 'Empresa 🏢', 'Empresa', 'Bs 149/mes', [
                        'Todo lo de Pro',
                        'Múltiples usuarios',
                        'API access',
                        'Logo empresa en perfil 🏢',
                        'Reportes avanzados',
                      ], dk, hasBuilding: true)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildPlanCard(context, authProvider, planActual, 'Gratuito', 'Gratis', '', [
                        '10 diagnósticos por mes',
                        'Marketplace básico',
                        'Clima en tiempo real',
                        'Mapa de plagas (lectura)',
                      ], dk),
                      const SizedBox(height: 16),
                      _buildPlanCard(context, authProvider, planActual, 'Pro 👑', 'Pro', 'Bs 49/mes', [
                        'Diagnósticos ilimitados',
                        'Historial completo',
                        'Soporte prioritario',
                        'Coronita en tu perfil 👑',
                      ], dk, hasCrown: true),
                      const SizedBox(height: 16),
                      _buildPlanCard(context, authProvider, planActual, 'Empresa 🏢', 'Empresa', 'Bs 149/mes', [
                        'Todo lo de Pro',
                        'Múltiples usuarios',
                        'API access',
                        'Logo empresa en perfil 🏢',
                        'Reportes avanzados',
                      ], dk, hasBuilding: true),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    AuthProvider authProvider,
    String currentPlan,
    String planId,
    String title,
    String price,
    List<String> features,
    bool dk, {
    bool hasCrown = false,
    bool hasBuilding = false,
  }) {
    final isCurrent = currentPlan.toLowerCase() == planId.toLowerCase() ||
        (planId.contains('Gratuito') && currentPlan.toLowerCase().contains('gratis')) ||
        (planId.contains('Pro') && currentPlan.toLowerCase().contains('pro')) ||
        (planId.contains('Empresa') && currentPlan.toLowerCase().contains('empresa'));

    Color borderColor = Colors.grey[300]!;
    Color buttonColor = SC.greenMid;
    if (isCurrent) {
      borderColor = SC.greenBright;
    } else if (hasCrown) {
      borderColor = const Color(0xFFFFD54F);
      buttonColor = SC.greenMid;
    } else if (hasBuilding) {
      borderColor = const Color(0xFF2979FF);
      buttonColor = const Color(0xFF2979FF);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dk ? SC.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isCurrent ? 2.0 : 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (hasCrown) const Text('👑 ', style: TextStyle(fontSize: 16)),
                  if (hasBuilding) const Text('🏢 ', style: TextStyle(fontSize: 16)),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: dk ? Colors.white : SC.greenDark,
                    ),
                  ),
                ],
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SC.greenGhost,
                    border: Border.all(color: SC.greenBright, width: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '✓ Tu plan actual',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: SC.greenMid),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            price.isNotEmpty ? price : 'Gratis',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: dk ? Colors.white : SC.greenDark,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 8),
          Column(
            children: features
                .map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✓ ',
                            style: TextStyle(color: SC.greenMid, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Expanded(
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 11,
                                color: dk ? Colors.white70 : Colors.grey[700],
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent
                  ? null
                  : () async {
                      final exito = await authProvider.mejorarPlan(planId);
                      if (exito && context.mounted) {
                        showDialog(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('🎉 ¡Felicidades!'),
                            content: Text('¡Tu cuenta ha sido actualizada al plan $title con éxito!'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx),
                                child: const Text('Excelente', style: TextStyle(color: SC.greenMid, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                isCurrent ? 'Plan actual' : 'Cambiar a $title',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    
    final Path dashedPath = Path();
    for (final ui.PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        dashedPath.addPath(
          measurePath.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}

