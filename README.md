# 🚀 KPSS Soru Yönetim Araçları v3.0

Modern, performanslı ve kullanımı kolay soru yönetim araçları.

## ✨ Özellikler

### Backend (question_server.js)
- **Modüler Mimari**: Servis bazlı clean architecture
- **AI Entegrasyonu**: OpenRouter API ile akıllı konu tespiti ve soru üretimi
- **Ultra Validasyon**: Benzerlik kontrolü, ID çarpışma tespiti, format kontrolü
- **Otomatik ID**: Konu bazlı akıllı ID oluşturma
- **Fallback Models**: AI hata durumunda otomatik model değişimi

### Frontend (public/)
- **Single Page App**: Modüler JavaScript yapısı
- **Modern UI**: Glassmorphism, animasyonlar, responsive tasarım
- **Dark Theme**: Göz yorgunluğunu azaltan koyu tema
- **Gerçek Zamanlı Validasyon**: Anında hata tespiti ve düzeltme önerileri

## 🏃‍♂️ Hızlı Başlangıç

```bash
# Sunucuyu başlat
cd tools
node question_server.js

# Tarayıcıda aç
http://localhost:3456
```

## 📁 Dosya Yapısı

```
tools/
├── question_server.js      # Ana API sunucusu
├── public/
│   ├── index.html          # Ana sayfa
│   ├── css/
│   │   └── style.css       # Tasarım sistemi
│   └── js/
│       ├── api.js          # API istemcisi
│       ├── app.js          # Ana uygulama
│       └── pages/
│           ├── input.js    # Giriş sayfası
│           ├── detect.js   # Konu tespiti
│           ├── editor.js   # Soru editörü
│           └── export.js   # Kayıt sayfası
└── archive/                # Eski dosyalar
```

## 🔌 API Endpoints

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/topics` | Tüm konuları listele |
| POST | `/detect` | AI ile konu tespiti |
| POST | `/validate` | Soru validasyonu |
| POST | `/auto-id` | Otomatik ID oluştur |
| POST | `/add` | Dosyaya ekle |
| POST | `/ai-fix` | AI ile düzelt |
| POST | `/ai-generate` | AI ile soru üret |

## 🧠 AI Modelleri

Sıralı fallback sistemi:
1. `google/gemini-2.5-flash` (Ana model)
2. `x-ai/grok-code-fast-1` (Yedek)
3. `google/gemini-2.5-flash-lite` (Ekonomik)

## 🛠️ Geliştirici Notları

### Yeni Konu Ekleme
`question_server.js` dosyasında `TOPICS` objesine ekle:
```javascript
'konu_id': { name: 'Konu Adı', lesson: 'DERS', prefix: 'on' }
```

### Keyword Tespiti
`TOPIC_KEYWORDS` objesine ilgili anahtar kelimeleri ekle.

## 📝 Değişiklik Günlüğü

### v3.0 (2024-12)
- ✅ Modüler mimari yeniden yazıldı
- ✅ Clean architecture prensipleri
- ✅ Modern CSS tasarım sistemi
- ✅ Retry logic ile güvenilir API
- ✅ Memory-safe body parsing
- ✅ Accessibility improvements

### v2.0
- AI konu tespiti
- Ultra validasyon
- Benzerlik kontrolü

### v1.0
- Temel soru ekleme
- Basit validasyon

---

**Made with ❤️ for KPSS 2026**
