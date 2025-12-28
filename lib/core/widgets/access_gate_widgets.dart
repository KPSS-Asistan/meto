import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../services/user_access_service.dart';

/// Erişim Kısıtlaması Overlay
/// Misafir kullanıcılara giriş yapma, kayıtlılara pro geçme teşviği gösterir
class AccessGateOverlay extends StatelessWidget {
  final FeatureAccessResult accessResult;
  final Widget child;
  final bool showPreview;
  
  const AccessGateOverlay({
    super.key,
    required this.accessResult,
    required this.child,
    this.showPreview = true,
  });
  
  @override
  Widget build(BuildContext context) {
    if (accessResult.canAccess) return child;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        // Preview (blurred/faded content)
        if (showPreview)
          Opacity(
            opacity: 0.3,
            child: IgnorePointer(child: child),
          ),
        
        // Lock overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? AppColors.darkBackground : AppColors.background).withValues(alpha: 0.8),
                  (isDark ? AppColors.darkBackground : AppColors.background).withValues(alpha: 0.95),
                ],
              ),
            ),
            child: Center(
              child: _buildLockCard(context, isDark),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLockCard(BuildContext context, bool isDark) {
    final isLoginAction = accessResult.upgradeAction == UpgradeAction.login;
    
    return Container(
      margin: const EdgeInsets.all(AppSizes.space24),
      padding: const EdgeInsets.all(AppSizes.space24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (isLoginAction ? AppColors.primary : AppColors.warning).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLoginAction ? Icons.lock_outline_rounded : Icons.workspace_premium_rounded,
              size: 32,
              color: isLoginAction ? AppColors.primary : AppColors.warning,
            ),
          ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),
          
          const SizedBox(height: AppSizes.space16),
          
          // Title
          Text(
            accessResult.feature,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: AppSizes.space8),
          
          // Message
          Text(
            accessResult.message ?? 'Bu özelliğe erişmek için giriş yap',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
            ),
          ),
          
          const SizedBox(height: AppSizes.space24),
          
          // Action button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                if (isLoginAction) {
                  context.go('/auth');
                } else {
                  context.push('/premium');
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: isLoginAction ? AppColors.primary : AppColors.warning,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
              ),
              child: Text(
                isLoginAction ? 'Giriş Yap' : 'Pro\'ya Geç',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          if (isLoginAction) ...[
            const SizedBox(height: AppSizes.space12),
            TextButton(
              onPressed: () => context.go('/register'),
              child: Text(
                'Hesabın yok mu? Kayıt ol',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

/// Soru Limiti Uyarı Dialog
class QuestionLimitDialog extends StatelessWidget {
  final QuestionAccessResult accessResult;
  
  const QuestionLimitDialog({
    super.key,
    required this.accessResult,
  });
  
  static Future<bool?> show(BuildContext context, QuestionAccessResult result) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuestionLimitDialog(accessResult: result),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGuest = accessResult.userType == UserType.guest;
    
    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withValues(alpha: 0.15),
                    AppColors.warning.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                size: 36,
                color: AppColors.warning,
              ),
            ).animate().shake(hz: 2, duration: 500.ms),
            
            const SizedBox(height: AppSizes.space16),
            
            // Title
            Text(
              'Günlük Limit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: AppSizes.space8),
            
            // Message
            Text(
              accessResult.message ?? 'Günlük soru limitine ulaştın',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: AppSizes.space12),
            
            // Limit info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkBackground : AppColors.background),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isGuest 
                        ? 'Misafir: 20/gün • Üye: 50/gün'
                        : 'Üye: 50/gün • Pro: Sınırsız',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSizes.space24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                    ),
                    child: Text(
                      'Kapat',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                      // Her durumda /auth'a yönlendir
                      // Misafir: Giriş yapsın
                      // Kayıtlı: Orada zaten giriş yapmış, /premium'a girebilir
                      if (isGuest) {
                        context.go('/auth');
                      } else {
                        // Kayıtlı kullanıcı premium sayfasına
                        context.push('/premium');
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                    ),
                    child: Text(
                      isGuest ? 'Giriş Yap' : 'Pro\'ya Geç',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Basit erişim kontrolü widget'ı
class FeatureGate extends StatelessWidget {
  final Future<FeatureAccessResult> Function() accessCheck;
  final Widget child;
  final Widget? placeholder;
  
  const FeatureGate({
    super.key,
    required this.accessCheck,
    required this.child,
    this.placeholder,
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FeatureAccessResult>(
      future: accessCheck(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return placeholder ?? const Center(child: CircularProgressIndicator());
        }
        
        final result = snapshot.data!;
        if (result.canAccess) return child;
        
        return AccessGateOverlay(
          accessResult: result,
          child: child,
        );
      },
    );
  }
}
