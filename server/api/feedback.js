const fs = require('fs').promises;
const fsSync = require('fs');
const { FEEDBACK_FILE } = require('../config');
const { sendJSON, parseBody } = require('../utils/helper');
const { db } = require('../firebase-admin');

async function handleFeedbackRoutes(req, res, pathname) {
    // GET /feedbacks — Firestore + file merge
    if (pathname === '/feedbacks' && req.method === 'GET') {
        try {
            const items = [];
            const seen = new Set();

            // 1) Firestore'dan oku (primary)
            if (db) {
                try {
                    const snap = await db.collection('feedbacks')
                        .orderBy('createdAt', 'desc')
                        .limit(200)
                        .get();
                    snap.forEach(doc => {
                        const d = doc.data();
                        const createdAt = d.createdAt && d.createdAt.toDate
                            ? d.createdAt.toDate().toISOString()
                            : (d.createdAt || new Date().toISOString());
                        const key = `${d.userId || ''}|${d.message || ''}|${createdAt}`;
                        if (seen.has(key)) return;
                        seen.add(key);
                        items.push({ id: doc.id, ...d, createdAt, source: 'firestore' });
                    });
                } catch (e) {
                    console.error('Firestore feedbacks fetch error:', e.message);
                }
            }

            // 2) Dosyadan oku (backup)
            if (fsSync.existsSync(FEEDBACK_FILE)) {
                const content = await fs.readFile(FEEDBACK_FILE, 'utf8');
                const fileItems = JSON.parse(content);
                for (const f of fileItems) {
                    const key = `${f.userId || ''}|${f.message || ''}|${f.createdAt || ''}`;
                    if (seen.has(key)) continue;
                    seen.add(key);
                    items.push({ ...f, source: f.source || 'file' });
                }
            }

            items.sort((a, b) => new Date(b.createdAt || b.receivedAt || 0) - new Date(a.createdAt || a.receivedAt || 0));
            return sendJSON(res, items);
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /feedback
    if (pathname === '/feedback' && req.method === 'POST') {
        try {
            const feedback = await parseBody(req);
            let feedbacks = [];
            if (fsSync.existsSync(FEEDBACK_FILE)) {
                feedbacks = JSON.parse(await fs.readFile(FEEDBACK_FILE, 'utf8'));
            }
            feedbacks.unshift({ ...feedback, receivedAt: new Date().toISOString() });
            feedbacks = feedbacks.slice(0, 100);
            await fs.writeFile(FEEDBACK_FILE, JSON.stringify(feedbacks, null, 2), 'utf8');
            return sendJSON(res, { success: true });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    return false;
}

module.exports = handleFeedbackRoutes;
