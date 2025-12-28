import 'package:flutter/services.dart';

/// 📳 Haptic Feedback Utility
/// Kullanıcı etkileşimlerinde dokunsal geri bildirim sağlar
/// 
/// Kullanım:
/// - HapticUtils.light() - Hafif dokunuş (buton tıklama)
/// - HapticUtils.medium() - Orta dokunuş (toggle değişimi)
/// - HapticUtils.heavy() - Ağır dokunuş (önemli aksiyon)
/// - HapticUtils.success() - Başarı (quiz doğru cevap)
/// - HapticUtils.error() - Hata (quiz yanlış cevap)
/// - HapticUtils.selection() - Seçim (liste item seçimi)
class HapticUtils {
  /// Hafif dokunsal geri bildirim
  /// Buton tıklamaları, küçük etkileşimler için
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Orta şiddette dokunsal geri bildirim
  /// Toggle değişimleri, swipe aksiyonları için
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Ağır dokunsal geri bildirim
  /// Önemli aksiyonlar, silme işlemleri için
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Başarı geri bildirimi
  /// Quiz doğru cevap, işlem tamamlandı için
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  /// Hata geri bildirimi
  /// Quiz yanlış cevap, hata durumları için
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }

  /// Seçim geri bildirimi
  /// Liste item seçimi, picker değişimi için
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Titreşim geri bildirimi
  /// Özel durumlar için (Android only)
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }
}
