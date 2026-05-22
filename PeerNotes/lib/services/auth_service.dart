import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign up with email and password
  Future<AuthResponse> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name},
      );

      if (response.user != null) {
        // Save user data (Mocked method)
        await _userService.updateUserData(name: name, email: email);
      }

      return response;
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'An unexpected error occurred during signup.';
    }
  }

  // Login with email and password
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'An unexpected error occurred during login.';
    }
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
