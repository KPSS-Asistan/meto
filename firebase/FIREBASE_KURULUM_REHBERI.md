# Firebase Remote Config + Storage Kurulum Rehberi

## 1. Remote Config Ayarları

### YÖNTEM 1: Template Dosyasından Yükleme (Kolay)

1. Firebase Console → **Remote Config** → **Parametreler** sekmesi
2. Sağ üstteki **⋮** (3 nokta) menüsüne tıkla
3. **"Dosyadan yayınla"** seç
4. `firebase/remote_config_template.json` dosyasını seç
5. **"Yayınla"** butonuna tıkla

### YÖNTEM 2: Manuel Ekleme

1. https://console.firebase.google.com → Projen → **Remote Config**
2. **"Add parameter"** butonuna tıkla

### Eklenecek Parametreler:

| Parameter Name | Default Value | Type | Açıklama |
|----------------|---------------|------|----------|
| `questions_version` | `1` | Number | Sorular JSON versiyonu |
| `flashcards_version` | `1` | Number | Flashcards versiyonu |
| `stories_version` | `1` | Number | Hikayeler versiyonu |
| `explanations_version` | `1` | Number | Konu anlatımları versiyonu |
| `matching_games_version` | `1` | Number | Eşleştirme oyunları versiyonu |
| `minimum_app_version` | `1.0.0` | String | Minimum uygulama versiyonu |
| `maintenance_mode` | `false` | Boolean | Bakım modu |
| `daily_question_limit_free` | `20` | Number | Ücretsiz günlük limit |
| `ai_coach_enabled` | `true` | Boolean | AI Coach aktif mi |

3. **"Publish changes"** butonuna tıkla

---

## 2. Storage Ayarları

### 2.1 Klasör Yapısı
Firebase Console → **Storage** → **Files**

```
gs://your-bucket/
└── data/
    ├── questions.json      ← Tüm sorular
    ├── flashcards.json     ← (Opsiyonel)
    ├── stories.json        ← (Opsiyonel)
    └── explanations.json   ← (Opsiyonel)
```

### 2.2 Storage Rules
Firebase Console → Storage → **Rules** → Bu kodu yapıştır:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /data/{fileName} {
      allow read: if true;
      allow write: if false;
    }
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

**"Publish"** butonuna tıkla.

---

## 3. JSON Formatı

### questions.json Örneği:
```json
[
  {
    "id": "q_turkce_ses_1",
    "topicId": "turkce_ses_bilgisi",
    "lessonId": "turkce",
    "q": "Soru metni buraya",
    "o": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı"],
    "a": 0,
    "e": "Açıklama metni",
    "subtopicId": "alt_konu_id",
    "subtopic": "Alt Konu Adı"
  }
]
```

### Alan Açıklamaları:
- `id`: Benzersiz soru ID'si
- `topicId`: Ana konu ID'si
- `lessonId`: Ders ID'si (turkce, tarih, cografya, vatandaslik)
- `q`: Soru metni
- `o`: Şıklar dizisi (4-5 eleman)
- `a`: Doğru cevap indeksi (0'dan başlar)
- `e`: Açıklama (opsiyonel)
- `subtopicId`: Alt konu ID'si (opsiyonel)
- `subtopic`: Alt konu adı (opsiyonel)

---

## 4. Güncelleme Yapma

### Yeni Sorular Eklemek:

1. **Storage'a yeni JSON yükle:**
   - Firebase Console → Storage → data/
   - questions.json dosyasını sil
   - Yeni questions.json yükle

2. **Remote Config'de versiyonu artır:**
   ```
   questions_version: 1  →  questions_version: 2
   ```

3. **Publish changes**

### Ne Olacak?
- Kullanıcılar uygulamayı açtığında
- Remote Config "versiyon 2" der
- Uygulama "bende 1 var, indirmeliyim" der
- Storage'dan yeni JSON indirilir
- Lokal versiyonu 2 olarak günceller

---

## 5. Maliyet

| İşlem | Maliyet |
|-------|---------|
| Remote Config Fetch | **ÜCRETSİZ** |
| Storage Download (versiyon aynıysa) | **$0** |
| Storage Download (100KB dosya, 1000 kullanıcı) | ~$0.01 |
| Firestore Read | **$0** (kullanmıyoruz) |

---

## 6. Test Etme

### Debug Logları:
Uygulama açılışında şunları görmelisin:
```
✅ RemoteConfigService initialized
📡 Remote questions version: 1
📱 Local questions version: 0
⬇️ Yeni versiyon mevcut, indiriliyor...
✅ Sorular başarıyla indirildi
📡 QuestionsData: Remote veriler yükleniyor
✅ QuestionsData: X topic, kaynak: remote
```

### İlk Kurulumda:
- Remote Config'de `questions_version: 1` olmalı
- Storage'da `data/questions.json` dosyası olmalı
- Uygulama ilk açılışta verileri indirecek

---

## 7. Önemli Notlar

### ✅ YAPILMASI GEREKENLER:
1. Remote Config parametrelerini ekle
2. Storage'a questions.json yükle
3. Storage rules'u güncelle

### ❌ YAPILMAMASI GEREKENLER:
- Versiyonu Firestore'da tutma (her read para)
- Her açılışta Storage'dan indirme (bandwidth parası)
- Büyük JSON dosyaları (>5MB) kullanma
