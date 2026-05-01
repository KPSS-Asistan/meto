/**
 * Stories API Routes
 * Story dosyaları için CRUD işlemleri
 */
const fs = require('fs').promises;
const path = require('path');
const { sendJSON, parseBody } = require('../utils/helper');
const { STORIES_DIR } = require('../config');

// Sıralama - Flutter topics_data.dart ile aynı sıra
const STORY_ORDER = [
    'JnFbEQt0uA8RSEuy22SQ','9Hg8tuMRdMTuVY7OZ9HL','8aIrKLvItXrwvOHq1L34','JU0iGKNhR7NQzA8M77vt','9WTotPoDW5OuWxsCf4Li',
    'DlT19snCttf5j5RUAXLz','4GUvpqBBImcLmN2eh1HK','onwrfsH02TgIhlyRUh56','xQWHl1hBYAKM96X4deR8',
    '80e0wkTLvaTQzPD6puB7','yWlh5C6jB7lzuJOodr2t','ICNDiSlTmmjWEQPT6rmT','JmyiPxf3n96Jkxqsa9jY','AJNLHhhaG2SLWOvxDYqW',
    'nN8JOTR7LZm01AN2i3sQ','jXcsrl5HEb65DmfpfqqI','qSEqigIsIEBAkhcMTyCE','wnt2zWaV1pX8p8s8BBc9',
    '1FEcPsGduhjcQARpaGBk','kbs0Ffved9pCP3Hq9M9k','6e0Thsz2RRNHFcwqQXso','uYDrMlBCEAho5776WZi8','WxrtQ26p2My4uJa0h1kk','GdpN8uxJNGtexWrkoL1T',
    'AQ0Zph76dzPdr87H1uKa','n4OjWupHmouuybQzQ1Fc','xXGXiqx2TkCtI4C7GMQg','1JZAYECyEn7farNNyGyx','lv93cmhwq7RmOFM5WxWD','Bo3qqooJsqtIZrK5zc9S',
];

