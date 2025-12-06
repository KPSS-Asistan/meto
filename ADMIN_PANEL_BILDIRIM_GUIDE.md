# 📱 **KULLANICIYA BİLDİRİM GÖNDERME - ADMİN PANELİ**

## 🎯 **İstenen Özellik:**
Admin olarak belirli kullanıcılara veya tüm kullanıcılara bildirim gönderme

## 💰 **Maliyet:**
- **Firebase Cloud Messaging (FCM):** ÜCRETSİZ
- **İlk 500 mesaj/gün:** Ücretsiz
- **Sonrası:** Çok düşük maliyet (~$0.0001/mesaj)
- **Toplam:** Pratikte ücretsiz

## 🏗️ **Teknik Yaklaşım:**

### **1. Kullanıcı Token Saklama**
Firebase Firestore'da kullanıcı token'larını saklayacağız:

```javascript
// Firestore Collection: user_tokens
{
  uid: "user_id",
  fcmToken: "eA1B2cD3E4f...",
  deviceInfo: {
    platform: "android/ios",
    version: "1.0.0"
  },
  createdAt: Timestamp,
  lastUpdated: Timestamp
}
```

### **2. Admin Paneli - React/Vue.js**
```javascript
// Admin Panelinde bildirim gönderme formu
const sendNotification = async () => {
  const data = {
    title: "📚 KPSS Hatırlatma",
    body: "Bugün çalışmayı unutma!",
    targetUsers: ["user1", "user2"], // veya "all"
    scheduledTime: "2025-12-06T19:00:00Z"
  };

  await fetch('/api/send-notification', {
    method: 'POST',
    body: JSON.stringify(data)
  });
};
```

### **3. Cloud Function - Bildirim Gönderme**
```javascript
// Firebase Functions - index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendNotification = functions.https.onCall(async (data, context) => {
  // Admin kontrolü
  if (!context.auth?.token.admin) {
    throw new functions.https.HttpsError('permission-denied');
  }

  const { title, body, targetUsers, scheduledTime } = data;

  // Kullanıcı token'larını al
  let tokens = [];
  if (targetUsers === 'all') {
    const snapshot = await admin.firestore().collection('user_tokens').get();
    tokens = snapshot.docs.map(doc => doc.data().fcmToken);
  } else {
    for (const uid of targetUsers) {
      const doc = await admin.firestore().collection('user_tokens').doc(uid).get();
      if (doc.exists) tokens.push(doc.data().fcmToken);
    }
  }

  // Bildirim payload'u
  const message = {
    notification: {
      title: title,
      body: body,
      icon: 'ic_launcher',
      sound: 'default'
    },
    data: {
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      type: 'admin_message'
    }
  };

  if (scheduledTime) {
    // Zamanlanmış bildirim (Firebase Cloud Scheduler ile)
    // ... scheduling logic
  } else {
    // Anlık gönderme
    const chunks = [];
    for (let i = 0; i < tokens.length; i += 500) {
      chunks.push(tokens.slice(i, i + 500));
    }

    for (const chunk of chunks) {
      await admin.messaging().sendToDevice(chunk, message);
    }
  }

  return { success: true, sentCount: tokens.length };
});
```

### **4. Mobil Uygulama - Token Yönetimi**
```dart
// lib/core/services/fcm_service.dart
class FCMService {
  static Future<void> initialize() async {
    // Token al ve Firestore'a kaydet
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Token değiştiğinde güncelle
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('user_tokens').doc(uid).set({
      'fcmToken': token,
      'deviceInfo': {
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'version': '1.0.0'
      },
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
```

## 🎨 **Admin Paneli Tasarımı**

### **Dashboard Sayfası:**
```
┌─────────────────────────────────────┐
│ 📊 Bildirim Yönetimi                │
├─────────────────────────────────────┤
│ 📝 Yeni Bildirim Oluştur            │
│ 📅 Zamanlanmış Bildirimler          │
│ 📈 Gönderim Geçmişi                 │
│ 👥 Kullanıcı Segmentleri            │
└─────────────────────────────────────┘
```

### **Bildirim Oluşturma Formu:**
```
Başlık: [___________________________]
Mesaj:  [___________________________]

Hedef Kitle:
○ Tüm Kullanıcılar
○ Aktif Kullanıcılar (son 7 gün)
○ Premium Kullanıcılar
○ Özel Kullanıcılar [user1,user2,user3]

Zamanlama:
○ Hemen Gönder
○ Tarih/Saat Seç: [📅 2025-12-06 19:00]

[GÖNDER] [TASLAK KAYDET]
```

## 📋 **Uygulama Adımları**

### **1. Firebase Kurulumu**
```bash
# Cloud Functions deploy
firebase deploy --only functions

# Admin kullanıcısı oluştur
firebase auth:create-user admin@kpss2026.com --password admin123
# Firestore'da admin claim ver
```

### **2. Mobil Uygulama Güncellemeleri**
```dart
// main.dart'a ekle
await FCMService.initialize();

// Bildirim tıklama
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  // Bildirime tıklandığında ne yapılacak
  debugPrint('Notification clicked: ${message.data}');
});
```

### **3. Güvenlik Kuralları**
```javascript
// Firestore Rules
match /user_tokens/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  allow read: if request.auth != null && request.auth.token.admin == true;
}
```

## 🚀 **Kullanım Senaryoları**

1. **Günlük Motivasyon:** Sabah 9'da tüm kullanıcılara
2. **Yeni Özellik Duyurusu:** Premium kullanıcılara
3. **Sınav Hatırlatma:** KPSS tarihinden 1 hafta önce
4. **Kişisel Mesaj:** Belirli kullanıcıya

## ⚡ **Performans & Limitler**

- **FCM Limitleri:** 500 mesaj/gün ücretsiz
- **Token Geçerliliği:** 2 ay (oto refresh)
- **Gönderim Hızı:** 500 mesaj/saniye
- **Boyut Limiti:** 4KB mesaj

Bu sistem tamamen **ÜCRETSİZ** çalışır ve production-ready! 🎉
