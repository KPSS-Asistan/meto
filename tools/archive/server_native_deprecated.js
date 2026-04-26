/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                                                                           ║
 * ║  ⚠️  DEPRECATED - BU DOSYA ARTIK KULLANILMIYOR                             ║
 * ║                                                                           ║
 * ║  Bu dosya 30 Aralık 2024 tarihinde deprecated edilmiştir.                 ║
 * ║                                                                           ║
 * ║  YENİ SUNUCU: question_server.js                                          ║
 * ║  Çalıştırmak için: node question_server.js                                ║
 * ║                                                                           ║
 * ║  Bu dosya sadece referans amaçlı saklanmıştır.                            ║
 * ║  Lütfen question_server.js kullanın.                                      ║
 * ║                                                                           ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */

console.error('⛔ UYARI: Bu sunucu deprecated edilmiştir!');
console.error('📌 Lütfen "node question_server.js" komutunu kullanın.');
console.error('');
process.exit(1);

// ═══════════════════════════════════════════════════════════════════════════
// AŞAĞISI ESKİ KOD - SADECE REFERANS İÇİN
// ═══════════════════════════════════════════════════════════════════════════

const http = require('http');
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const fs = require('fs');
const path = require('path');
const url = require('url');
const { exec } = require('child_process');
const { TOPICS, LESSON_TARGETS } = require('./topics');


const PORT = 3456;
const PUBLIC_DIR = path.join(__dirname, 'public');
const QUESTIONS_DIR = path.join(__dirname, '../questions');

const MIME_TYPES = {
    '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css',
    '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpg'
};

