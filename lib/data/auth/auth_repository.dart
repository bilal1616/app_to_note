import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _sb = Supabase.instance.client;

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _sb.auth.signInWithPassword(email: email, password: password);
      return null; // null -> success
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unexpected error';
    }
  }

  Future<String?> signUp({required String email, required String password}) async {
    try {
      // email confirm açık ise "Check your inbox" beklenir
      await _sb.auth.signUp(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unexpected error';
    }
  }

  Future<String?> sendResetPassword({required String email}) async {
    try {
      await _sb.auth.resetPasswordForEmail(
        email,
        redirectTo: null, // mobilde zorunlu değil; web’de deep link verirsin
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unexpected error';
    }
  }

  Future<void> signOut() async => _sb.auth.signOut();

  Session? get currentSession => _sb.auth.currentSession;
  String? get userId => _sb.auth.currentUser?.id;

  Stream<AuthState> get onAuthStateChange => _sb.auth.onAuthStateChange;
}
