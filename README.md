# 📚 KPSS 2026 - İçerik Veri Deposu

Bu repo, **KPSS Asistan 2026** uygulamasının içerik güncellemelerini barındırır. Uygulama açılışta bu repodan güncellemeleri kontrol eder ve yeni içerikleri otomatik olarak indirir.

> ⚠️ **Önemli:** Bu repo **private** olarak ayarlanmalıdır. Uygulama, GitHub API token'ı ile bu repoya erişir.

---

## 📁 Klasör Yapısı

```
kpss-data/
├── version.json                    # 🔑 VERSİYON KONTROLÜ (Bu dosyayı güncelle!)
├── flashcards/
│   └── {topicId}.json              # Flashcard verileri
├── stories/
│   └── {topicId}.json              # Hikaye verileri
├── explanations/
│   └── {topicId}.json              # Konu anlatımları
├── matching_games/
│   └── {topicId}.json              # Eşleştirme oyunları
└── questions/
    └── {topicId}.json              # Sorular
```

---

## 🔄 Sync Nasıl Çalışır?

1. Uygulama açılışta `version.json` dosyasını indirir
2. Her topic için **local versiyon** ile **remote versiyon** karşılaştırılır
3. `remoteVersion > localVersion` ise → İçerik indirilir
4. `remoteVersion <= localVersion` ise → İndirme yapılmaz (güncel)
5. İndirilen veriler cihazda cache'lenir

