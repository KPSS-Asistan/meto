# KPSS Asistan - Admin Panel Entegrasyon Rehberi

## 🎯 AMAÇ
KPSS Asistan mobil uygulaması için Firebase Admin Panel entegrasyonu. Uygulama artık **LOCAL-FIRST** mimarisine geçti. Tüm içerikler (sorular, flashcards, hikayeler, eşleştirme oyunları) Dart dosyalarında hardcoded olarak tutuluyor. Firebase sadece **kullanıcı authentication** ve **günlük user data sync** için kullanılıyor.

---

## 🔥 FİREBASE TEMİZLİĞİ - SİLİNECEK COLLECTION'LAR

Aşağıdaki collection'lar artık kullanılmıyor ve **SİLİNMELİ**:

### İçerik Collection'ları (Artık Hardcoded):
```
❌ questions          → lib/core/data/questions/ klasöründe
❌ flashcards         → lib/core/data/flashcards/ klasöründe
❌ topics             → lib/core/data/topics_data.dart
❌ lessons            → lib/core/data/lessons_data.dart
❌ topic_stories      → lib/core/data/stories/ klasöründe
❌ game_matching      → lib/core/data/matching_games/ klasöründe
❌ game_memory        → Kullanılmıyor
❌ game_wordhunt      → Kullanılmıyor
❌ explanations       → lib/core/data/explanations/ klasöründe
```

### Eski User Data Collection'ları (Yeni yapıya geçildi):
```
❌ user_progress      → Artık users/{userId}/data/progress altında
❌ user_favorites     → Artık users/{userId}/data/progress altında
❌ streak_data        → Artık users/{userId}/data/progress altında
❌ user_flashcard_progress → Artık users/{userId}/data/progress altında
```

### Diğer Gereksiz Collection'lar:
```
❌ app_updates        → Kullanılmıyor
❌ notifications      → Kullanılmıyor (local notifications)
```

---

## ✅ FİREBASE'DE KALACAK YAPILAR

### 1. Authentication (Firebase Auth)
- Email/Password login
- Google Sign-In
- Kullanıcı profil bilgileri

### 2. Firestore Yapısı (Sadece User Data)
```
users/
└── {userId}/
    ├── email: string
    ├── displayName: string
    ├── createdAt: timestamp
    ├── lastLoginAt: timestamp
    ├── isPremium: boolean
    └── data/
        └── progress/
            ├── lastSync: string (ISO date)
            ├── userId: string
            ├── email: string
            ├── currentStreak: number
            ├── lastStudyDate: string ("2025-12-04")
            ├── longestStreak: number
            ├── totalStudyTimeMinutes: number
            ├── totalQuestionsAnswered: number
            ├── totalCorrectAnswers: number
            ├── favoriteTopics: string[]
            ├── settings: {
            │   ├── notificationsEnabled: boolean
            │   ├── dailyReminderTime: string ("09:00")
            │   ├── darkMode: boolean
            │   └── soundEnabled: boolean
            │   }
            ├── topicProgress: {
            │   └── [topicId]: {
            │       ├── topicId: string
            │       ├── topicName: string
            │       ├── lessonId: string
            │       ├── attemptedQuestions: number
            │       ├── correctAnswers: number
            │       ├── wrongAnswers: number
            │       ├── lastStudiedAt: string
            │       └── studyTimeMinutes: number
            │       }
            │   }
            ├── wrongAnswers: [
            │   {
            │       questionId: string,
            │       topicId: string,
            │       topicName: string,
            │       wrongCount: number,
            │       lastWrongAt: string,
            │       selectedAnswer: string,
            │       correctAnswer: string
            │   }
            │   ]
            ├── flashcardProgress: {
            │   └── [topicId]: {
            │       ├── topicId: string
            │       ├── totalCards: number
            │       ├── knownCards: number
            │       ├── unknownCards: number
            │       ├── lastStudiedAt: string
            │       └── boxLevels: {[cardId]: number}
            │       }
            │   }
            └── quizHistory: [
                {
                    topicId: string,
                    topicName: string,
                    lessonId: string,
                    totalQuestions: number,
                    correctAnswers: number,
                    durationSeconds: number,
                    completedAt: string
                }
                ] (son 50 kayıt)
```

### 3. Analytics (Ücretsiz)
- Firebase Analytics aktif kalacak
- Kullanıcı davranışları izlenecek

