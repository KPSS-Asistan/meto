/**
 * quality-check.js — Soru JSON kalite kontrol API
 * GET  /api/quality-check?source=local&topic=<id>
 * POST /api/quality-check/fix  — local prefix'leri temizle
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const ROOT_DIR = path.join(__dirname, '..', '..', '..', '..');
const ASSETS_DIR = path.join(ROOT_DIR, 'assets', 'data', 'questions');

const OPTION_PREFIX_RE = /^[A-Ea-e][).–\-]\s*/;

// ─── Helpers ─────────────────────────────────────────────────────────────────

function getLocalTopicIds() {
    if (!fs.existsSync(ASSETS_DIR)) return [];
    return fs.readdirSync(ASSETS_DIR)
        .filter(f => f.endsWith('.json'))
        .map(f => path.basename(f, '.json'));
}

// ─── Checker ─────────────────────────────────────────────────────────────────

function checkTopic(topicId, jsonString) {
    let data;
    try { data = JSON.parse(jsonString); }
    catch (e) { return { topicId, parseError: e.message, issues: [], questionCount: 0 }; }

    if (!Array.isArray(data)) return { topicId, parseError: 'JSON array değil', issues: [], questionCount: 0 };

    const issues = [];
    const seenIds = new Set();

    data.forEach((q, idx) => {
        if (!q.id) issues.push({ severity: 'warn', idx, msg: 'id eksik' });
        if (!q.q) issues.push({ severity: 'error', idx, msg: 'q (soru metni) eksik' });
        if (!q.o) issues.push({ severity: 'error', idx, msg: 'o (şıklar) eksik' });
        if (q.a === undefined || q.a === null) issues.push({ severity: 'error', idx, msg: 'a (cevap index) eksik' });

        if (q.id) {
            if (seenIds.has(q.id)) issues.push({ severity: 'error', idx, msg: `Yinelenen ID: ${q.id}` });
            seenIds.add(q.id);
        }

        if (q.q && q.q.includes('\uFFFD'))
            issues.push({ severity: 'error', idx, msg: `Soru encoding bozuk: ${q.q.substring(0, 60)}` });

        if (q.o && Array.isArray(q.o)) {
            if (q.o.length !== 5)
                issues.push({ severity: q.o.length < 5 ? 'error' : 'warn', idx, msg: `Şık sayısı ${q.o.length} (5 olmalı)` });

            q.o.forEach((opt, i) => {
                const s = String(opt);
                if (s.includes('\uFFFD'))
                    issues.push({ severity: 'error', idx, msg: `Şık[${i}] encoding bozuk: ${s.substring(0, 50)}` });
                if (OPTION_PREFIX_RE.test(s))
                    issues.push({ severity: 'warn', idx, msg: `Şık[${i}] prefix: "${s.substring(0, 50)}"` });
            });
        }

        if (q.a !== undefined && q.o && Array.isArray(q.o)) {
            if (typeof q.a !== 'number' || q.a < 0 || q.a >= q.o.length)
                issues.push({ severity: 'error', idx, msg: `Geçersiz cevap index: a=${q.a}` });
        }
    });

    return {
        topicId,
        questionCount: data.length,
        issues,
        errorCount: issues.filter(i => i.severity === 'error').length,
        warnCount: issues.filter(i => i.severity === 'warn').length,
    };
}

// ─── Fix: prefix temizle ─────────────────────────────────────────────────────

