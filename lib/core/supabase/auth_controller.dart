import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class AuthStateData {
  final User? user;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  AuthStateData({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get isAuthenticated => user != null;

  AuthStateData copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearUser = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthStateData(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthStateData> {
  StreamSubscription<AuthState>? _authSubscription;

  AuthController()
    : super(AuthStateData(user: SupabaseConfig.client.auth.currentUser)) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = SupabaseConfig.client.auth.onAuthStateChange.listen(
      (data) {
        state = state.copyWith(user: data.session?.user, clearError: true);
      },
      onError: (err) {
        state = state.copyWith(errorMessage: _mapAuthError(err));
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<bool> signUp({required String email, required String password}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );

      state = state.copyWith(
        user: response.user,
        isLoading: false,
        successMessage: 'Account created successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _mapAuthError(e));
      return false;
    }
  }

  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to sign in. Please verify your credentials.',
        );
        return false;
      }

      state = state.copyWith(
        user: response.user,
        isLoading: false,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _mapAuthError(e));
      return false;
    }
  }

  Future<bool> resetPasswordForEmail(String email) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'com.nethivo.medibond_bd://login-callback/',
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset link sent! Please check your email.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _mapAuthError(e));
      return false;
    }
  }

  Future<bool> updateUserPassword(String newPassword) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(password: newPassword.trim()),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password updated successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _mapAuthError(e));
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sign out exception: $e');
      }
    } finally {
      state = AuthStateData(user: null, isLoading: false);
    }
  }

  String _mapAuthError(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Invalid email or password. Please try again.';
      } else if (msg.contains('already registered') ||
          msg.contains('user_already_exists')) {
        return 'An account with this email already exists. Please login instead.';
      } else if (msg.contains('weak password') ||
          msg.contains('at least 6 characters')) {
        return 'Password must be at least 6 characters long.';
      } else if (msg.contains('rate limit')) {
        return 'Too many requests. Please wait a few moments and try again.';
      }
      return error.message;
    }
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('network') ||
        errStr.contains('failed host lookup')) {
      return 'Network unavailable. Operating in offline mode.';
    }
    return 'Authentication error occurred. Please try again.';
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthStateData>((ref) {
      return AuthController();
    });
