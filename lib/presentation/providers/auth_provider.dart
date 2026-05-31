import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/failure.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/supabase_auth_service.dart';
import '../../data/services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseAuthService _authService;
  final DatabaseService _databaseService;

  UsuarioModel? _usuarioActual;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({
    SupabaseAuthService? authService,
    DatabaseService? databaseService,
  })  : _authService = authService ?? SupabaseAuthService(),
        _databaseService = databaseService ?? DatabaseService() {
    _inicializarEscuchaSesion();
  }

  // Getters
  UsuarioModel? get usuarioActual => _usuarioActual;
  bool get isAuthenticated => _authService.currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _inicializarEscuchaSesion() {
    // Escucha cambios en el estado de autenticación de Supabase de manera reactiva
    _authService.authStateChanges.listen((data) async {
      final session = data.session;
      if (session != null) {
        await cargarPerfilUsuario(session.user.id);
      } else {
        _usuarioActual = null;
        notifyListeners();
      }
    });
  }

  Future<void> cargarPerfilUsuario(String id) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _usuarioActual = await _databaseService.obtenerUsuario(id);
    } catch (e) {
      _errorMessage = e is Failure ? e.message : 'Error al cargar perfil de usuario.';
      _usuarioActual = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _authService.signIn(email: email, password: password);
      if (user != null) {
        if (_authService.isOffline) {
          final meta = user.userMetadata ?? {};
          final nombre = meta['nombre'] as String? ?? 'Juan Rojas';
          final zona = meta['zona_santa_cruz'] as String? ?? 'Montero';
          final cultivo = meta['cultivo_principal'] as String? ?? 'Tomate';
          
          await _databaseService.actualizarUsuario(UsuarioModel(
            id: user.id,
            nombre: nombre,
            email: email,
            zonaSantaCruz: zona,
            cultivoPrincipal: cultivo,
            plan: 'Gratuito',
            diagnosticosHoy: 1,
          ));
        }
        await cargarPerfilUsuario(user.id);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e is Failure ? e.message : e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String nombre,
    required String zonaSantaCruz,
    required String cultivoPrincipal,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        nombre: nombre,
        zonaSantaCruz: zonaSantaCruz,
        cultivoPrincipal: cultivoPrincipal,
      );
      if (user != null) {
        if (_authService.isOffline) {
          await _databaseService.actualizarUsuario(UsuarioModel(
            id: user.id,
            nombre: nombre,
            email: email,
            zonaSantaCruz: zonaSantaCruz,
            cultivoPrincipal: cultivoPrincipal,
            plan: 'Gratuito',
            diagnosticosHoy: 0,
          ));
        }
        await cargarPerfilUsuario(user.id);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e is Failure ? e.message : e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.signOut();
      _usuarioActual = null;
    } catch (e) {
      _errorMessage = e is Failure ? e.message : e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> mejorarPlan(String nuevoPlan) async {
    if (_usuarioActual == null) return false;
    _setLoading(true);
    _errorMessage = null;
    try {
      final usuarioActualizado = _usuarioActual!.copyWith(
        plan: nuevoPlan,
      );
      await _databaseService.actualizarUsuario(usuarioActualizado);
      _usuarioActual = usuarioActualizado;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is Failure ? e.message : 'Error al mejorar el plan.';
      return false;
    } finally {
      _setLoading(false);
    }
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
