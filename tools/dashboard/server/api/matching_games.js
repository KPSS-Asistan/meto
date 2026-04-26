/**
 * Matching Games API Routes
 * Eşleştirme oyunları için CRUD işlemleri
 */
const fs = require('fs').promises;
const path = require('path');
const { sendJSON, parseBody } = require('../utils/helper');

const MATCHING_GAMES_DIR = path.join(__dirname, '../../../../matching_games');

// Sıralama - Flutter topics_data.dart ile aynı sıra
const MATCHING_ORDER = [
    'JnFbEQt0uA8RSEuy22SQ','9Hg8tuMRdMTuVY7OZ9HL','8aIrKLvItXrwvOHq1L34','JU0iGKNhR7NQzA8M77vt','9WTotPoDW5OuWxsCf4Li',
    'DlT19snCttf5j5RUAXLz','4GUvpqBBImcLmN2eh1HK','onwrfsH02TgIhlyRUh56','xQWHl1hBYAKM96X4deR8',
    '80e0wkTLvaTQzPD6puB7','yWlh5C6jB7lzuJOodr2t','ICNDiSlTmmjWEQPT6rmT','JmyiPxf3n96Jkxqsa9jY','AJNLHhhaG2SLWOvxDYqW',
    'nN8JOTR7LZm01AN2i3sQ','jXcsrl5HEb65DmfpfqqI','qSEqigIsIEBAkhcMTyCE','wnt2zWaV1pX8p8s8BBc9',
    '1FEcPsGduhjcQARpaGBk','kbs0Ffved9pCP3Hq9M9k','6e0Thsz2RRNHFcwqQXso','uYDrMlBCEAho5776WZi8','WxrtQ26p2My4uJa0h1kk','GdpN8uxJNGtexWrkoL1T',
    'AQ0Zph76dzPdr87H1uKa','n4OjWupHmouuybQzQ1Fc','xXGXiqx2TkCtI4C7GMQg','1JZAYECyEn7farNNyGyx','lv93cmhwq7RmOFM5WxWD','Bo3qqooJsqtIZrK5zc9S',
];

const MATCHING_TITLES = {
    'JnFbEQt0uA8RSEuy22SQ': 'Tarih - İslamiyet Öncesi Türk Tarihi',
    '9Hg8tuMRdMTuVY7OZ9HL': 'Tarih - İlk Müslüman Türk Devletleri',
    '8aIrKLvItXrwvOHq1L34': 'Tarih - Türkiye Selçuklu Devleti',
    'JU0iGKNhR7NQzA8M77vt': 'Tarih - Osmanlı Devleti (Siyasi)',
    '9WTotPoDW5OuWxsCf4Li': 'Tarih - Osmanlı Devleti (Kültür)',
    'DlT19snCttf5j5RUAXLz': 'Tarih - Kurtuluş Savaşı Dönemi',
    '4GUvpqBBImcLmN2eh1HK': 'Tarih - Atatürk İlke ve İnkılapları',
    'onwrfsH02TgIhlyRUh56': 'Tarih - Cumhuriyet Dönemi',
    'xQWHl1hBYAKM96X4deR8': 'Tarih - Çağdaş Türk ve Dünya Tarihi',
    '80e0wkTLvaTQzPD6puB7': 'Türkçe - Ses Bilgisi',
    'yWlh5C6jB7lzuJOodr2t': 'Türkçe - Yapı Bilgisi',
    'ICNDiSlTmmjWEQPT6rmT': 'Türkçe - Sözcük Türleri',
    'JmyiPxf3n96Jkxqsa9jY': 'Türkçe - Sözcükte Anlam',
    'AJNLHhhaG2SLWOvxDYqW': 'Türkçe - Cümlede Anlam',
    'nN8JOTR7LZm01AN2i3sQ': 'Türkçe - Paragrafta Anlam',
    'jXcsrl5HEb65DmfpfqqI': 'Türkçe - Anlatım Bozuklukları',
    'qSEqigIsIEBAkhcMTyCE': 'Türkçe - Yazım Kuralları ve Noktalama',
    'wnt2zWaV1pX8p8s8BBc9': 'Türkçe - Sözel Mantık ve Akıl Yürütme',
    '1FEcPsGduhjcQARpaGBk': 'Coğrafya - Türkiye\'nin Coğrafi Konumu',
    'kbs0Ffved9pCP3Hq9M9k': 'Coğrafya - Türkiye\'nin Fiziki Özellikleri',
    '6e0Thsz2RRNHFcwqQXso': 'Coğrafya - İklim ve Bitki Örtüsü',
    'uYDrMlBCEAho5776WZi8': 'Coğrafya - Beşeri Coğrafya',
    'WxrtQ26p2My4uJa0h1kk': 'Coğrafya - Ekonomik Coğrafya',
    'GdpN8uxJNGtexWrkoL1T': 'Coğrafya - Türkiye\'nin Coğrafi Bölgeleri',
    'AQ0Zph76dzPdr87H1uKa': 'Vatandaşlık - Hukuka Giriş',
    'n4OjWupHmouuybQzQ1Fc': 'Vatandaşlık - Anayasa Hukuku',
    'xXGXiqx2TkCtI4C7GMQg': 'Vatandaşlık - 1982 Anayasası Temel İlkeleri',
    '1JZAYECyEn7farNNyGyx': 'Vatandaşlık - Devlet Organları',
    'lv93cmhwq7RmOFM5WxWD': 'Vatandaşlık - İdari Yapı',
    'Bo3qqooJsqtIZrK5zc9S': 'Vatandaşlık - Temel Hak ve Özgürlükler',
};

