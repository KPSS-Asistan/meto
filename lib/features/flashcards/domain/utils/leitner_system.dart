/// Leitner System (Spaced Repetition) Helper
/// 
/// Kutu Sistemi:
/// - Kutu 1: Yeni veya bilinmeyen kartlar (3 gün sonra)
/// - Kutu 2: Bir kez doğru bilinenler (7 gün sonra)
/// - Kutu 3: İki kez doğru bilinenler (14 gün sonra)
/// - Kutu 4: Üç kez doğru bilinenler (30 gün sonra)
class LeitnerSystem {
  /// Doğru cevap verildiğinde yeni kutu seviyesini hesapla
  static int getNextBoxLevel(int currentLevel) {
    if (currentLevel >= 4) return 4; // Maksimum seviye
    return currentLevel + 1;
  }

  /// Yanlış cevap verildiğinde kutu seviyesini sıfırla
  static int resetBoxLevel() {
    return 1; // Her zaman 1'e dön
  }

  /// Kutu seviyesine göre bir sonraki tekrar tarihini hesapla
  static DateTime calculateNextReviewDate(int boxLevel) {
    final now = DateTime.now();
    
    switch (boxLevel) {
      case 1:
        return now.add(const Duration(days: 3)); // 3 gün sonra
      case 2:
        return now.add(const Duration(days: 7)); // 7 gün sonra
      case 3:
        return now.add(const Duration(days: 14)); // 14 gün sonra
      case 4:
        return now.add(const Duration(days: 30)); // 30 gün sonra
      default:
        return now.add(const Duration(days: 3)); // Varsayılan
    }
  }

  /// Yanlış cevap için hemen tekrar göster
  static DateTime getImmediateReviewDate() {
    return DateTime.now();
  }

  /// Kartın tekrar edilmesi gerekip gerekmediğini kontrol et
  static bool shouldReview(DateTime nextReviewDate) {
    return DateTime.now().isAfter(nextReviewDate) || 
           DateTime.now().isAtSameMomentAs(nextReviewDate);
  }

  /// Başarı oranını hesapla
  static double calculateSuccessRate(int correctCount, int totalReviews) {
    if (totalReviews == 0) return 0.0;
    return (correctCount / totalReviews) * 100;
  }
}
