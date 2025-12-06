# Firebase Temizlik Kontrol Listesi

## ❌ SİLİNECEK COLLECTION'LAR

Firebase Console → Firestore Database → Her birini sil:

### İçerik (Artık Hardcoded):
- [ ] `questions`
- [ ] `flashcards`
- [ ] `topics`
- [ ] `lessons`
- [ ] `topic_stories`
- [ ] `game_matching`
- [ ] `game_memory`
- [ ] `game_wordhunt`
- [ ] `explanations`

### Eski User Data (Yeni yapıya taşındı):
- [ ] `user_progress`
- [ ] `user_favorites`
- [ ] `streak_data`
- [ ] `user_flashcard_progress`

### Diğer Gereksiz:
- [ ] `app_updates`
- [ ] `notifications`

---

## ✅ KALACAK YAPILAR

```
users/
└── {userId}/
    ├── email
    ├── displayName
    ├── createdAt
    ├── lastLoginAt
    ├── isPremium
    └── data/
        └── progress/  ← TÜM USER DATA BURADA
```

---

## 🔐 YENİ SECURITY RULES

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /data/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    match /{document=**} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

---

## 👤 ADMİN OLUŞTUR

1. `admins` collection oluştur
2. Document ID = Senin Firebase Auth UID
3. Fields:
   - `email`: "senin@email.com"
   - `isAdmin`: true
   - `createdAt`: timestamp

---

## 📊 ADMİN PANELİ İÇİN QUERY'LER

### Tüm Kullanıcılar:
```javascript
db.collection('users').get()
```

### Kullanıcı Progress:
```javascript
db.collection('users').doc(userId).collection('data').doc('progress').get()
```

### Aktif Kullanıcılar (Son 7 gün):
```javascript
db.collection('users')
  .where('lastLoginAt', '>=', sevenDaysAgo)
  .get()
```

### Premium Kullanıcılar:
```javascript
db.collection('users')
  .where('isPremium', '==', true)
  .get()
```

---

**Tahmini Temizlik Süresi**: 5-10 dakika
**Risk**: Düşük (içerikler zaten hardcoded)
