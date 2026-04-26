/**
 * Explanations API Routes
 * Açıklama dosyaları için CRUD işlemleri
 */
const fs = require('fs').promises;
const path = require('path');
const { sendJSON, parseBody } = require('../utils/helper');

const EXPLANATIONS_DIR = path.join(__dirname, '../../../../explanations');

// Sıralama - Flutter topics_data.dart ile aynı sıra
const EXPLANATION_ORDER = [
    'JnFbEQt0uA8RSEuy22SQ','9Hg8tuMRdMTuVY7OZ9HL','8aIrKLvItXrwvOHq1L34','JU0iGKNhR7NQzA8M77vt','9WTotPoDW5OuWxsCf4Li',
    'DlT19snCttf5j5RUAXLz','4GUvpqBBImcLmN2eh1HK','onwrfsH02TgIhlyRUh56','xQWHl1hBYAKM96X4deR8',
    '80e0wkTLvaTQzPD6puB7','yWlh5C6jB7lzuJOodr2t','ICNDiSlTmmjWEQPT6rmT','JmyiPxf3n96Jkxqsa9jY','AJNLHhhaG2SLWOvxDYqW',
    'nN8JOTR7LZm01AN2i3sQ','jXcsrl5HEb65DmfpfqqI','qSEqigIsIEBAkhcMTyCE','wnt2zWaV1pX8p8s8BBc9',
    '1FEcPsGduhjcQARpaGBk','kbs0Ffved9pCP3Hq9M9k','6e0Thsz2RRNHFcwqQXso','uYDrMlBCEAho5776WZi8','WxrtQ26p2My4uJa0h1kk','GdpN8uxJNGtexWrkoL1T',
    'AQ0Zph76dzPdr87H1uKa','n4OjWupHmouuybQzQ1Fc','xXGXiqx2TkCtI4C7GMQg','1JZAYECyEn7farNNyGyx','lv93cmhwq7RmOFM5WxWD','Bo3qqooJsqtIZrK5zc9S',
];

