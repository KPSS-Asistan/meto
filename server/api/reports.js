const fs = require('fs').promises;
const fsSync = require('fs');
const { REPORTS_FILE } = require('../config');
const { sendJSON, parseBody } = require('../utils/helper');
const { db } = require('../firebase-admin');

async function handleReportRoutes(req, res, pathname) {
    // GET /reports — Firestore + file merge
    if (pathname === '/reports' && req.method === 'GET') {
        try {
            const items = [];
            const seen = new Set();

            // 1) Firestore'dan oku (primary)
            if (db) {
                try {
                    const snap = await db.collection('reports')
                        .orderBy('createdAt', 'desc')
                        .limit(200)
                        .get();
                    snap.forEach(doc => {
                        const d = doc.data();
                        const createdAt = d.createdAt && d.createdAt.toDate
                            ? d.createdAt.toDate().toISOString()
                            : (d.createdAt || new Date().toISOString());
                        const key = `${d.userId || ''}|${d.questionId || ''}|${createdAt}`;
                        if (seen.has(key)) return;
                        seen.add(key);
                        items.push({ id: doc.id, ...d, createdAt, source: 'firestore' });
                    });
                } catch (e) {
                    console.error('Firestore reports fetch error:', e.message);
                }
            }

            // 2) Dosyadan oku (backup)
            if (fsSync.existsSync(REPORTS_FILE)) {
                const content = await fs.readFile(REPORTS_FILE, 'utf8');
                const fileItems = JSON.parse(content);
                for (const r of fileItems) {
                    const key = `${r.userId || ''}|${r.questionId || ''}|${r.createdAt || ''}`;
                    if (seen.has(key)) continue;
                    seen.add(key);
                    items.push({ ...r, source: r.source || 'file' });
                }
            }

            items.sort((a, b) => new Date(b.createdAt || b.receivedAt || 0) - new Date(a.createdAt || a.receivedAt || 0));
            return sendJSON(res, items);
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /report
    if (pathname === '/report' && req.method === 'POST') {
        try {
            const report = await parseBody(req);
            let reports = [];
            if (fsSync.existsSync(REPORTS_FILE)) {
                reports = JSON.parse(await fs.readFile(REPORTS_FILE, 'utf8'));
            }
            reports.unshift({ ...report, receivedAt: new Date().toISOString() });
            reports = reports.slice(0, 100);
            await fs.writeFile(REPORTS_FILE, JSON.stringify(reports, null, 2), 'utf8');
            return sendJSON(res, { success: true });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    return false;
}

module.exports = handleReportRoutes;