const server = http.createServer(async (req, res) => {
    // CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, DELETE, PUT, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }

    const parseBody = (cb) => {
        let body = '';
        req.on('data', c => { body += c.toString(); });
        req.on('end', () => { try { cb(JSON.parse(body)); } catch { cb({}); } });
    };

    const parsedUrl = url.parse(req.url, true);
    let pathname = parsedUrl.pathname;

    const json = (data, code = 200) => {
        res.writeHead(code, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(data));
    };
    const error = (msg, code = 500) => json({ error: msg }, code);

    // FAVICON
    if (pathname === '/favicon.ico') {
        res.writeHead(204);
        res.end();
        return;
    }

    // CORE ENDPOINTS
    if (pathname === '/topics' && req.method === 'GET') {
        const list = Object.entries(TOPICS).map(([id, t]) => {
            const fp = path.join(QUESTIONS_DIR, `${id}.json`);
            let c = 0;
            if (fs.existsSync(fp)) try { c = JSON.parse(fs.readFileSync(fp)).length } catch { }
            return { id, ...t, count: c };
        }); json(list); return;
    }
    if (pathname.startsWith('/questions/') && req.method === 'GET') {
        const parts = pathname.split('/');
        const fp = path.join(QUESTIONS_DIR, `${parts[2]}.json`);
        if (fs.existsSync(fp)) fs.createReadStream(fp).pipe(res); else json([]); return;
    }
    if (pathname === '/stats' && req.method === 'GET') {
        let total = 0, missing = 0, byLesson = {};
        let recentFiles = [];
        Object.entries(TOPICS).forEach(([id, t]) => {
            const fp = path.join(QUESTIONS_DIR, `${id}.json`);
            let count = 0;
            if (fs.existsSync(fp)) {
                try {
                    const stats = fs.statSync(fp);
                    const q = JSON.parse(fs.readFileSync(fp));
                    count = q.length;
                    q.forEach(x => { if (!x.e || x.e.length < 5) missing++; });
                    recentFiles.push({ name: t.name, lesson: t.lesson, time: stats.mtime });
                } catch { }
            }
            total += count; if (!byLesson[t.lesson]) byLesson[t.lesson] = { count: 0, target: (LESSON_TARGETS[t.lesson]?.target || 500) };
            byLesson[t.lesson].count += count;
        });

        recentFiles.sort((a, b) => new Date(b.time) - new Date(a.time));

        json({
            totalQuestions: total,
            totalTopics: Object.keys(TOPICS).length,
            missingExplanations: missing,
            byLesson,
            recentActivity: recentFiles.slice(0, 5)
        }); return;
    }
    if (pathname === '/add' && req.method === 'POST') {
        parseBody(({ topicId, questions }) => {
            if (!topicId || !questions) return error('Missing data', 400);
            const fp = path.join(QUESTIONS_DIR, `${topicId}.json`);
            let curr = [];
            if (fs.existsSync(fp)) try { curr = JSON.parse(fs.readFileSync(fp)); } catch { }
            curr = [...curr, ...questions.map(q => ({ ...q, id: q.id || `q_${Date.now()}_${Math.random().toString(36).substr(2, 4)}` }))];
            fs.writeFileSync(fp, JSON.stringify(curr, null, 2));
            json({ success: true, count: curr.length });
        }); return;
    }
    if (pathname.startsWith('/questions/') && req.method === 'DELETE') {
        const [, , tid, qid] = pathname.split('/');
        const fp = path.join(QUESTIONS_DIR, `${tid}.json`);
        if (!fs.existsSync(fp)) return error('Topic not found', 404);
        try { let cols = JSON.parse(fs.readFileSync(fp)); const newCols = cols.filter(q => q.id !== qid); fs.writeFileSync(fp, JSON.stringify(newCols, null, 2)); json({ success: true }); } catch (e) { error(e.message); } return;
    }

    // UPDATE QUESTION
    if (pathname.startsWith('/questions/') && req.method === 'PUT') {
        const [, , tid, qid] = pathname.split('/');
        const fp = path.join(QUESTIONS_DIR, `${tid}.json`);
        if (!fs.existsSync(fp)) return error('Topic not found', 404);

        parseBody((updatedData) => {
            try {
                let questions = JSON.parse(fs.readFileSync(fp));
                const idx = questions.findIndex(q => q.id === qid);
                if (idx === -1) return error('Question not found', 404);

                // Merge updated fields while preserving others
                questions[idx] = { ...questions[idx], ...updatedData, id: qid };
                fs.writeFileSync(fp, JSON.stringify(questions, null, 2));
                json({ success: true, question: questions[idx] });
            } catch (e) {
                error(e.message);
            }
        });
        return;
    }

    // ══════════════════════════════════════════════════════════════════
    // AI SORU SİHİRBAZI
    // ══════════════════════════════════════════════════════════════════
    if (pathname === '/ai/generate' && req.method === 'POST') {
        parseBody(async ({ topic }) => {
            if (!topic) return error('Konu belirtilmedi', 400);

            try {
                // Check for Gemini API key
                const apiKey = process.env.GEMINI_API_KEY || '';
                if (!apiKey) {
                }

                const prompt = `Sen bir KPSS uzmanısın. "${topic}" konusunda Türkçe bir çoktan seçmeli soru hazırla.

Kurallar:
- Soru KPSS formatında olmalı
- 5 şık olmalı (A, B, C, D, E)
- Tek doğru cevap olmalı
- Kısa ve net bir açıklama ekle

JSON formatında cevap ver:
{
  "q": "Soru metni",
  "o": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı", "E şıkkı"],
  "a": 0,
  "e": "Açıklama"
}

Sadece JSON döndür, başka bir şey yazma.`;

                const response = await fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=' + apiKey, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        contents: [{ parts: [{ text: prompt }] }],
                        generationConfig: { temperature: 0.8 }
                    })
                });

                const data = await response.json();
                const text = data.candidates?.[0]?.content?.parts?.[0]?.text || '';

                // Extract JSON from response
                const jsonMatch = text.match(/\{[\s\S]*\}/);
                if (jsonMatch) {
                    const generated = JSON.parse(jsonMatch[0]);
                    json({ success: true, question: generated });
                } else {
                    json({ success: false, error: 'AI geçersiz yanıt döndü' });
                }
            } catch (e) {
                json({ success: false, error: e.message });
            }
        }); return;
    }

    // ══════════════════════════════════════════════════════════════════
    // AI SORU ANALİZİ (OpenRouter)
    // ══════════════════════════════════════════════════════════════════
    if (pathname === '/ai/analyze' && req.method === 'POST') {
        parseBody(async ({ questions }) => {
            if (!questions || !Array.isArray(questions) || questions.length === 0) {
                return error('Analiz edilecek soru bulunamadı', 400);
            }

            try {
                const apiKey = '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' || '';
                if (!apiKey) {
                }

                const prompt = `Sen bir KPSS soru bankası editörüsün. Aşağıdaki soruları analiz et ve her biri için detaylı geri bildirim ver.

KONTROL EDİLECEKLER:
1. Doğru cevap gerçekten doğru mu? (Bilgi doğruluğu)
2. Yanlış şıklar mantıklı mı? (Çeldirici kalitesi)
3. Soru metni açık ve anlaşılır mı?
4. Dilbilgisi ve yazım hataları var mı?
5. KPSS formatına uygun mu?
6. Zorluk seviyesi uygun mu?

SORULAR:
${JSON.stringify(questions, null, 2)}

CEVAP FORMATI (JSON dizisi olarak):
[
  {
    "index": 0,
    "status": "ok" | "warning" | "error",
    "score": 1-10,
    "issues": ["Sorun 1", "Sorun 2"],
    "suggestions": ["Öneri 1", "Öneri 2"],
    "correctAnswerCheck": "Doğru cevap hakkında değerlendirme",
    "summary": "Genel değerlendirme"
  }
]

Sadece JSON dizisi döndür, başka bir şey yazma.`;

                const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${apiKey}`,
                        'HTTP-Referer': 'http://localhost:3456',
                        'X-Title': 'KPSS Soru Analizi'
                    },
                    body: JSON.stringify({
                        model: 'google/gemini-2.0-flash-001',
                        messages: [
                            { role: 'system', content: 'Sen bir KPSS uzmanı ve soru bankası editörüsün. Türkçe cevap ver.' },
                            { role: 'user', content: prompt }
                        ],
                        temperature: 0.3
                    })
                });

                const data = await response.json();

                if (data.error) {
                    return json({ success: false, error: data.error.message || 'OpenRouter API hatası' });
                }

                const text = data.choices?.[0]?.message?.content || '';

                // Extract JSON from response
                const jsonMatch = text.match(/\[[\s\S]*\]/);
                if (jsonMatch) {
                    const analysis = JSON.parse(jsonMatch[0]);
                    json({ success: true, analysis });
                } else {
                    // Try to parse as is
                    try {
                        const analysis = JSON.parse(text);
                        json({ success: true, analysis: Array.isArray(analysis) ? analysis : [analysis] });
                    } catch {
                        json({ success: false, error: 'AI geçersiz yanıt döndü', raw: text });
                    }
                }
            } catch (e) {
                json({ success: false, error: e.message });
            }
        }); return;
    }

    // ══════════════════════════════════════════════════════════════════
    // DATA SYNC LOGIC
    // ══════════════════════════════════════════════════════════════════
    const execGit = (cmd) => new Promise((resolve) => {
        exec(cmd, { cwd: path.join(__dirname, '..') }, (err, stdout, stderr) => {
            if (err) resolve({ success: false, error: stderr || err.message });
            else resolve({ success: true, output: stdout.trim() });
        });
    });

    if (pathname === '/git/status' && req.method === 'GET') {
        const br = await execGit('git branch --show-current');
        // Sadece veri klasörlerindeki değişiklikleri kontrol et
        const st = await execGit('git status -s questions flashcards stories explanations matching_games version.json');
        const rem = await execGit('git remote get-url origin');
        json({
            branch: br.output || 'main',
            remote: rem.output || 'Tanımsız',
            changes: st.output ? st.output.split('\n') : []
        }); return;
    }

    if (pathname === '/git/set-remote' && req.method === 'POST') {
        parseBody(async ({ url }) => {
            if (!url) return error('URL gerekli', 400);
            let res = await execGit(`git remote set-url origin ${url}`);
            if (!res.success) res = await execGit(`git remote add origin ${url}`);
            if (res.success) json({ success: true }); else error(res.error);
        }); return;
    }

    if (pathname === '/git/pull' && req.method === 'POST') {
        // Smart Merge Logic
        const res = await execGit('git pull origin main --no-rebase --autostash --allow-unrelated-histories');
        json(res);
        return;
    }

    if (pathname === '/git/commit' && req.method === 'POST') {
        parseBody(async ({ message }) => {
            if (!message) return error('Message required', 400);

            // SADECE veri klasörlerini ve version.json'u ekle
            const targets = 'questions flashcards stories explanations matching_games version.json README.md .gitignore';
            await execGit(`git add ${targets}`);

            const check = await execGit('git diff --cached --name-only');
            if (!check.output) return error('Senkronizasyon yapılacak veri değişikliği yok.', 400);

            // SADECE hedeflenen dosyaları commit et
            const res = await execGit(`git commit -m "Data Update: ${message}" -- ${targets}`);
            json(res);
        }); return;
    }

    if (pathname === '/git/push' && req.method === 'POST') {
        json(await execGit('git push origin main'));
        return;
    }

    if (pathname === '/git/abort' && req.method === 'POST') {
        await execGit('git rebase --abort');
        await execGit('git merge --abort');
        await execGit('git clean -fd');
        json({ success: true, message: 'Git resetlendi.' });
        return;
    }

    if (pathname === '/search' && req.method === 'GET') {
        const qStr = (parsedUrl.query.q || '').toLowerCase();
        let results = [], count = 0;
        if (qStr.length >= 3) {
            for (const [id, t] of Object.entries(TOPICS)) {
                if (count > 50) break;
                const fp = path.join(QUESTIONS_DIR, `${id}.json`);
                if (fs.existsSync(fp)) { try { const qs = JSON.parse(fs.readFileSync(fp)); qs.forEach(q => { if (count > 50) return; if ((q.q || '').toLowerCase().includes(qStr)) { results.push({ ...q, topicId: id, topicName: t.name }); count++; } }); } catch { } }
            }
        } json({ results }); return;
    }

    if (pathname === '/') pathname = '/index.html';
    const ext = path.extname(pathname);
    const safe = path.normalize(pathname).replace(/^(\.\.[\/\\])+/, '');
    const fp = path.join(PUBLIC_DIR, safe);
    fs.readFile(fp, (err, data) => { if (err) { res.writeHead(404); res.end('404'); } else { res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'text/plain' }); res.end(data); } });
});

server.listen(PORT, () => console.log(`🚀 Native Data Server running on ${PORT}`));
