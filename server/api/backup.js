/**
 * Backup API
 * GET  /api/backup/history  — son 30 commit listesi
 * GET  /api/backup/tags     — mevcut yedek etiketleri
 * POST /api/backup/create   — yeni yedek noktası oluştur (git tag)
 * GET  /api/backup/download — assets/ klasörünü zip olarak indir (git archive)
 */

const { exec } = require('child_process');
const path = require('path');
const { sendJSON } = require('../utils/helper');

const ROOT_DIR = path.resolve(__dirname, '../../');

function runGit(args, timeoutMs = 15000) {
    return new Promise((resolve, reject) => {
        exec(`git ${args}`, { cwd: ROOT_DIR, timeout: timeoutMs }, (err, stdout, stderr) => {
            if (err) reject(new Error(stderr || err.message));
            else resolve(stdout.trim());
        });
    });
}

async function handleBackupRoutes(req, res, pathname) {

    // GET /api/backup/history — son 30 commit
    if (pathname === '/api/backup/history' && req.method === 'GET') {
        try {
            const raw = await runGit(
                'log --oneline -30 --format="%H|%s|%ai|%an" -- assets/'
            );
            const commits = raw
                .split('\n')
                .filter(Boolean)
                .map(line => {
                    const [hash, subject, date, author] = line.split('|');
                    return { hash: (hash || '').substring(0, 8), subject, date, author };
                });
            return sendJSON(res, { success: true, commits });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // GET /api/backup/tags — yedek etiketleri
    if (pathname === '/api/backup/tags' && req.method === 'GET') {
        try {
            const raw = await runGit('tag -l "yedek/*" --sort=-creatordate');
            const tags = raw.split('\n').filter(Boolean).map(tag => {
                const name = tag.replace('yedek/', '');
                return { tag, name };
            });
            return sendJSON(res, { success: true, tags });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /api/backup/create — yeni yedek noktası
    if (pathname === '/api/backup/create' && req.method === 'POST') {
        try {
            let body = {};
            try {
                const chunks = [];
                for await (const chunk of req) chunks.push(chunk);
                body = JSON.parse(Buffer.concat(chunks).toString()) || {};
            } catch { }

            const label = (body.label || '').replace(/[^a-zA-Z0-9ğüşıöçĞÜŞİÖÇ _-]/g, '').trim().substring(0, 50);
            const ts = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19);
            const tagName = `yedek/${ts}${label ? '-' + label.replace(/\s+/g, '_') : ''}`;

            await runGit(`tag "${tagName}"`);
            await runGit(`push origin "${tagName}"`).catch(() => {}); // push başarısız olursa sessiz geç

            return sendJSON(res, { success: true, tag: tagName, message: `Yedek oluşturuldu: ${tagName}` });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // GET /api/backup/download — assets/ zip olarak indir
    if (pathname === '/api/backup/download' && req.method === 'GET') {
        try {
            const { exec: execCb } = require('child_process');
            res.setHeader('Content-Type', 'application/zip');
            res.setHeader('Content-Disposition', `attachment; filename="assets-yedek-${new Date().toISOString().substring(0, 10)}.zip"`);

            const proc = require('child_process').spawn(
                'git', ['archive', '--format=zip', 'HEAD', 'assets/'],
                { cwd: ROOT_DIR }
            );

            proc.stdout.pipe(res);
            proc.stderr.on('data', d => console.error('[backup/download]', d.toString()));
            proc.on('error', e => {
                console.error('[backup/download] spawn error:', e.message);
                if (!res.headersSent) res.writeHead(500);
                res.end();
            });
            return true;
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    return false;
}

module.exports = handleBackupRoutes;
