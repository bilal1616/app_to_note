import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'auth_state.dart';

final _sb = Supabase.instance.client;

/// Uygulama geneli auth durumunu yöneten Cubit
class AuthCubit extends Cubit<AuthState> {
  StreamSubscription<dynamic>? _sub;

  AuthCubit() : super(const AuthState(status: AuthStatus.unknown)) {
    // 1) Uygulama açılışında mevcut session var mı?
    final s = _sb.auth.currentSession;
    if (s != null) {
      emit(AuthState(
        status: AuthStatus.authenticated,
        userId: s.user.id,
        email: s.user.email,
      ));
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }

    // 2) Supabase auth değişimlerini dinle (v2 API)
    _sub = _sb.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      if (session?.user != null) {
        emit(AuthState(
          status: AuthStatus.authenticated,
          userId: session!.user.id,
          email: session.user.email,
        ));
      } else {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      }
    });
  }

  // ----------------- REGISTER -----------------
  Future<String?> register(
    String email,
    String password, {
    String? fullName,
  }) async {
    try {
      emit(state.copyWith(status: AuthStatus.authenticating, error: null));

      final res = await _sb.auth.signUp(
        email: email.trim(),
        password: password,
        data: (fullName?.isNotEmpty ?? false) ? {'full_name': fullName} : null,
      );

      // Email confirmation açıksa session null gelebilir
      if (res.session == null) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
        return 'Please confirm the email we sent to complete signup.';
      }

      // (Opsiyonel) profile upsert
      if ((fullName?.isNotEmpty ?? false) && res.user != null) {
        await _sb.from('profiles').upsert({
          'id': res.user!.id,
          'email': email.trim(),
          'full_name': fullName,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      emit(AuthState(
        status: AuthStatus.authenticated,
        userId: res.user?.id,
        email: res.user?.email,
      ));
      return null;
    } on AuthApiException catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, error: e.message));
      return e.message;
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, error: '$e'));
      return 'Signup failed';
    }
  }

  // ----------------- LOGIN -----------------
  Future<String?> login(String email, String password) async {
    try {
      emit(state.copyWith(status: AuthStatus.authenticating, error: null));

      final res = await _sb.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (res.session == null || res.user == null) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
        return 'Login failed';
      }

      emit(AuthState(
        status: AuthStatus.authenticated,
        userId: res.user!.id,
        email: res.user!.email,
      ));
      return null;
    } on AuthApiException catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, error: e.message));
      return e.message;
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, error: '$e'));
      return 'Login failed';
    }
  }

  // ----------------- FORGOT PASSWORD -----------------
  Future<String?> forgot(String email) async {
    try {
      await _sb.auth.resetPasswordForEmail(email.trim());
      return 'Password reset email sent';
    } on AuthApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to send reset link';
    }
  }

  // ----------------- LOGOUT -----------------
  /// Tek çıkış fonksiyonu: global signOut + local temizlik + state reset
  Future<void> logout() async {
    emit(state.copyWith(status: AuthStatus.authenticating, error: null));
    try {
      // Sunucuda tüm oturumları kapat (özellikle iOS için önemli)
      await _sb.auth.signOut(scope: SignOutScope.global);

      // (İsteğe bağlı) realtime kanallarını temizle
      try {
        _sb.removeAllChannels();
      } catch (_) {}

      // Not cache'lerini de sıfırlamak istiyorsan aç:
      // await HydratedBloc.storage.clear();

      emit(const AuthState(status: AuthStatus.unauthenticated));
    } catch (e) {
      // Logout başarısız olsa da kullanıcıyı içeride bırakmıyoruz
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  /// Geriye uyumluluk için (UI’da signOut çağırıyorsan)
  Future<void> signOut() => logout();

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