// Ensure directory exists
if (!require('fs').existsSync(MATCHING_GAMES_DIR)) {
    require('fs').mkdirSync(MATCHING_GAMES_DIR, { recursive: true });
}

async function handleMatchingGamesRoutes(req, res, pathname, searchParams) {
    
    // GET /matching-games - Tüm matching game dosyalarını listele
    if (pathname === '/matching-games' && req.method === 'GET') {
        try {
            const files = await fs.readdir(MATCHING_GAMES_DIR);
            const jsonFiles = files.filter(f => f.endsWith('.json'));
            
            const gameFiles = [];
            for (const file of jsonFiles) {
                try {
                    const filePath = path.join(MATCHING_GAMES_DIR, file);
                    const stats = await fs.stat(filePath);
                    const content = await fs.readFile(filePath, 'utf8');
                    const games = JSON.parse(content);
                    
                    const fileId = path.basename(file, '.json');
                    gameFiles.push({
                        filename: file,
                        id: fileId,
                        title: MATCHING_TITLES[fileId] || fileId,
                        count: games.length,
                        lastModified: stats.mtime.toISOString(),
                        preview: games[0]?.title || games[0]?.question || ''
                    });
                } catch (e) {
                    console.error(`Error reading ${file}:`, e.message);
                }
            }
            
            gameFiles.sort((a, b) => {
                const idxA = MATCHING_ORDER.indexOf(a.id);
                const idxB = MATCHING_ORDER.indexOf(b.id);
                return (idxA === -1 ? 999 : idxA) - (idxB === -1 ? 999 : idxB);
            });
            return sendJSON(res, { success: true, games: gameFiles });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }
    
    // GET /matching-games/:filename - Belirli dosyayı getir
    if (pathname.startsWith('/matching-games/') && req.method === 'GET') {
        const parts = pathname.split('/');
        if (parts.length === 3) {
            const filename = parts[2];
            if (!filename.endsWith('.json')) {
                filename += '.json';
            }
            
            try {
                const filePath = path.join(MATCHING_GAMES_DIR, filename);
                if (!require('fs').existsSync(filePath)) {
                    return sendJSON(res, { error: 'File not found' }, 404);
                }
                
                const content = await fs.readFile(filePath, 'utf8');
                const games = JSON.parse(content);
                
                return sendJSON(res, { 
                    success: true, 
                    filename,
                    games 
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    // POST /matching-games/:filename - Yeni matching game ekle
    if (pathname.startsWith('/matching-games/') && req.method === 'POST') {
        const parts = pathname.split('/');
        if (parts.length === 3) {
            const filename = parts[2];
            if (!filename.endsWith('.json')) {
                filename += '.json';
            }
            
            try {
                const body = await parseBody(req);
                const { title, question, pairs, difficulty } = body;
                
                if (!title || !question || !pairs) {
                    return sendJSON(res, { error: 'Title, question and pairs are required' }, 400);
                }
                
                const filePath = path.join(MATCHING_GAMES_DIR, filename);
                let games = [];
                
                if (require('fs').existsSync(filePath)) {
                    const existingContent = await fs.readFile(filePath, 'utf8');
                    games = JSON.parse(existingContent);
                }
                
                const newGame = {
                    id: `mg_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`,
                    title: title.trim(),
                    question: question.trim(),
                    pairs: Array.isArray(pairs) ? pairs : [],
                    difficulty: difficulty || 'medium',
                    createdAt: new Date().toISOString(),
                    updatedAt: new Date().toISOString()
                };
                
                games.push(newGame);
                await fs.writeFile(filePath, JSON.stringify(games, null, 2), 'utf8');
                
                return sendJSON(res, { 
                    success: true, 
                    message: 'Matching game added',
                    totalGames: games.length,
                    game: newGame
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    // POST /matching-games/:filename/save - Tüm oyunları kaydet (full array replace)
    if (pathname.startsWith('/matching-games/') && pathname.endsWith('/save') && req.method === 'POST') {
        const parts = pathname.split('/');
        if (parts.length === 4) {
            let filename = parts[2];
            
            try {
                const body = await parseBody(req);
                const { games } = body;
                
                if (!Array.isArray(games)) {
                    return sendJSON(res, { error: 'Games must be an array' }, 400);
                }
                
                // Validate each game
                for (let i = 0; i < games.length; i++) {
                    const game = games[i];
                    if (!game.title || !game.question || !game.pairs) {
                        return sendJSON(res, { error: `Item ${i}: title, question and pairs required` }, 400);
                    }
                    if (!Array.isArray(game.pairs)) {
                        return sendJSON(res, { error: `Item ${i}: pairs must be an array` }, 400);
                    }
                    if (!game.id) {
                        game.id = `mg_${Date.now()}_${Math.random().toString(36).substr(2, 4)}_${i}`;
                    }
                }
                
                const filePath = path.join(MATCHING_GAMES_DIR, filename);
                await fs.writeFile(filePath, JSON.stringify(games, null, 2), 'utf8');
                
                return sendJSON(res, { 
                    success: true, 
                    message: 'All matching games saved',
                    count: games.length
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    // PUT /matching-games/:filename/:index - Matching game güncelle
    if (pathname.startsWith('/matching-games/') && req.method === 'PUT') {
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
                const filePath = path.join(MATCHING_GAMES_DIR, filename);
                if (!require('fs').existsSync(filePath)) {
                    return sendJSON(res, { error: 'File not found' }, 404);
                }
                
                const content = await fs.readFile(filePath, 'utf8');
                const games = JSON.parse(content);
                
                if (index >= games.length) {
                    return sendJSON(res, { error: 'Index out of range' }, 400);
                }
                
                const body = await parseBody(req);
                const { title, question, pairs, difficulty } = body;
                
                games[index] = {
                    ...games[index],
                    title: title?.trim() || games[index].title,
                    question: question?.trim() || games[index].question,
                    pairs: Array.isArray(pairs) ? pairs : games[index].pairs,
                    difficulty: difficulty !== undefined ? difficulty : games[index].difficulty,
                    updatedAt: new Date().toISOString()
                };
                
                await fs.writeFile(filePath, JSON.stringify(games, null, 2), 'utf8');
                
                return sendJSON(res, { 
                    success: true, 
                    message: 'Matching game updated',
                    game: games[index]
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    // DELETE /matching-games/:filename/:index - Matching game sil
    if (pathname.startsWith('/matching-games/') && req.method === 'DELETE') {
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
                const filePath = path.join(MATCHING_GAMES_DIR, filename);
                if (!require('fs').existsSync(filePath)) {
                    return sendJSON(res, { error: 'File not found' }, 404);
                }
                
                const content = await fs.readFile(filePath, 'utf8');
                const games = JSON.parse(content);
                
                if (index >= games.length) {
                    return sendJSON(res, { error: 'Index out of range' }, 400);
                }
                
                const deletedGame = games.splice(index, 1)[0];
                await fs.writeFile(filePath, JSON.stringify(games, null, 2), 'utf8');
                
                return sendJSON(res, { 
                    success: true, 
                    message: 'Matching game deleted',
                    deletedGame,
                    remainingGames: games.length
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    return false; // Route handled
}

module.exports = handleMatchingGamesRoutes;