### 4. Crashlytics (Ücretsiz)
- Hata raporlama aktif kalacak

---

## 📱 MOBİL UYGULAMA MİMARİSİ

### Veri Akışı:
```
┌─────────────────────────────────────────────────────────────┐
│                    MOBİL UYGULAMA                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │  HARDCODED DATA │    │  LOCAL STORAGE  │                │
│  │  (Dart Files)   │    │ (SharedPrefs)   │                │
│  ├─────────────────┤    ├─────────────────┤                │
│  │ • Sorular       │    │ • User Progress │                │
│  │ • Flashcards    │    │ • Streak        │                │
│  │ • Hikayeler     │    │ • Favorites     │                │
│  │ • Eşleştirmeler │    │ • Quiz History  │                │
│  │ • Konular       │    │ • Settings      │                │
│  │ • Dersler       │    │ • Wrong Answers │                │
│  └─────────────────┘    └────────┬────────┘                │
│                                  │                          │
│                                  │ Günlük Sync              │
│                                  │ (24 saat)                │
│                                  ▼                          │
│                    ┌─────────────────────┐                  │
│                    │     FIREBASE        │                  │
│                    │  (Sadece User Data) │                  │
│                    │                     │                  │
│                    │ users/{uid}/data/   │                  │
│                    │     progress        │                  │
│                    └─────────────────────┘                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Sync Mantığı:
1. **Uygulama Açılışı**: 24 saatten eski ise Firebase'den pull
2. **Login Sonrası**: Firebase'den veri çek, local ile merge
3. **Uygulama Arka Plana Alındığında**: Local veriyi Firebase'e push
4. **Logout Öncesi**: Son sync yap

---

## 🛠️ ADMİN PANELİ GEREKSİNİMLERİ

### 1. Kullanıcı Yönetimi
```
- Tüm kullanıcıları listele
- Kullanıcı detaylarını görüntüle:
  • Email, Display Name
  • Kayıt tarihi, Son giriş
  • Premium durumu
  • Streak bilgisi
  • Toplam çözülen soru
  • Başarı oranı
- Kullanıcı ara (email/isim)
- Premium durumu değiştir
- Kullanıcı sil
```

### 2. İstatistik Dashboard
```
- Toplam kullanıcı sayısı
- Aktif kullanıcı sayısı (son 7 gün)
- Günlük yeni kayıt
- Premium kullanıcı sayısı
- En çok çalışılan konular
- Ortalama streak
- Toplam çözülen soru
```

### 3. İçerik Yönetimi (Opsiyonel - Gelecek için)
```
NOT: İçerikler şu an Dart dosyalarında hardcoded.
Gelecekte admin panelden içerik güncellemesi için:
- JSON export/import özelliği
- Versiyon kontrolü
- Uygulama güncelleme bildirimi
```

---

## 🔐 FİREBASE SECURITY RULES

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Kullanıcılar sadece kendi verilerine erişebilir
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Alt koleksiyonlar
      match /data/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Admin erişimi (admin paneli için)
    match /{document=**} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

### Admin Koleksiyonu:
```
admins/
└── {adminUserId}/
    ├── email: string
    ├── isAdmin: boolean
    └── createdAt: timestamp
