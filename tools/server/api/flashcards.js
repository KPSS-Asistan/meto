/**
 * Flashcards API Routes
 * Flashcard setleri için CRUD işlemleri
 */
const fs = require('fs').promises;
const path = require('path');
const { sendJSON, parseBody } = require('../utils/helper');
const { FLASHCARDS_DIR } = require('../config');

// Ensure directory exists
if (!require('fs').existsSync(FLASHCARDS_DIR)) {
    require('fs').mkdirSync(FLASHCARDS_DIR, { recursive: true });
}

// Sıralama - Flutter topics_data.dart ile aynı sıra
const FLASHCARD_ORDER = [
    // TARİH (9)
    'JnFbEQt0uA8RSEuy22SQ',
    '9Hg8tuMRdMTuVY7OZ9HL',
    '8aIrKLvItXrwvOHq1L34',
    'JU0iGKNhR7NQzA8M77vt',
    '9WTotPoDW5OuWxsCf4Li',
    'DlT19snCttf5j5RUAXLz',
    '4GUvpqBBImcLmN2eh1HK',
    'onwrfsH02TgIhlyRUh56',
    'xQWHl1hBYAKM96X4deR8',
    // TÜRKÇE (9)
    '80e0wkTLvaTQzPD6puB7',
    'yWlh5C6jB7lzuJOodr2t',
    'ICNDiSlTmmjWEQPT6rmT',
    'JmyiPxf3n96Jkxqsa9jY',
    'AJNLHhhaG2SLWOvxDYqW',
    'nN8JOTR7LZm01AN2i3sQ',
    'jXcsrl5HEb65DmfpfqqI',
    'qSEqigIsIEBAkhcMTyCE',
    'wnt2zWaV1pX8p8s8BBc9',
    // COĞRAFYA (6)
    '1FEcPsGduhjcQARpaGBk',
    'kbs0Ffved9pCP3Hq9M9k',
    '6e0Thsz2RRNHFcwqQXso',
    'uYDrMlBCEAho5776WZi8',
    'WxrtQ26p2My4uJa0h1kk',
    'GdpN8uxJNGtexWrkoL1T',
    // VATANDAŞLIK (6)
    'AQ0Zph76dzPdr87H1uKa',
    'n4OjWupHmouuybQzQ1Fc',
    'xXGXiqx2TkCtI4C7GMQg',
    '1JZAYECyEn7farNNyGyx',
    'lv93cmhwq7RmOFM5WxWD',
    'Bo3qqooJsqtIZrK5zc9S',
];

// Türkçe başlık mapping
const FLASHCARD_TITLES = {
    // TARİH (9)
    'JnFbEQt0uA8RSEuy22SQ': 'Tarih - İslamiyet Öncesi Türk Tarihi',
    '9Hg8tuMRdMTuVY7OZ9HL': 'Tarih - İlk Müslüman Türk Devletleri',
    '8aIrKLvItXrwvOHq1L34': 'Tarih - Türkiye Selçuklu Devleti',
    'JU0iGKNhR7NQzA8M77vt': 'Tarih - Osmanlı Devleti (Siyasi)',
    '9WTotPoDW5OuWxsCf4Li': 'Tarih - Osmanlı Devleti (Kültür)',
    'DlT19snCttf5j5RUAXLz': 'Tarih - Kurtuluş Savaşı Dönemi',
    '4GUvpqBBImcLmN2eh1HK': 'Tarih - Atatürk İlke ve İnkılapları',
    'onwrfsH02TgIhlyRUh56': 'Tarih - Cumhuriyet Dönemi',
    'xQWHl1hBYAKM96X4deR8': 'Tarih - Çağdaş Türk ve Dünya Tarihi',
    // TÜRKÇE (9)
    '80e0wkTLvaTQzPD6puB7': 'Türkçe - Ses Bilgisi',
    'yWlh5C6jB7lzuJOodr2t': 'Türkçe - Yapı Bilgisi',
    'ICNDiSlTmmjWEQPT6rmT': 'Türkçe - Sözcük Türleri',
    'JmyiPxf3n96Jkxqsa9jY': 'Türkçe - Sözcükte Anlam',
    'AJNLHhhaG2SLWOvxDYqW': 'Türkçe - Cümlede Anlam',
    'nN8JOTR7LZm01AN2i3sQ': 'Türkçe - Paragrafta Anlam',
    'jXcsrl5HEb65DmfpfqqI': 'Türkçe - Anlatım Bozuklukları',
    'qSEqigIsIEBAkhcMTyCE': 'Türkçe - Yazım Kuralları ve Noktalama',
    'wnt2zWaV1pX8p8s8BBc9': 'Türkçe - Sözel Mantık ve Akıl Yürütme',
    // COĞRAFYA (6)
    '1FEcPsGduhjcQARpaGBk': 'Coğrafya - Türkiye\'nin Coğrafi Konumu',
    'kbs0Ffved9pCP3Hq9M9k': 'Coğrafya - Türkiye\'nin Fiziki Özellikleri',
    '6e0Thsz2RRNHFcwqQXso': 'Coğrafya - İklim ve Bitki Örtüsü',
    'uYDrMlBCEAho5776WZi8': 'Coğrafya - Beşeri Coğrafya',
    'WxrtQ26p2My4uJa0h1kk': 'Coğrafya - Ekonomik Coğrafya',
    'GdpN8uxJNGtexWrkoL1T': 'Coğrafya - Türkiye\'nin Coğrafi Bölgeleri',
    // VATANDAŞLIK (6)
    'AQ0Zph76dzPdr87H1uKa': 'Vatandaşlık - Hukuka Giriş',
    'n4OjWupHmouuybQzQ1Fc': 'Vatandaşlık - Anayasa Hukuku',
    'xXGXiqx2TkCtI4C7GMQg': 'Vatandaşlık - 1982 Anayasası Temel İlkeleri',
    '1JZAYECyEn7farNNyGyx': 'Vatandaşlık - Devlet Organları',
    'lv93cmhwq7RmOFM5WxWD': 'Vatandaşlık - İdari Yapı',
    'Bo3qqooJsqtIZrK5zc9S': 'Vatandaşlık - Temel Hak ve Özgürlükler',
};

