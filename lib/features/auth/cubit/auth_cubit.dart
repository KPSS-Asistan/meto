import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kpss_2026/core/repositories/auth_repository.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit({
    required AuthRepository repository,
  })  : _repository = repository,
        super(const AuthState.initial());

  /// Email/şifre ile giriş
  Future<void> login(String email, String password) async {
    try {
      emit(const AuthState.loading());

      final user = await _repository.signIn(email, password);
      
      // displayName kontrolü
      final needsName = await _checkNeedsDisplayName(user.uid);
      
      if (needsName) {
        emit(AuthState.needsDisplayName(user));
      } else {
        emit(AuthState.authenticated(user));
      }
      
      AppLogger.info('User logged in: ${user.email}');
    } catch (e) {
      AppLogger.error('Login failed', e);
      emit(AuthState.error(_mapAuthError(e)));
    }
  }

  /// Email/şifre ile kayıt
  Future<void> register(String email, String password) async {
    try {
      emit(const AuthState.loading());

      final user = await _repository.signUp(email, password);
      
      emit(AuthState.needsDisplayName(user));
      AppLogger.info('User registered: ${user.email}');
    } catch (e) {
      AppLogger.error('Registration failed', e);
      emit(AuthState.error(_mapAuthError(e)));
    }
  }

  /// Google ile giriş
  Future<void> signInWithGoogle() async {
    try {
      emit(const AuthState.loading());

      final user = await _repository.signInWithGoogle();
      
      final needsName = await _checkNeedsDisplayName(user.uid);
      
      if (needsName) {
        emit(AuthState.needsDisplayName(user));
      } else {
        emit(AuthState.authenticated(user));
      }
      
      AppLogger.info('User signed in with Google: ${user.email}');
    } catch (e) {
      AppLogger.error('Google sign in failed', e);
      
      // Kullanıcı iptal ettiyse sessizce initial'a dön
      if (e.toString().contains('cancelled')) {
        emit(const AuthState.initial());
        return;
      }
      
      emit(AuthState.error(_mapAuthError(e)));
    }
  }

  /// Misafir girişi
  Future<void> signInAnonymously() async {
    try {
      emit(const AuthState.loading());

      final user = await _repository.signInAnonymously();
      
      emit(AuthState.authenticated(user));
      AppLogger.info('User signed in anonymously');
    } catch (e) {
      AppLogger.error('Anonymous sign in failed', e);
      emit(AuthState.error(_mapAuthError(e)));
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    try {
      await _repository.signOut();
      emit(const AuthState.unauthenticated());
      AppLogger.info('User logged out');
    } catch (e) {
      AppLogger.error('Logout failed', e);
    }
  }

  /// Şifre sıfırlama e-postası gönder
  Future<void> resetPassword(String email) async {
    try {
      emit(const AuthState.loading());
      await _repository.resetPassword(email);
      emit(const AuthState.initial());
      AppLogger.info('Password reset email sent to: $email');
    } catch (e) {
      AppLogger.error('Password reset failed', e);
      emit(AuthState.error(_mapAuthError(e)));
    }
  }

  /// displayName gerekiyor mu kontrol et
  /// displayName gerekiyor mu kontrol et
  /// ⚡ OPTIMIZED: Firestore yerine Firebase Auth kullan (Bedava & Hızlı)
  Future<bool> _checkNeedsDisplayName(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    
    // Firebase Auth'tan displayName kontrol et
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      return false; // İsim var, ekrana gerek yok
    }
    
    return true; // İsim yok, sorulmalı
  }

  /// Firebase Auth hatalarını Türkçe mesajlara çevir
  String _mapAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('user-not-found')) {
      return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı';
    } else if (errorString.contains('wrong-password')) {
      return 'Hatalı şifre girdiniz';
    } else if (errorString.contains('invalid-email')) {
      return 'Geçersiz e-posta adresi';
    } else if (errorString.contains('user-disabled')) {
      return 'Bu hesap devre dışı bırakılmış';
    } else if (errorString.contains('email-already-in-use')) {
      return 'Bu e-posta adresi zaten kullanımda';
    } else if (errorString.contains('weak-password')) {
      return 'Şifre en az 6 karakter olmalıdır';
    } else if (errorString.contains('network')) {
      return 'İnternet bağlantınızı kontrol edin';
    } else if (errorString.contains('too-many-requests')) {
      return 'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin';
    } else if (errorString.contains('cancelled')) {
      return 'İşlem iptal edildi';
    }

    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}