```

---

## 📊 KONU VE DERS ID'LERİ (Referans)

### Dersler:
```
caZ5LwfH3QJrBVUQCros → TARİH
L3i1Rqv2LN3AKFFejuUg → TÜRKÇE
A779wvZWQcbvanmbS8Qz → COĞRAFYA
2ztkqV35cWjGRkhYRutg → VATANDAŞLIK
```

### Tarih Konuları:
```
JnFbEQt0uA8RSEuy22SQ → İslamiyet Öncesi Türk Tarihi
9Hg8tuMRdMTuVY7OZ9HL → İlk Müslüman Türk Devletleri
rl2xQTfv1iUaCyhFzp5V → Osmanlı Devleti Tarihi
DlT19snCttf5j5RUAXLz → Kurtuluş Savaşı Dönemi
4GUvpqBBImcLmN2eh1HK → Atatürk İlke ve İnkılapları
onwrfsH02TgIhlyRUh56 → Cumhuriyet Dönemi
xQWHl1hBYAKM96X4deR8 → Çağdaş Türk ve Dünya Tarihi
```

### Türkçe Konuları:
```
80e0wkTLvaTQzPD6puB7 → Ses Bilgisi
yWlh5C6jB7lzuJOodr2t → Yapı Bilgisi
ICNDiSlTmmjWEQPT6rmT → Sözcük Türleri
JmyiPxf3n96Jkxqsa9jY → Sözcükte Anlam
AJNLHhhaG2SLWOvxDYqW → Cümlede Anlam
nN8JOTR7LZm01AN2i3sQ → Paragrafta Anlam
jXcsrl5HEb65DmfpfqqI → Anlatım Bozuklukları
qSEqigIsIEBAkhcMTyCE → Yazım Kuralları ve Noktalama
wnt2zWaV1pX8p8s8BBc9 → Sözel Mantık ve Akıl Yürütme
```

### Coğrafya Konuları:
```
1FEcPsGduhjcQARpaGBk → Türkiye'nin Coğrafi Konumu
kbs0Ffved9pCP3Hq9M9k → Türkiye'nin Fiziki Özellikleri
6e0Thsz2RRNHFcwqQXso → Türkiye'nin İklimi ve Bitki Örtüsü
uYDrMlBCEAho5776WZi8 → Beşeri Coğrafya
WxrtQ26p2My4uJa0h1kk → Ekonomik Coğrafya
GdpN8uxJNGtexWrkoL1T → Türkiye'nin Coğrafi Bölgeleri
```

### Vatandaşlık Konuları:
```
AQ0Zph76dzPdr87H1uKa → Hukuka Giriş
n4OjWupHmouuybQzQ1Fc → Anayasa Hukuku
xXGXiqx2TkCtI4C7GMQg → 1982 Anayasası Temel İlkeleri
1JZAYECyEn7farNNyGyx → Devlet Organları
lv93cmhwq7RmOFM5WxWD → İdari Yapı
Bo3qqooJsqtIZrK5zc9S → Güncel Olaylar
```

---

## 🚀 UYGULAMA ADIMLARI

### Adım 1: Firebase Temizliği
1. Firebase Console'a git
2. Firestore Database → Aşağıdaki collection'ları sil:
   - questions
   - flashcards
   - topics
   - lessons
   - topic_stories
   - game_matching
   - game_memory
   - game_wordhunt
   - explanations
   - user_progress
   - user_favorites
   - streak_data
   - user_flashcard_progress
   - app_updates
   - notifications

### Adım 2: Security Rules Güncelle
1. Firestore → Rules
2. Yukarıdaki security rules'ı yapıştır
3. Publish

### Adım 3: Admin Koleksiyonu Oluştur
1. Firestore → Start collection
2. Collection ID: `admins`
3. Document ID: Kendi Firebase Auth UID'in
4. Fields:
   - email: "senin@email.com"
   - isAdmin: true
   - createdAt: (timestamp)

### Adım 4: Admin Panel Entegrasyonu
1. Admin paneli Firebase projesine bağla
2. Kullanıcı listesi için `users` collection'ını oku
3. User progress için `users/{userId}/data/progress` oku
4. İstatistikler için aggregate queries kullan

---

## 📝 NOTLAR

1. **Maliyet**: Bu yapı ile Firebase maliyeti minimum. Sadece user data sync için okuma/yazma yapılıyor.

2. **Offline Çalışma**: Uygulama tamamen offline çalışabilir. İnternet sadece login ve sync için gerekli.

3. **İçerik Güncelleme**: Yeni sorular/içerikler eklemek için uygulama güncellemesi gerekiyor. Bu, içerik kalitesini kontrol altında tutar.

4. **Veri Güvenliği**: Kullanıcı verileri sadece kendi hesaplarına erişebilir. Admin paneli ayrı yetkilendirme ile çalışır.

5. **Sync Çakışması**: Firebase ve local veri çakışırsa, daha yeni olan (lastSync tarihine göre) kullanılır.

---

## 🔗 İLGİLİ DOSYALAR

```
lib/core/services/local_progress_service.dart  → Local veri yönetimi
lib/core/services/sync_service.dart            → Firebase sync
lib/core/models/local_user_data.dart           → Veri modeli
lib/core/repositories/auth_repository.dart     → Authentication
lib/main.dart                                  → Uygulama başlatma
```

---

**Son Güncelleme**: 4 Aralık 2025
**Versiyon**: 2.0 (Local-First Architecture)