```
┌─────────────────────────────────────────────────────────────┐
│  Uygulama Açılışı                                           │
│  ↓                                                          │
│  version.json indir                                         │
│  ↓                                                          │
│  Her topic için:                                            │
│  ├─ remote > local? → İndir ve cache'le                     │
│  └─ remote <= local? → Atla (güncel)                        │
│  ↓                                                          │
│  Sync tamamlandı ✅                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Mevcut İçerikler

### Flashcards (10 Topic)
| Topic ID | Konu | Kart Sayısı |
|----------|------|-------------|
| `JnFbEQt0uA8RSEuy22SQ` | İslamiyet Öncesi Türk Tarihi | 195 |
| `9Hg8tuMRdMTuVY7OZ9HL` | İlk Müslüman Türk Devletleri | 37 |
| `rl2xQTfv1iUaCyhFzp5V` | Osmanlı Devleti Tarihi | 45 |
| `DlT19snCttf5j5RUAXLz` | Kurtuluş Savaşı Dönemi | 19 |
| `4GUvpqBBImcLmN2eh1HK` | Atatürk İlke ve İnkılapları | 54 |
| `onwrfsH02TgIhlyRUh56` | Cumhuriyet Dönemi | 38 |
| `qBFhnVl9E4oNj8MsBqnB` | Çağdaş Türk ve Dünya Tarihi | 15 |
| `80e0wkTLvaTQzPD6puB7` | Türkçe - Ses Bilgisi | 6 |
| `n4OjWupHmouuybQzQ1Fc` | Vatandaşlık - Anayasa | 7 |
| `1FEcPsGduhjcQARpaGBk` | Coğrafya - Konum | 1 |

### Stories (1 Topic)
| Topic ID | Konu | Hikaye Sayısı |
|----------|------|---------------|
| `JnFbEQt0uA8RSEuy22SQ` | İslamiyet Öncesi Türk Tarihi | 2 |

---

## 🔑 Topic ID Referansı

### TARİH (7 Konu)
| Topic ID | Konu Adı |
|----------|----------|
| `JnFbEQt0uA8RSEuy22SQ` | İslamiyet Öncesi Türk Tarihi |
| `9Hg8tuMRdMTuVY7OZ9HL` | İlk Müslüman Türk Devletleri |
| `rl2xQTfv1iUaCyhFzp5V` | Osmanlı Devleti Tarihi |
| `DlT19snCttf5j5RUAXLz` | Kurtuluş Savaşı Dönemi |
| `4GUvpqBBImcLmN2eh1HK` | Atatürk İlke ve İnkılapları |
| `onwrfsH02TgIhlyRUh56` | Cumhuriyet Dönemi |
| `qBFhnVl9E4oNj8MsBqnB` | Çağdaş Türk ve Dünya Tarihi |

### TÜRKÇE (9 Konu)
| Topic ID | Konu Adı |
|----------|----------|
| `80e0wkTLvaTQzPD6puB7` | Ses Bilgisi |
| `yWlh5C6jB7lzuJOodr2t` | Yapı Bilgisi |
| `ICNDiSlTmmjWEQPT6rmT` | Sözcük Türleri |
| `JmyiPxf3n96Jkxqsa9jY` | Sözcükte Anlam |
| `AJNLHhhaG2SLWOvxDYqW` | Cümlede Anlam |
| `nN8JOTR7LZm01AN2i3sQ` | Paragrafta Anlam |
| `jXcsrl5HEb65DmfpfqqI` | Anlatım Bozuklukları |
| `qSEqigIsIEBAkhcMTyCE` | Yazım ve Noktalama |
| `wnt2zWaV1pX8p8s8BBc9` | Sözel Mantık |

### COĞRAFYA (6 Konu)
| Topic ID | Konu Adı |
|----------|----------|
| `1FEcPsGduhjcQARpaGBk` | Türkiye'nin Coğrafi Konumu |
| `kbs0Ffved9pCP3Hq9M9k` | Türkiye'nin Fiziki Özellikleri |
| `6e0Thsz2RRNHFcwqQXso` | Türkiye'nin İklimi |
| `uYDrMlBCEAho5776WZi8` | Beşeri Coğrafya |
| `WxrtQ26p2My4uJa0h1kk` | Ekonomik Coğrafya |
| `GdpN8uxJNGtexWrkoL1T` | Türkiye'nin Coğrafi Bölgeleri |

### VATANDAŞLIK (6 Konu)
| Topic ID | Konu Adı |
|----------|----------|
| `AQ0Zph76dzPdr87H1uKa` | Hukuka Giriş |
| `n4OjWupHmouuybQzQ1Fc` | Anayasa Hukuku |
| `xXGXiqx2TkCtI4C7GMQg` | 1982 Anayasası |
| `1JZAYECyEn7farNNyGyx` | Devlet Organları |
| `lv93cmhwq7RmOFM5WxWD` | İdari Yapı |
| `Bo3qqooJsqtIZrK5zc9S` | Güncel Olaylar |

---

## ✏️ İçerik Güncelleme Rehberi

### Adım 1: JSON Dosyasını Düzenle

Örnek: `flashcards/JnFbEQt0uA8RSEuy22SQ.json` dosyasına yeni kart ekle:

```json
[
  {
    "question": "Mevcut soru",
    "answer": "Mevcut cevap"
  },
  {
    "question": "YENİ SORU",
    "answer": "YENİ CEVAP",
    "additionalInfo": "Ek bilgi (opsiyonel)"
  }
]
```

### Adım 2: version.json'u Güncelle

**⚠️ ÖNEMLİ:** Versiyonu artırmayı unutma! Artırmazsan uygulama indirmez.

```json
{
  "last_updated": "2025-12-17",
  "flashcards": {
    "JnFbEQt0uA8RSEuy22SQ": 2,  // 1'den 2'ye artır!
    ...
  }
}
```

### Adım 3: Commit & Push

```bash
git add .
git commit -m "Flashcard güncelleme: İslamiyet Öncesi Türk Tarihi v2"
git push
```

### Adım 4: Test Et

Uygulamayı aç ve logları kontrol et:
```
📥 flashcards/JnFbEQt0uA8RSEuy22SQ indiriliyor (local:1 -> remote:2)
✅ flashcards/JnFbEQt0uA8RSEuy22SQ v2 indirildi
```

---

## 📝 JSON Formatları

### Flashcards
```json
[
  {
    "question": "Soru / Ön yüz",
    "answer": "Cevap / Arka yüz",
    "additionalInfo": "Ek bilgi (opsiyonel)"
  }
]
```

### Stories (Hikayeler)
```json
[
  {
    "title": "Hikaye Başlığı",
    "content": "Hikaye içeriği...",
    "keyPoints": [
      "Önemli nokta 1",
      "Önemli nokta 2"
    ],
    "order": 0
  }
]
```

### Explanations (Konu Anlatımları)
```json
[
  {
    "title": "Bölüm Başlığı",
    "content": "Anlatım içeriği...",
    "order": 0
  }
]
```

### Matching Games (Eşleştirme)
```json
[
  {
    "left": "Sol taraf (terim)",
    "right": "Sağ taraf (tanım)"
  }
]
```

### Questions (Sorular)
```json
[
  {
    "id": "unique_id",
    "topicId": "JnFbEQt0uA8RSEuy22SQ",
    "q": "Soru metni?",
    "o": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı", "E şıkkı"],
    "a": 0,
    "e": "Açıklama"
  }
]
```

---

## ⚙️ Teknik Detaylar

### API Endpoint
```
https://api.github.com/repos/mertcanasdf/kpss-data/contents/{path}
```

### Authentication
```
Authorization: token {GITHUB_TOKEN}
Accept: application/vnd.github.v3.raw
```

### Cache Mekanizması
- Veriler `SharedPreferences`'ta cache'lenir
- Key formatı: `github_{type}_{topicId}_data`
- Versiyon key: `github_{type}_{topicId}_version`

---

## 🚨 Dikkat Edilmesi Gerekenler

1. **JSON Syntax:** Geçersiz JSON uygulama hatasına neden olur
2. **Versiyon Artırma:** Versiyonu artırmayı unutma!
3. **Topic ID:** Yanlış topic ID kullanma
4. **Encoding:** UTF-8 kullan (Türkçe karakterler için)
5. **Private Repo:** Repo private olmalı, token güvenli tutulmalı

---

## 📊 version.json Örneği

```json
{
  "last_updated": "2025-12-17",
  "flashcards": {
    "JnFbEQt0uA8RSEuy22SQ": 1,
    "9Hg8tuMRdMTuVY7OZ9HL": 1,
    "rl2xQTfv1iUaCyhFzp5V": 1
  },
  "stories": {
    "JnFbEQt0uA8RSEuy22SQ": 1
  },
  "explanations": {},
  "matching_games": {},
  "questions": {}
}
```

---

## 📞 Destek

Sorun yaşarsan uygulama loglarını kontrol et:
- `🔍 Fetching versions from:` - Version kontrolü başladı
- `📡 Version response: 200` - GitHub'a bağlantı başarılı
- `⏭️ güncel` - İndirme gerekmiyor
- `📥 indiriliyor` - Yeni içerik indiriliyor
- `✅ indirildi` - İndirme başarılı
- `❌` - Hata oluştu