function fixLocalPrefixes(topicId) {
    const filePath = path.join(ASSETS_DIR, `${topicId}.json`);
    if (!fs.existsSync(filePath)) return { fixed: 0, removed: 0, error: 'Dosya bulunamadı' };

    let data;
    try {
        const buf = fs.readFileSync(filePath);
        // BOM (UTF-8 Byte Order Mark) temizle
        const hasBOM = buf[0] === 0xEF && buf[1] === 0xBB && buf[2] === 0xBF;
        const text = hasBOM ? buf.slice(3).toString('utf8') : buf.toString('utf8');
        data = JSON.parse(text);
    }
    catch (e) { return { fixed: 0, removed: 0, error: e.message }; }

    let fixed = 0;
    data.forEach(q => {
        if (q.o && Array.isArray(q.o)) {
            q.o = q.o.map(opt => {
                const s = String(opt);
                const stripped = s.replace(OPTION_PREFIX_RE, '').trim();
                if (stripped !== s) fixed++;
                return stripped;
            });
        }
    });

    const before = data.length;
    const cleaned = data.filter(q => q.id || q.q || q.o);
    const removed = before - cleaned.length;

    fs.writeFileSync(filePath, JSON.stringify(cleaned, null, 2), 'utf8');
    return { fixed, removed };
}

// ─── Fix: encoding bozuk soruları sil ───────────────────────────────────────

function removeEncodingBroken(topicId) {
    const filePath = path.join(ASSETS_DIR, `${topicId}.json`);
    if (!fs.existsSync(filePath)) return { removed: 0, remaining: 0, error: 'Dosya bulunamadı' };

    let data;
    try {
        const buf = fs.readFileSync(filePath);
        const hasBOM = buf[0] === 0xEF && buf[1] === 0xBB && buf[2] === 0xBF;
        const text = hasBOM ? buf.slice(3).toString('utf8') : buf.toString('utf8');
        data = JSON.parse(text);
    }
    catch (e) { return { removed: 0, remaining: 0, error: e.message }; }

    const isBad = q => {
        // Boş / eksik zorunlu alan
        if (!q.q || !q.o || q.a === undefined || q.a === null) return true;
        // Encoding bozuk (\uFFFD replacement character)
        if (q.q.includes('\uFFFD')) return true;
        if (Array.isArray(q.o) && q.o.some(o => String(o).includes('\uFFFD'))) return true;
        return false;
    };

    const before = data.length;
    const cleaned = data.filter(q => !isBad(q));
    const removed = before - cleaned.length;

    fs.writeFileSync(filePath, JSON.stringify(cleaned, null, 2), 'utf8');
    return { removed, remaining: cleaned.length };
}

// ─── Bulk: tümünü düzelt (prefix + boş obje) ────────────────────────────────

async function bulkFix(topicIds, onProgress) {
    const results = [];
    for (let i = 0; i < topicIds.length; i++) {
        const r = fixLocalPrefixes(topicIds[i]);
        results.push({ topicId: topicIds[i], ...r });
        if (onProgress) onProgress(i + 1, topicIds.length);
    }
    return results;
}

// ─── Bulk: tümünde bozukları sil ────────────────────────────────────────────

async function bulkRemoveBroken(topicIds, onProgress) {
    const results = [];
    for (let i = 0; i < topicIds.length; i++) {
        const r = removeEncodingBroken(topicIds[i]);
        if (r.removed > 0) results.push({ topicId: topicIds[i], ...r });
        if (onProgress) onProgress(i + 1, topicIds.length);
    }
    return results;
}

// ─── Route Handler ───────────────────────────────────────────────────────────

