import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Uygulama genelinde kullanılan standart dialog'lar
class AppDialogs {
  AppDialogs._();

  /// Onay dialog'u göster
  /// [title] - Dialog başlığı
  /// [message] - Açıklama metni
  /// [confirmText] - Onay butonu metni
  /// [cancelText] - İptal butonu metni
  /// [isDestructive] - Kırmızı/tehlikeli aksiyon mu?
  /// [icon] - Üstte gösterilecek ikon
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Onayla',
    String cancelText = 'İptal',
    bool isDestructive = false,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDestructive 
        ? const Color(0xFFEF4444) 
        : const Color(0xFF6366F1);

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // İkon
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 32),
              ),
            if (icon != null) const SizedBox(height: 20),
            
            // Başlık
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            
            // Mesaj
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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

  /// Bilgi dialog'u göster (sadece OK butonu)
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Tamam',
    IconData icon = LucideIcons.info,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF6366F1), size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hata dialog'u göster
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Tamam',
  }) {
    return showInfo(
      context: context,
      title: title,
      message: message,
      buttonText: buttonText,
      icon: LucideIcons.info,
    );
  }

  /// Başarı dialog'u göster
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Tamam',
  }) {
    return showInfo(
      context: context,
      title: title,
      message: message,
      buttonText: buttonText,
      icon: LucideIcons.check,
    );
  }

  /// Premium özellik için uyarı dialog'u
  static Future<bool?> showPremiumRequired({
    required BuildContext context,
    required String featureName,
  }) {
    return showConfirmation(
      context: context,
      title: 'Premium Özellik',
      message: '$featureName özelliği sadece Premium üyeler için aktiftir. Premium\'a geçmek ister misiniz?',
      confirmText: 'Premium\'a Geç',
      cancelText: 'Vazgeç',
      icon: LucideIcons.crown,
    );
  }

  /// Çıkış onay dialog'u
  static Future<bool?> showLogoutConfirmation(BuildContext context) {
    return showConfirmation(
      context: context,
      title: 'Çıkış Yap',
      message: 'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
      confirmText: 'Çıkış Yap',
      cancelText: 'İptal',
      isDestructive: true,
      icon: LucideIcons.logOut,
    );
  }

  /// Silme onay dialog'u
  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    required String itemName,
  }) {
    return showConfirmation(
      context: context,
      title: 'Silmeyi Onayla',
      message: '"$itemName" silinecek. Bu işlem geri alınamaz.',
      confirmText: 'Sil',
      cancelText: 'Vazgeç',
      isDestructive: true,
      icon: LucideIcons.trash2,
    );
  }
}
