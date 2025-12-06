# KPSS 2026 - Akıllı KPSS Hazırlık Uygulaması

📚 KPSS sınavına hazırlanan öğrenciler için yapay zeka destekli, kapsamlı bir mobil uygulama.

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

## ✨ Özellikler

### 📖 Ders İçerikleri
- 4 ana ders kategorisi (Türkçe, Tarih, Coğrafya, Vatandaşlık)
- 28 konu, 148+ hardcoded içerik dosyası
- Konu anlatımları, hikayeler ve görsel özetler
- Offline-first mimari

### 🎯 Pratik ve Test
- Konu bazlı testler (20 soru, 20 dakika)
- Flashcard sistemi (Leitner algoritması)
- Yanlış soru takibi ve tekrar
- Favori soru listesi
- AI destekli test analizi

### 🎮 Eğitici Oyunlar
- Eşleştirme oyunu
- Hafıza teknikleri (Mnemonics)
- Konu bazlı oyunlar

### 🤖 AI Koç (OpenRouter + Grok 4.1)
- Streaming yanıtlar
- Kişiselleştirilmiş öneriler
- Günlük 10 soru hakkı + reklam ile bonus
- Çakallık koruması

### 📊 İlerleme Takibi
- Günlük çalışma streak'i
- Haftalık takvim görünümü
- Günlük hedefler (50 soru, 1 konu, 20 flashcard)
- Konu bazlı istatistikler

### 🔔 Bildirimler
- Günlük çalışma hatırlatıcısı
- Streak uyarısı (gece 22:00)
- Motivasyon bildirimleri
- Push notifications (Firebase Messaging)

### 💎 Premium
- Sınırsız AI Koç kullanımı
- Reklamsız deneyim
- Öncelikli destek
- 1/3/12 aylık planlar

## 🛠️ Teknoloji Stack

- **Framework:** Flutter 3.24+ (Dart 3.9+)
- **State Management:** BLoC/Cubit + Provider
- **Backend:** Firebase (Firestore, Auth, Analytics, Crashlytics, Performance)
- **AI:** OpenRouter API (Grok 4.1 Fast)
- **Local Storage:** SharedPreferences + flutter_secure_storage
- **Notifications:** flutter_local_notifications + firebase_messaging
- **Routing:** GoRouter
- **Code Generation:** Freezed, JSON Serializable
- **In-App Purchase:** in_app_purchase

## 📁 Proje Yapısı

```
lib/
├── core/
│   ├── models/          # Veri modelleri
│   ├── repositories/    # Firebase repository'leri
│   ├── services/        # Servisler (notification, cache, etc.)
│   ├── theme/           # Tema ve stiller
│   ├── utils/           # Yardımcı fonksiyonlar
│   └── widgets/         # Ortak widget'lar
├── features/
│   ├── auth/            # Kimlik doğrulama
│   ├── dashboard/       # Ana sayfa
│   ├── lessons/         # Dersler ve konular
│   ├── quiz/            # Test sistemi
│   ├── flashcards/      # Flashcard modülü
│   ├── games/           # Eğitici oyunlar
│   ├── ai_coach/        # AI Koç
│   └── practice/        # Pratik modülü
└── main.dart
```

## 🚀 Kurulum

```bash
# Repository'yi klonla
git clone https://github.com/username/kpss_2026.git
cd kpss_2026

# Bağımlılıkları yükle
flutter pub get

# Kod üretimi (freezed, json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Uygulamayı çalıştır
flutter run
```

## 🧪 Test

```bash
# Tüm testleri çalıştır
flutter test

# Coverage ile test
flutter test --coverage

# Belirli test dosyası
flutter test test/unit/cubits/
```

## 📋 Gereksinimler

- Flutter SDK ^3.24.0
- Dart SDK ^3.9.0
- Android SDK 21+ (Android için)
- iOS 12+ (iOS için)
- Firebase projesi

## 🔒 Güvenlik

- Firebase Security Rules ile veri koruması
- Kullanıcı bazlı erişim kontrolü
- API key'ler Firebase'de güvenli saklama
- flutter_secure_storage ile hassas veri şifreleme
- Crashlytics ile hata takibi
- Performance monitoring

## 📊 Servisler

| Servis | Açıklama |
|--------|----------|
| `NotificationService` | Push & Local bildirimler |
| `SecureStorageService` | Şifreli veri saklama |
| `PurchaseService` | In-app purchase yönetimi |
| `StreakService` | Çalışma serisi takibi |
| `QuizStatsService` | Quiz istatistikleri |
| `LocalProgressService` | Offline ilerleme |
| `PremiumService` | Premium üyelik kontrolü |
| `AICoachAdService` | Reklam ile bonus hak |

## 🧪 Test Coverage

```bash
# Unit testler
flutter test test/unit/

# Widget testler
flutter test test/widget/

# Tüm testler + coverage
flutter test --coverage
```

**Test Dosyaları:**
- `streak_service_test.dart` - Streak mantığı
- `quiz_stats_service_test.dart` - Quiz istatistikleri
- `notification_service_test.dart` - Bildirim mantığı
- `secure_storage_service_test.dart` - Güvenli saklama
- `purchase_service_test.dart` - Satın alma mantığı

## 📱 Platform Desteği

| Platform | Durum | Min Version |
|----------|-------|-------------|
| Android | ✅ | API 21 (5.0) |
| iOS | ✅ | iOS 12.0 |
| Web | ❌ | - |

## 📄 Lisans

Bu proje özel lisans altındadır. Tüm hakları saklıdır.

## 👥 İletişim

Sorularınız için: mertcancilingir@gmail.com