module.exports = async function handleQualityCheckRoutes(req, res, pathname, searchParams) {
    // GET /api/quality-check
    if (req.method === 'GET' && pathname === '/api/quality-check') {
        const topicId = searchParams.get('topic') || null;

        const topicIds = topicId ? [topicId] : getLocalTopicIds();
        const results = [];
        let totalQuestions = 0;

        for (const tid of topicIds) {
            let jsonString;
            try {
                const fp = path.join(ASSETS_DIR, `${tid}.json`);
                if (!fs.existsSync(fp)) continue;
                jsonString = fs.readFileSync(fp, 'utf8');
            } catch (e) {
                results.push({ topicId: tid, fetchError: e.message, issues: [], questionCount: 0, errorCount: 1, warnCount: 0 });
                continue;
            }

            const result = checkTopic(tid, jsonString);
            totalQuestions += result.questionCount;
            results.push(result);
        }

        const summary = {
            totalTopics: results.length,
            totalQuestions,
            cleanTopics: results.filter(r => r.errorCount === 0 && r.warnCount === 0).length,
            totalErrors: results.reduce((s, r) => s + (r.errorCount || 0), 0),
            totalWarns: results.reduce((s, r) => s + (r.warnCount || 0), 0),
        };

        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ summary, results }));
        return true;
    }

    // POST /api/quality-check/fix  (tek topic veya toplu)
    if (req.method === 'POST' && pathname === '/api/quality-check/fix') {
        let body = '';
        req.on('data', c => body += c);
        await new Promise(r => req.on('end', r));

        let topicIds, bulk = false;
        try {
            const parsed = JSON.parse(body);
            bulk = parsed.bulk === true;
            topicIds = parsed.topicIds || (bulk ? getLocalTopicIds() : []);
        } catch { topicIds = getLocalTopicIds(); bulk = true; }

        if (bulk) {
            // SSE streaming — her topic işlenince progress gönder
            res.writeHead(200, {
                'Content-Type': 'text/event-stream; charset=utf-8',
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive',
            });
            let totalFixed = 0;
            const details = [];
            for (let i = 0; i < topicIds.length; i++) {
                const r = fixLocalPrefixes(topicIds[i]);
                if (r.fixed > 0 || r.removed > 0) {
                    details.push({ topicId: topicIds[i], ...r });
                    totalFixed += r.fixed || 0;
                }
                res.write(`data: ${JSON.stringify({ done: i + 1, total: topicIds.length, topicId: topicIds[i], fixed: r.fixed || 0 })}\n\n`);
            }
            res.write(`data: ${JSON.stringify({ finished: true, totalFixed, details })}\n\n`);
            res.end();
        } else {
            // Tek topic — normal JSON
            const fixResults = [];
            for (const tid of topicIds) {
                const r = fixLocalPrefixes(tid);
                if (r.fixed > 0 || r.removed > 0) fixResults.push({ topicId: tid, ...r });
            }
            res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
            res.end(JSON.stringify({ fixed: fixResults, totalFixed: fixResults.reduce((s, r) => s + (r.fixed || 0), 0) }));
        }
        return true;
    }

    // POST /api/quality-check/remove-broken  (tek topic veya toplu)
    if (req.method === 'POST' && pathname === '/api/quality-check/remove-broken') {
        let body = '';
        req.on('data', c => body += c);
        await new Promise(r => req.on('end', r));

        let topicIds, bulk = false;
        try {
            const parsed = JSON.parse(body);
            bulk = parsed.bulk === true;
            topicIds = parsed.topicIds || (bulk ? getLocalTopicIds() : []);
        } catch { topicIds = getLocalTopicIds(); bulk = true; }

        if (bulk) {
            res.writeHead(200, {
                'Content-Type': 'text/event-stream; charset=utf-8',
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive',
            });
            let totalRemoved = 0;
            const details = [];
            for (let i = 0; i < topicIds.length; i++) {
                const r = removeEncodingBroken(topicIds[i]);
                if (r.removed > 0) {
                    details.push({ topicId: topicIds[i], ...r });
                    totalRemoved += r.removed;
                }
                res.write(`data: ${JSON.stringify({ done: i + 1, total: topicIds.length, topicId: topicIds[i], removed: r.removed || 0 })}\n\n`);
            }
            res.write(`data: ${JSON.stringify({ finished: true, totalRemoved, details })}\n\n`);
            res.end();
        } else {
            const removeResults = [];
            let totalRemoved = 0;
            for (const tid of topicIds) {
                const r = removeEncodingBroken(tid);
                if (r.removed > 0) { removeResults.push({ topicId: tid, ...r }); totalRemoved += r.removed; }
            }
            res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
            res.end(JSON.stringify({ removed: removeResults, totalRemoved }));
        }
        return true;
    }



    return false;
};