const EXPLANATION_TITLES = {
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
if (!require('fs').existsSync(EXPLANATIONS_DIR)) {
    require('fs').mkdirSync(EXPLANATIONS_DIR, { recursive: true });
}

async function handleExplanationRoutes(req, res, pathname, searchParams) {
    
    // GET /explanations - Tüm açıklama dosyalarını listele
    if (pathname === '/explanations' && req.method === 'GET') {
        try {
            const files = await fs.readdir(EXPLANATIONS_DIR);
            const jsonFiles = files.filter(f => f.endsWith('.json'));
            
            const explanationFiles = [];
            for (const file of jsonFiles) {
                try {
                    const filePath = path.join(EXPLANATIONS_DIR, file);
                    const stats = await fs.stat(filePath);
                    const content = await fs.readFile(filePath, 'utf8');
                    const explanations = JSON.parse(content);
                    
                    const fileId = path.basename(file, '.json');
                    explanationFiles.push({
                        filename: file,
                        id: fileId,
                        title: EXPLANATION_TITLES[fileId] || fileId,
                        count: Array.isArray(explanations) ? explanations.length : 1,
                        lastModified: stats.mtime.toISOString(),
                        preview: Array.isArray(explanations) ? 
                            (explanations[0]?.title || explanations[0]?.topicId || '') : 
                            (explanations?.title || explanations?.topicId || '')
                    });
                } catch (e) {
                    console.error(`Error reading ${file}:`, e.message);
                }
            }
            
            explanationFiles.sort((a, b) => {
                const idxA = EXPLANATION_ORDER.indexOf(a.id);
                const idxB = EXPLANATION_ORDER.indexOf(b.id);
                return (idxA === -1 ? 999 : idxA) - (idxB === -1 ? 999 : idxB);
            });
            return sendJSON(res, { success: true, explanations: explanationFiles });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }
    
    // GET /explanations/:filename - Belirli dosyayı getir
    if (pathname.startsWith('/explanations/') && req.method === 'GET') {
        const parts = pathname.split('/');
        if (parts.length === 3) {
            const filename = parts[2];
            if (!filename.endsWith('.json')) {
                filename += '.json';
            }
            
            try {
                const filePath = path.join(EXPLANATIONS_DIR, filename);
                if (!require('fs').existsSync(filePath)) {
                    return sendJSON(res, { error: 'File not found' }, 404);
                }
                
                const content = await fs.readFile(filePath, 'utf8');
                const explanations = JSON.parse(content);
                
                return sendJSON(res, { 
                    success: true, 
                    filename,
                    explanations 
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    // POST /explanations/:filename - Yeni açıklama ekle
    if (pathname.startsWith('/explanations/') && req.method === 'POST') {
        const parts = pathname.split('/');
        if (parts.length === 3) {
            const filename = parts[2];
            if (!filename.endsWith('.json')) {
                filename += '.json';
            }
            
            try {
                const body = await parseBody(req);
                const { topicId, title, content, type, difficulty } = body;
                
                if (!topicId || !title || !content) {
                    return sendJSON(res, { error: 'Topic ID, title and content are required' }, 400);
                }
                
                const filePath = path.join(EXPLANATIONS_DIR, filename);
                let explanations = [];
                
                if (require('fs').existsSync(filePath)) {
                    const existingContent = await fs.readFile(filePath, 'utf8');
                    explanations = JSON.parse(existingContent);
                    if (!Array.isArray(explanations)) {
                        explanations = [explanations];
                    }
                }
                
                const newExplanation = {
                    id: `exp_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`,
                    topicId: topicId.trim(),
                    title: title.trim(),
                    content: content.trim(),
                    type: type || 'general',
                    difficulty: difficulty || 'medium',
                    createdAt: new Date().toISOString(),
                    updatedAt: new Date().toISOString()
                };
                
                explanations.push(newExplanation);
                await fs.writeFile(filePath, JSON.stringify(explanations, null, 2), 'utf8');
                
                return sendJSON(res, { 
                    success: true, 
                    message: 'Explanation added',
                    totalExplanations: explanations.length,
                    explanation: newExplanation
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    // POST /explanations/:filename/save - Tüm açıklamaları kaydet (full array replace)
    if (pathname.startsWith('/explanations/') && pathname.endsWith('/save') && req.method === 'POST') {
        const parts = pathname.split('/');
        if (parts.length === 4) {
            const filename = parts[2];
            
            try {
                const body = await parseBody(req);
                const { explanations } = body;
                
                if (!Array.isArray(explanations)) {
                    return sendJSON(res, { error: 'Explanations must be an array' }, 400);
                }
                
                // Validate each explanation
                for (let i = 0; i < explanations.length; i++) {
                    const exp = explanations[i];
                    if (!exp.topicId || !exp.title || !exp.content) {
                        return sendJSON(res, { error: `Item ${i}: topicId, title and content required` }, 400);
                    }
                    // Ensure id exists
                    if (!exp.id) {
                        exp.id = `exp_${Date.now()}_${Math.random().toString(36).substr(2, 4)}_${i}`;
                    }
                    // Ensure timestamps
                    if (!exp.createdAt) exp.createdAt = new Date().toISOString();
                    exp.updatedAt = new Date().toISOString();
                }
                
                const filePath = path.join(EXPLANATIONS_DIR, filename);
                await fs.writeFile(filePath, JSON.stringify(explanations, null, 2), 'utf8');
                
                return sendJSON(res, { 
                    success: true, 
                    message: 'All explanations saved',
                    count: explanations.length
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    // PUT /explanations/:filename/:index - Açıklama güncelle
    if (pathname.startsWith('/explanations/') && req.method === 'PUT') {
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
                const filePath = path.join(EXPLANATIONS_DIR, filename);
                if (!require('fs').existsSync(filePath)) {
                    return sendJSON(res, { error: 'File not found' }, 404);
                }
                
                const content = await fs.readFile(filePath, 'utf8');
                let explanations = JSON.parse(content);
                if (!Array.isArray(explanations)) {
                    explanations = [explanations];
                }
                
                if (index >= explanations.length) {
                    return sendJSON(res, { error: 'Index out of range' }, 400);
                }
                
                const body = await parseBody(req);
                const { topicId, title, content: explanationContent, type, difficulty } = body;
                
                explanations[index] = {
                    ...explanations[index],
                    topicId: topicId?.trim() || explanations[index].topicId,
                    title: title?.trim() || explanations[index].title,
                    content: explanationContent?.trim() || explanations[index].content,
                    type: type !== undefined ? type : explanations[index].type,
                    difficulty: difficulty !== undefined ? difficulty : explanations[index].difficulty,
                    updatedAt: new Date().toISOString()
                };
                
                await fs.writeFile(filePath, JSON.stringify(explanations, null, 2), 'utf8');
                
                return sendJSON(res, { 
                    success: true, 
                    message: 'Explanation updated',
                    explanation: explanations[index]
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    // DELETE /explanations/:filename/:index - Açıklama sil
    if (pathname.startsWith('/explanations/') && req.method === 'DELETE') {
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
                const filePath = path.join(EXPLANATIONS_DIR, filename);
                if (!require('fs').existsSync(filePath)) {
                    return sendJSON(res, { error: 'File not found' }, 404);
                }
                
                const content = await fs.readFile(filePath, 'utf8');
                let explanations = JSON.parse(content);
                if (!Array.isArray(explanations)) {
                    explanations = [explanations];
                }
                
                if (index >= explanations.length) {
                    return sendJSON(res, { error: 'Index out of range' }, 400);
                }
                
                const deletedExplanation = explanations.splice(index, 1)[0];
                await fs.writeFile(filePath, JSON.stringify(explanations, null, 2), 'utf8');
                
                return sendJSON(res, { 
                    success: true, 
                    message: 'Explanation deleted',
                    deletedExplanation,
                    remainingExplanations: explanations.length
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    return false; // Route handled
}

module.exports = handleExplanationRoutes;