async function handleFlashcardRoutes(req, res, pathname, searchParams) {

    // GET /flashcards - Tüm flashcard dosyalarını listele
    if (pathname === '/flashcards' && req.method === 'GET') {
        try {
            console.log('[Flashcards API] Reading directory:', FLASHCARDS_DIR);
            const files = await fs.readdir(FLASHCARDS_DIR);
            console.log('[Flashcards API] Files found:', files);
            const jsonFiles = files.filter(f => f.endsWith('.json'));
            console.log('[Flashcards API] JSON files:', jsonFiles);

            const flashcardSets = [];
            for (const file of jsonFiles) {
                try {
                    const filePath = path.join(FLASHCARDS_DIR, file);
                    const stats = await fs.stat(filePath);
                    const content = await fs.readFile(filePath, 'utf8');
                    const cards = JSON.parse(content);
                    const fileId = path.basename(file, '.json');

                    flashcardSets.push({
                        filename: file,
                        id: fileId,
                        title: FLASHCARD_TITLES[fileId] || fileId, // Türkçe başlık ekle
                        count: cards.length,
                        lastModified: stats.mtime.toISOString(),
                        preview: cards[0]?.question || ''
                    });
                } catch (e) {
                    console.error(`Error reading ${file}:`, e.message);
                }
            }

            flashcardSets.sort((a, b) => {
                const idxA = FLASHCARD_ORDER.indexOf(a.id);
                const idxB = FLASHCARD_ORDER.indexOf(b.id);
                return (idxA === -1 ? 999 : idxA) - (idxB === -1 ? 999 : idxB);
            });
            console.log('[Flashcards API] Returning sets:', flashcardSets.length);
            return sendJSON(res, { success: true, flashcards: flashcardSets });
        } catch (e) {
            console.error('[Flashcards API] Error:', e);
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // GET /flashcards/:filename - Belirli dosyayı getir
    if (pathname.startsWith('/flashcards/') && req.method === 'GET') {
        const parts = pathname.split('/');
        if (parts.length === 3) {
            const filename = parts[2];
            if (!filename.endsWith('.json')) {
                filename += '.json';
            }

            try {
                const filePath = path.join(FLASHCARDS_DIR, filename);
                if (!require('fs').existsSync(filePath)) {
                    return sendJSON(res, { error: 'File not found' }, 404);
                }

                const content = await fs.readFile(filePath, 'utf8');
                const cards = JSON.parse(content);

                return sendJSON(res, {
                    success: true,
                    filename,
                    cards
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }

    // POST /flashcards/:filename - Yeni flashcard ekle
    if (pathname.startsWith('/flashcards/') && req.method === 'POST') {
        const parts = pathname.split('/');
        if (parts.length === 3) {
            const filename = parts[2];
            if (!filename.endsWith('.json')) {
                filename += '.json';
            }

            try {
                const body = await parseBody(req);
                const { question, answer, additionalInfo } = body;

                if (!question || !answer) {
                    return sendJSON(res, { error: 'Question and answer are required' }, 400);
                }

                const filePath = path.join(FLASHCARDS_DIR, filename);
                let cards = [];

                if (require('fs').existsSync(filePath)) {
                    const content = await fs.readFile(filePath, 'utf8');
                    cards = JSON.parse(content);
                }

                const newCard = {
                    question: question.trim(),
                    answer: answer.trim(),
                    additionalInfo: additionalInfo?.trim() || ''
                };

                cards.push(newCard);
                await fs.writeFile(filePath, JSON.stringify(cards, null, 2), 'utf8');

                return sendJSON(res, {
                    success: true,
                    message: 'Flashcard added',
                    totalCards: cards.length,
                    card: newCard
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }

    // POST /flashcards/:filename/save - Tüm flashcard'ları kaydet (full array replace)
    if (pathname.startsWith('/flashcards/') && pathname.endsWith('/save') && req.method === 'POST') {
        const parts = pathname.split('/');
        if (parts.length === 4) {
            let filename = parts[2];

            try {
                const body = await parseBody(req);
                const { cards } = body;

                if (!Array.isArray(cards)) {
                    return sendJSON(res, { error: 'Cards must be an array' }, 400);
                }

                // Validate each card
                for (let i = 0; i < cards.length; i++) {
                    const card = cards[i];
                    if (!card.question || !card.answer) {
                        return sendJSON(res, { error: `Item ${i}: question and answer required` }, 400);
                    }
                }

                const filePath = path.join(FLASHCARDS_DIR, filename);
                await fs.writeFile(filePath, JSON.stringify(cards, null, 2), 'utf8');

                return sendJSON(res, {
                    success: true,
                    message: 'All flashcards saved',
                    count: cards.length
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }

    // PUT /flashcards/:filename/:index - Flashcard güncelle
    if (pathname.startsWith('/flashcards/') && req.method === 'PUT') {
        const parts = pathname.split('/');
        if (parts.length === 4) {
            const filename = parts[2];
            const index = parseInt(parts[3]);

            if (!filename.endsWith('.json')) {
                filename += '.json';
            }

            if (isNaN(index) || index < 0) {
                return sendJSON(res, { error: 'Invalid index' }, 400);
            }

            try {
                const filePath = path.join(FLASHCARDS_DIR, filename);
                if (!require('fs').existsSync(filePath)) {
                    return sendJSON(res, { error: 'File not found' }, 404);
                }

                const content = await fs.readFile(filePath, 'utf8');
                const cards = JSON.parse(content);

                if (index >= cards.length) {
                    return sendJSON(res, { error: 'Index out of range' }, 400);
                }

                const body = await parseBody(req);
                const { question, answer, additionalInfo } = body;

                cards[index] = {
                    question: question?.trim() || cards[index].question,
                    answer: answer?.trim() || cards[index].answer,
                    additionalInfo: additionalInfo?.trim() || cards[index].additionalInfo
                };

                await fs.writeFile(filePath, JSON.stringify(cards, null, 2), 'utf8');

                return sendJSON(res, {
                    success: true,
                    message: 'Flashcard updated',
                    card: cards[index]
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }

    // DELETE /flashcards/:filename/:index - Flashcard sil
    if (pathname.startsWith('/flashcards/') && req.method === 'DELETE') {
        const parts = pathname.split('/');
        if (parts.length === 4) {
            const filename = parts[2];
            const index = parseInt(parts[3]);

            if (!filename.endsWith('.json')) {
                filename += '.json';
            }

            if (isNaN(index) || index < 0) {
                return sendJSON(res, { error: 'Invalid index' }, 400);
            }

            try {
                const filePath = path.join(FLASHCARDS_DIR, filename);
                if (!require('fs').existsSync(filePath)) {
                    return sendJSON(res, { error: 'File not found' }, 404);
                }

                const content = await fs.readFile(filePath, 'utf8');
                const cards = JSON.parse(content);

                if (index >= cards.length) {
                    return sendJSON(res, { error: 'Index out of range' }, 400);
                }

                const deletedCard = cards.splice(index, 1)[0];
                await fs.writeFile(filePath, JSON.stringify(cards, null, 2), 'utf8');

                return sendJSON(res, {
                    success: true,
                    message: 'Flashcard deleted',
                    deletedCard,
                    remainingCards: cards.length
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }

    return false; // Route handled
}

module.exports = handleFlashcardRoutes;
