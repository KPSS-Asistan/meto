const { sendJSON } = require('../utils/helper');
const { exec } = require('child_process');
const path = require('path');

const ROOT_DIR = path.resolve(__dirname, '../../');

function runGit(args, timeoutMs = 60000) {
    return new Promise((resolve, reject) => {
        exec(`git ${args}`, { cwd: ROOT_DIR, timeout: timeoutMs }, (err, stdout, stderr) => {
            if (err) reject(new Error(stderr || err.message));
            else resolve(stdout.trim());
        });
    });
}

/**
 * assets/ klasörünü git'e commit'ler ve 3 hedefe push'lar:
 *   1. origin/{currentBranch}
 *   2. meto/main
 *   3. mobile/sync/assets-update  (sadece assets/ alt ağacı)
 *
 * @param {string} label  - commit mesajına eklenen etiket (ör. "soru", "flashcard")
 * @returns {Promise<{committed: boolean, results: object}>}
 */
async function pushAllRemotes(label = 'içerik') {
    const timestamp = new Date().toLocaleString('tr-TR', { timeZone: 'Europe/Istanbul' });
    const results = {};

    // 1. Değişiklik var mı?
    const status = await runGit('status --porcelain -- assets/');
    const committed = !!status;

    if (committed) {
        await runGit('add assets/');
        await runGit(`commit -m "data: ${label} güncellemesi ${timestamp}"`);
    }

    const branch = await runGit('rev-parse --abbrev-ref HEAD');

    // 2. origin push
    try {
        await runGit(`push origin ${branch}`);
        results.origin = 'ok';
    } catch (e) {
        results.origin = `hata: ${e.message}`;
        console.error('[git-push] origin:', e.message);
    }

    // 3. meto/main push
    try {
        await runGit(`push meto ${branch}:main`);
        results.meto = 'ok';
    } catch (e) {
        results.meto = `hata: ${e.message}`;
        console.error('[git-push] meto:', e.message);
    }

    // 4. mobile assets subtree push (assets/ → sync/assets-update)
    try {
        const splitHash = await runGit('subtree split --prefix=assets HEAD', 90000);
        await runGit(`push mobile ${splitHash}:refs/heads/sync/assets-update --force`);
        results.mobile = 'ok';
    } catch (e) {
        results.mobile = `hata: ${e.message}`;
        console.error('[git-push] mobile:', e.message);
    }

    return { committed, results };
}

async function handleSyncRoutes(req, res, pathname) {
    // Return mock success for any old sync endpoints hit by cached frontend
    if (pathname.startsWith('/auto-sync/')) {
        return sendJSON(res, { success: true, message: 'Sync is disabled.', disabled: true });
    }

    // POST /api/git-push  — commit + push (tüm remote'lar)
    if (pathname === '/api/git-push' && req.method === 'POST') {
        try {
            const status = await runGit('status --porcelain -- assets/');
            if (!status) {
                return sendJSON(res, { success: true, message: 'Değişiklik yok, push atlandı.' });
            }

            const { committed, results } = await pushAllRemotes('manuel güncelleme');
            const allOk = Object.values(results).every(v => v === 'ok');

            return sendJSON(res, {
                success: allOk,
                committed,
                results,
                message: allOk
                    ? 'Tüm remote\'lara push başarılı'
                    : `Kısmi push: ${JSON.stringify(results)}`
            });
        } catch (e) {
            console.error('[git-push]', e.message);
            return sendJSON(res, { success: false, error: e.message }, 500);
        }
    }

    return false;
}

module.exports = { handleSyncRoutes, pushAllRemotes };
