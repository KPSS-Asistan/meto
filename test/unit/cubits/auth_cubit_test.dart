import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/features/auth/cubit/auth_state.dart';

/// AuthCubit testleri Firebase bağımlılığı nedeniyle
/// sadece AuthState testleri olarak yapılandırıldı.
/// 
/// Not: AuthCubit içindeki `_checkNeedsDisplayName` metodu
/// `FirebaseAuth.instance.currentUser` kullandığı için
/// unit test ortamında mock'lanamaz.
void main() {
  group('AuthState', () {
    test('initial state doğru olmalı', () {
      const state = AuthState.initial();
      expect(state, isA<AuthState>());
      state.mapOrNull(
        initial: (s) => expect(s, isNotNull),
      );
    });

    test('loading state doğru olmalı', () {
      const state = AuthState.loading();
      expect(state, isA<AuthState>());
      state.mapOrNull(
        loading: (s) => expect(s, isNotNull),
      );
    });

    test('unauthenticated state doğru olmalı', () {
      const state = AuthState.unauthenticated();
      expect(state, isA<AuthState>());
      state.mapOrNull(
        unauthenticated: (s) => expect(s, isNotNull),
      );
    });

    test('error state mesaj içermeli', () {
      const state = AuthState.error('Test hatası');
      state.mapOrNull(
        error: (error) {
          expect(error.message, 'Test hatası');
        },
      );
    });

    test('error state farklı mesajlar içerebilmeli', () {
      const errorMessages = [
        'Bu e-posta ile kayıtlı kullanıcı bulunamadı',
        'Hatalı şifre girdiniz',
        'Geçersiz e-posta adresi',
        'Bu e-posta adresi zaten kullanımda',
        'Şifre en az 6 karakter olmalıdır',
      ];

      for (final message in errorMessages) {
        final state = AuthState.error(message);
        state.mapOrNull(
          error: (error) {
            expect(error.message, message);
          },
        );
      }
    });

    test('state equality çalışmalı', () {
      const state1 = AuthState.initial();
      const state2 = AuthState.initial();
      expect(state1, equals(state2));

      const loading1 = AuthState.loading();
      const loading2 = AuthState.loading();
      expect(loading1, equals(loading2));

      const error1 = AuthState.error('Hata');
      const error2 = AuthState.error('Hata');
      expect(error1, equals(error2));

      const error3 = AuthState.error('Farklı hata');
      expect(error1, isNot(equals(error3)));
    });
  });
}
