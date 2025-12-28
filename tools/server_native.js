const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');
const { exec } = require('child_process');
const { TOPICS } = require('./topics');

const PORT = 3456;
const PUBLIC_DIR = path.join(__dirname, 'public');
const QUESTIONS_DIR = path.join(__dirname, '../assets/data/questions');

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
        Object.entries(TOPICS).forEach(([id, t]) => {
            const fp = path.join(QUESTIONS_DIR, `${id}.json`);
            let count = 0;
            if (fs.existsSync(fp)) { try { const q = JSON.parse(fs.readFileSync(fp)); count = q.length; q.forEach(x => { if (!x.e || x.e.length < 5) missing++; }); } catch { } }
            total += count; if (!byLesson[t.lesson]) byLesson[t.lesson] = { count: 0 }; byLesson[t.lesson].count += count;
        }); json({ totalQuestions: total, totalTopics: Object.keys(TOPICS).length, missingExplanations: missing, byLesson }); return;
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

    // ══════════════════════════════════════════════════════════════════
    // GIT INTEGRATION v9.5 (Unrelated Histories)
    // ══════════════════════════════════════════════════════════════════
    const execGit = (cmd) => new Promise((resolve) => {
        exec(cmd, { cwd: path.join(__dirname, '..') }, (err, stdout, stderr) => {
            if (err) resolve({ success: false, error: stderr || err.message });
            else resolve({ success: true, output: stdout.trim() });
        });
    });

    if (pathname === '/git/status' && req.method === 'GET') {
        const br = await execGit('git branch --show-current');
        const st = await execGit('git status -s assets/data/questions');
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
        // v9.5: --allow-unrelated-histories
        // En zorlu birleştirme senaryosu için tam yetki
        const res = await execGit('git pull origin main --no-rebase --autostash --allow-unrelated-histories');
        json(res);
        return;
    }

    if (pathname === '/git/commit' && req.method === 'POST') {
        parseBody(async ({ message }) => {
            if (!message) return error('Message required', 400);
            await execGit('git add assets/data/questions');
            const check = await execGit('git diff --cached --name-only');
            if (!check.output) return error('Değişiklik yok, commit iptal.', 400);
            const res = await execGit(`git commit -m "Data Update: ${message}"`);
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

server.listen(PORT, () => console.log(`🚀 v9.5 Native Server (Unrelated Histories) running on ${PORT}`));