const STORY_TITLES = {
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
if (!require('fs').existsSync(STORIES_DIR)) {
    require('fs').mkdirSync(STORIES_DIR, { recursive: true });
}

async function handleStoryRoutes(req, res, pathname, searchParams) {
    
    // GET /stories - Tüm story dosyalarını listele
    if (pathname === '/stories' && req.method === 'GET') {
        try {
            const files = await fs.readdir(STORIES_DIR);
            const jsonFiles = files.filter(f => f.endsWith('.json'));
            
            const storyFiles = [];
            for (const file of jsonFiles) {
                try {
                    const filePath = path.join(STORIES_DIR, file);
                    const stats = await fs.stat(filePath);
                    const content = await fs.readFile(filePath, 'utf8');
                    const stories = JSON.parse(content);
                    
                    const fileId = path.basename(file, '.json');
                    storyFiles.push({
                        filename: file,
                        id: fileId,
                        title: STORY_TITLES[fileId] || fileId,
                        count: stories.length,
                        lastModified: stats.mtime.toISOString(),
                        preview: stories[0]?.title || ''
                    });
                } catch (e) {
                    console.error(`Error reading ${file}:`, e.message);
                }
            }
            
            storyFiles.sort((a, b) => {
                const idxA = STORY_ORDER.indexOf(a.id);
                const idxB = STORY_ORDER.indexOf(b.id);
                return (idxA === -1 ? 999 : idxA) - (idxB === -1 ? 999 : idxB);
            });
            return sendJSON(res, { success: true, stories: storyFiles });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }
    
    // GET /stories/:filename - Belirli dosyayı getir
    if (pathname.startsWith('/stories/') && req.method === 'GET') {
        const parts = pathname.split('/');
        if (parts.length === 3) {
            const filename = parts[2];
            if (!filename.endsWith('.json')) {
                filename += '.json';
            }
            
            try {
                const filePath = path.join(STORIES_DIR, filename);
                if (!require('fs').existsSync(filePath)) {
                    return sendJSON(res, { error: 'File not found' }, 404);
                }
                
                const content = await fs.readFile(filePath, 'utf8');
                const stories = JSON.parse(content);
                
                return sendJSON(res, { 
                    success: true, 
                    filename,
                    stories 
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    // POST /stories/:filename - Yeni story ekle
    if (pathname.startsWith('/stories/') && req.method === 'POST') {
        const parts = pathname.split('/');
        if (parts.length === 3) {
            const filename = parts[2];
            if (!filename.endsWith('.json')) {
                filename += '.json';
            }
            
            try {
                const body = await parseBody(req);
                const { title, content, keyPoints, order } = body;
                
                if (!title || !content) {
                    return sendJSON(res, { error: 'Title and content are required' }, 400);
                }
                
                const filePath = path.join(STORIES_DIR, filename);
                let stories = [];
                
                if (require('fs').existsSync(filePath)) {
                    const existingContent = await fs.readFile(filePath, 'utf8');
                    stories = JSON.parse(existingContent);
                }
                
                const newStory = {
                    title: title.trim(),
                    content: content.trim(),
                    keyPoints: Array.isArray(keyPoints) ? keyPoints : [],
                    order: order || stories.length
                };
                
                stories.push(newStory);
                stories.sort((a, b) => a.order - b.order);
                
                await fs.writeFile(filePath, JSON.stringify(stories, null, 2), 'utf8');
                
                return sendJSON(res, { 
                    success: true, 
                    message: 'Story added',
                    totalStories: stories.length,
                    story: newStory
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    // POST /stories/:filename/save - Tüm hikayeleri kaydet (full array replace)
    if (pathname.startsWith('/stories/') && pathname.endsWith('/save') && req.method === 'POST') {
        const parts = pathname.split('/');
        if (parts.length === 4) {
            let filename = parts[2];
            
            try {
                const body = await parseBody(req);
                const { stories } = body;
                
                if (!Array.isArray(stories)) {
                    return sendJSON(res, { error: 'Stories must be an array' }, 400);
                }
                
                // Validate each story
                for (let i = 0; i < stories.length; i++) {
                    const story = stories[i];
                    if (!story.title || !story.content) {
                        return sendJSON(res, { error: `Item ${i}: title and content required` }, 400);
                    }
                    if (!story.order) story.order = i;
                }
                
                stories.sort((a, b) => a.order - b.order);
                
                const filePath = path.join(STORIES_DIR, filename);
                await fs.writeFile(filePath, JSON.stringify(stories, null, 2), 'utf8');
                
                return sendJSON(res, { 
                    success: true, 
                    message: 'All stories saved',
                    count: stories.length
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    // PUT /stories/:filename/:index - Story güncelle
    if (pathname.startsWith('/stories/') && req.method === 'PUT') {
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
                const filePath = path.join(STORIES_DIR, filename);
                if (!require('fs').existsSync(filePath)) {
                    return sendJSON(res, { error: 'File not found' }, 404);
                }
                
                const content = await fs.readFile(filePath, 'utf8');
                const stories = JSON.parse(content);
                
                if (index >= stories.length) {
                    return sendJSON(res, { error: 'Index out of range' }, 400);
                }
                
                const body = await parseBody(req);
                const { title, content: storyContent, keyPoints, order } = body;
                
                stories[index] = {
                    title: title?.trim() || stories[index].title,
                    content: storyContent?.trim() || stories[index].content,
                    keyPoints: Array.isArray(keyPoints) ? keyPoints : stories[index].keyPoints,
                    order: order !== undefined ? order : stories[index].order
                };
                
                stories.sort((a, b) => a.order - b.order);
                await fs.writeFile(filePath, JSON.stringify(stories, null, 2), 'utf8');
                
                return sendJSON(res, { 
                    success: true, 
                    message: 'Story updated',
                    story: stories[index]
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    // DELETE /stories/:filename/:index - Story sil
    if (pathname.startsWith('/stories/') && req.method === 'DELETE') {
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
                const filePath = path.join(STORIES_DIR, filename);
                if (!require('fs').existsSync(filePath)) {
                    return sendJSON(res, { error: 'File not found' }, 404);
                }
                
                const content = await fs.readFile(filePath, 'utf8');
                const stories = JSON.parse(content);
                
                if (index >= stories.length) {
                    return sendJSON(res, { error: 'Index out of range' }, 400);
                }
                
                const deletedStory = stories.splice(index, 1)[0];
                stories.sort((a, b) => a.order - b.order);
                
                await fs.writeFile(filePath, JSON.stringify(stories, null, 2), 'utf8');
                
                return sendJSON(res, { 
                    success: true, 
                    message: 'Story deleted',
                    deletedStory,
                    remainingStories: stories.length
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }
    
    return false; // Route handled
}

module.exports = handleStoryRoutes;
