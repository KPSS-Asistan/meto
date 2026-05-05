const { sendJSON } = require('../utils/helper');
const { exec } = require('child_process');
const path = require('path');

const ROOT_DIR = path.resolve(__dirname, '../../');

function runGit(args) {
    return new Promise((resolve, reject) => {
        exec(`git ${args}`, { cwd: ROOT_DIR, timeout: 30000 }, (err, stdout, stderr) => {
            if (err) reject(new Error(stderr || err.message));
            else resolve(stdout.trim());
        });
    });
}

async function handleSyncRoutes(req, res, pathname) {
    // Return mock success for any old sync endpoints hit by cached frontend
    if (pathname.startsWith('/auto-sync/')) {
        return sendJSON(res, { success: true, message: 'Sync is disabled.', disabled: true });
    }

    // POST /api/git-push  — commit + push değişiklikleri
    if (pathname === '/api/git-push' && req.method === 'POST') {
        try {
            // Staged değişiklik var mı?
            const status = await runGit('status --porcelain');
            if (!status) {
                return sendJSON(res, { success: true, message: 'Değişiklik yok, push atlandı.' });
            }

            const branch = (await runGit('rev-parse --abbrev-ref HEAD')).trim();
            const timestamp = new Date().toLocaleString('tr-TR', { timeZone: 'Europe/Istanbul' });

            await runGit('add assets/data/questions');
            await runGit(`commit -m "data: soru güncellemesi ${timestamp}"`);
            await runGit(`push origin ${branch}`);

            return sendJSON(res, { success: true, message: `Push başarılı → ${branch}` });
        } catch (e) {
            console.error('[git-push]', e.message);
            return sendJSON(res, { success: false, error: e.message }, 500);
        }
    }

    return false;
}

module.exports = { handleSyncRoutes };
