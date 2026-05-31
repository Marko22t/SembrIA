import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/failure.dart';
import 'database_service.dart';

class SupabaseAuthService {
  final SupabaseClient? _supabaseClient;

  SupabaseAuthService({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? _tryGetClient();

  static SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isOffline => _supabaseClient == null || DatabaseService.forceOffline;

  static User? _mockUserOverride;

  User? get currentUser {
    if (isOffline) {
      // Retornamos un usuario demo en modo offline o el registrado/logeado
      return _mockUserOverride ?? const User(
        id: 'juan-rojas-demo-uuid',
        appMetadata: {},
        userMetadata: {
          'nombre': 'Juan Rojas',
          'zona_santa_cruz': 'Montero',
          'cultivo_principal': 'Tomate',
        },
        aud: 'authenticated',
        createdAt: '2026-05-31T00:00:00Z',
      );
    }
    return _supabaseClient!.auth.currentUser;
  }

  Session? get currentSession => isOffline ? null : _supabaseClient!.auth.currentSession;
  
  Stream<AuthState> get authStateChanges {
    if (isOffline) {
      // Flujo demo vacío cuando no hay conexión configurada
      return const Stream.empty();
    }
    return _supabaseClient!.auth.onAuthStateChange;
  }

  Future<User?> signUp({
    required String email,
    required String password,
    required String nombre,
    required String zonaSantaCruz,
    required String cultivoPrincipal,
  }) async {
    if (isOffline) {
      await Future.delayed(const Duration(milliseconds: 600));
      _mockUserOverride = User(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        appMetadata: const {},
        userMetadata: {
          'nombre': nombre,
          'zona_santa_cruz': zonaSantaCruz,
          'cultivo_principal': cultivoPrincipal,
        },
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: email,
      );
      return _mockUserOverride;
    }

    try {
      final AuthResponse response = await _supabaseClient!.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombre': nombre,
          'zona_santa_cruz': zonaSantaCruz,
          'cultivo_principal': cultivoPrincipal,
          'plan': 'Gratuito',
          'diagnosticos_hoy': 0,
        },
      );
      
      final user = response.user;
      if (user == null) {
        throw const AuthFailure('No se pudo crear el usuario.');
      }

      await _supabaseClient!.from('usuarios').upsert({
        'id': user.id,
        'nombre': nombre,
        'email': email,
        'zona_santa_cruz': zonaSantaCruz,
        'cultivo_principal': cultivoPrincipal,
        'plan': 'Gratuito',
        'diagnosticos_hoy': 0,
      });

      return user;
    } on AuthException catch (e) {
      if (e.message.contains('Failed to fetch') || e.message.contains('ClientException')) {
        print('Conexión fallida. Activando Modo Demo Offline automáticamente...');
        DatabaseService.forceOffline = true;
        return await signUp(
          email: email,
          password: password,
          nombre: nombre,
          zonaSantaCruz: zonaSantaCruz,
          cultivoPrincipal: cultivoPrincipal,
        );
      }
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('Failed to fetch') || errorStr.contains('ClientException')) {
        print('Conexión fallida. Activando Modo Demo Offline automáticamente...');
        DatabaseService.forceOffline = true;
        return await signUp(
          email: email,
          password: password,
          nombre: nombre,
          zonaSantaCruz: zonaSantaCruz,
          cultivoPrincipal: cultivoPrincipal,
        );
      }
      throw AuthFailure('Error inesperado durante el registro: ${e.toString()}');
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    if (isOffline) {
      await Future.delayed(const Duration(milliseconds: 500));
      // Si ya hay un usuario registrado, nos logueamos con él,
      // sino creamos uno por defecto con el correo especificado
      if (_mockUserOverride == null || _mockUserOverride!.email != email) {
        _mockUserOverride = User(
          id: 'juan-rojas-demo-uuid',
          appMetadata: const {},
          userMetadata: const {
            'nombre': 'Juan Rojas',
            'zona_santa_cruz': 'Montero',
            'cultivo_principal': 'Tomate',
          },
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: email,
        );
      }
      return _mockUserOverride;
    }

    try {
      final AuthResponse response = await _supabaseClient!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } on AuthException catch (e) {
      if (e.message.contains('Failed to fetch') || e.message.contains('ClientException')) {
        print('Conexión fallida. Activando Modo Demo Offline automáticamente...');
        DatabaseService.forceOffline = true;
        return await signIn(email: email, password: password);
      }
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('Failed to fetch') || errorStr.contains('ClientException')) {
        print('Conexión fallida. Activando Modo Demo Offline automáticamente...');
        DatabaseService.forceOffline = true;
        return await signIn(email: email, password: password);
      }
      throw AuthFailure('Error inesperado durante el login: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    if (isOffline) {
      await Future.delayed(const Duration(milliseconds: 300));
      _mockUserOverride = null;
      return;
    }
    try {
      await _supabaseClient!.auth.signOut();
    } on AuthException catch (e) {
      if (e.message.contains('Failed to fetch') || e.message.contains('ClientException')) {
        print('Conexión fallida. Activando Modo Demo Offline automáticamente...');
        DatabaseService.forceOffline = true;
        return await signOut();
      }
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('Failed to fetch') || errorStr.contains('ClientException')) {
        print('Conexión fallida. Activando Modo Demo Offline automáticamente...');
        DatabaseService.forceOffline = true;
        return await signOut();
      }
      throw AuthFailure('Error inesperado al cerrar sesión: ${e.toString()}');
    }
  }
}
