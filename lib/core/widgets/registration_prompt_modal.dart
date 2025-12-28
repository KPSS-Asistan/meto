import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/services/guest_prompt_service.dart';

/// Kayıt teşvik modalı - Feature gate ve soft prompt için
/// Apple + Google login destekli, platform-aware
class RegistrationPromptModal extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? featureName;
  final VoidCallback? onRegistered;
  final VoidCallback? onDismissed;

  const RegistrationPromptModal({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lock_outline_rounded,
    this.featureName,
    this.onRegistered,
    this.onDismissed,
  });

  /// Feature gate için göster
  static Future<bool> showFeatureGate({
    required BuildContext context,
    required String feature,
    required String title,
    required String message,
    IconData icon = Icons.lock_outline_rounded,
  }) async {
    // Kayıtlıysa gate gösterme
    if (!GuestPromptService.isAnonymous()) return true;
    
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegistrationPromptModal(
        title: title,
        message: message,
        icon: icon,
        featureName: feature,
      ),
    );
    
    return result ?? false;
  }

  /// Progress prompt için göster (banner tarzı)
  static Future<void> showProgressPrompt(BuildContext context, {int? questionsAnswered}) async {
    if (!GuestPromptService.isAnonymous()) return;
    
    final shouldShow = await GuestPromptService().shouldShowProgressPrompt();
    if (!shouldShow) return;
    
    final count = questionsAnswered ?? await GuestPromptService().getQuestionsAnswered();
    
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RegistrationPromptModal(
          title: 'İlerlemeni Kaydet',
          message: '$count soru çözdün! Çalışmanı kaybetmemek için hesap oluştur.',
          icon: Icons.bookmark_rounded,
        ),
      );
    }
  }

  @override
  State<RegistrationPromptModal> createState() => _RegistrationPromptModalState();
}

class _RegistrationPromptModalState extends State<RegistrationPromptModal> {
  bool _isLoading = false;
  String? _error;
  String? _loadingProvider; // 'google' or 'apple'

  bool get _isIOS => Platform.isIOS;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _loadingProvider = 'google';
      _error = null;
    });

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Anonim hesabı Google'a bağla
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        await currentUser.linkWithCredential(credential);
      } else {
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      // Guest verilerini temizle
      await GuestPromptService().clearAllGuestData();

      if (mounted && context.mounted) {
        widget.onRegistered?.call();
        Navigator.of(context).pop(true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _loadingProvider = null;
        _error = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadingProvider = null;
        _error = 'Bir hata oluştu. Tekrar deneyin.';
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _loadingProvider = 'apple';
      _error = null;
    });

    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      // Anonim hesabı Apple'a bağla
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        await currentUser.linkWithProvider(appleProvider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(appleProvider);
      }

      // Guest verilerini temizle
      await GuestPromptService().clearAllGuestData();

      if (mounted && context.mounted) {
        widget.onRegistered?.call();
        Navigator.of(context).pop(true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _loadingProvider = null;
        _error = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadingProvider = null;
        _error = 'Apple ile giriş yapılamadı.';
      });
    }
  }

  void _goToEmailLogin() {
    Navigator.of(context).pop(false);
    context.push('/auth');
  }

  void _dismiss() {
    GuestPromptService().markPromptDismissed();
    widget.onDismissed?.call();
    Navigator.of(context).pop(false);
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'credential-already-in-use':
        return 'Bu hesap başka bir kullanıcıya ait.';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullanılıyor.';
      default:
        return 'Giriş yapılamadı. Tekrar deneyin.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXLarge),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 36,
                  color: AppColors.primary,
                ),
              ).animate().scale(
                begin: const Offset(0.8, 0.8),
                curve: Curves.elasticOut,
                duration: 600.ms,
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Message
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
                  height: 1.5,
                ),
              ),
              
              // Error
              if (_error != null) ...[ 
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 28),
              
              // === iOS: Apple button first ===
              if (_isIOS) ...[
                _buildAppleButton(isDark),
                const SizedBox(height: 12),
                _buildGoogleButton(isDark),
              ] else ...[
                // === Android: Google button first ===
                _buildGoogleButton(isDark),
                const SizedBox(height: 12),
                _buildAppleButton(isDark),
              ],
              
              const SizedBox(height: 20),
              
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'veya',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.border)),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Email login link
              TextButton(
                onPressed: _isLoading ? null : _goToEmailLogin,
                child: Text(
                  'E-posta ile giriş yap',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Dismiss link
              TextButton(
                onPressed: _isLoading ? null : _dismiss,
                child: Text(
                  'Daha sonra',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(bool isDark) {
    final isLoadingGoogle = _loadingProvider == 'google';
    
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoadingGoogle)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              )
            else
              Image.network(
                'https://www.google.com/favicon.ico',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
              ),
            const SizedBox(width: 12),
            Text(
              isLoadingGoogle ? 'Bağlanıyor...' : 'Google ile Devam Et',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleButton(bool isDark) {
    final isLoadingApple = _loadingProvider == 'apple';
    
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signInWithApple,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoadingApple)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.black : Colors.white,
                ),
              )
            else
              Icon(Icons.apple_rounded, size: 24),
            const SizedBox(width: 12),
            Text(
              isLoadingApple ? 'Bağlanıyor...' : 'Apple ile Devam Et',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
