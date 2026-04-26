/**
 * Update Config API Routes
 * app_update.json yönetimi (zorunlu güncelleme kontrolü)
 */
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { ROOT_DIR } = require('../config');
const { sendJSON, parseBody } = require('../utils/helper');

const getUpdateFile = () => path.join(ROOT_DIR, 'app_update.json');

async function handleUpdateRoutes(req, res, pathname) {
    // GET /api/update/current-version
    if (pathname === '/api/update/current-version' && req.method === 'GET') {
        try {
            const pubspecPath = path.join(ROOT_DIR, 'pubspec.yaml');
            if (!fs.existsSync(pubspecPath)) {
                return sendJSON(res, { error: 'pubspec.yaml bulunamadı' }, 404);
            }
            const content = fs.readFileSync(pubspecPath, 'utf8');
            const versionMatch = content.match(/^version:\s*([\d\.]+)/m);
            if (versionMatch && versionMatch[1]) {
                return sendJSON(res, { success: true, version: versionMatch[1] });
            }
            return sendJSON(res, { error: 'Versiyon bulunamadı' }, 404);
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // GET /api/update/config
    if (pathname === '/api/update/config' && req.method === 'GET') {
        try {
            const filePath = getUpdateFile();

            if (!fs.existsSync(filePath)) {
                return sendJSON(res, {
                    success: false,
                    error: 'app_update.json bulunamadı',
                    config: null
                }, 404);
            }

            const content = fs.readFileSync(filePath, 'utf8');
            const config = JSON.parse(content);

            return sendJSON(res, { success: true, config });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /api/update/config
    if (pathname === '/api/update/config' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { android, ios } = body;

            if (!android && !ios) {
                return sendJSON(res, { error: 'En az bir platform verisi gerekli (android/ios)' }, 400);
            }

            // Validate fields
            const validatePlatform = (data, name) => {
                if (!data) return;
                const errors = [];
                if (!data.min_version || !/^\d+\.\d+\.\d+$/.test(data.min_version)) {
                    errors.push(`${name}: min_version geçersiz (x.y.z formatında olmalı)`);
                }
                if (!data.latest_version || !/^\d+\.\d+\.\d+$/.test(data.latest_version)) {
                    errors.push(`${name}: latest_version geçersiz (x.y.z formatında olmalı)`);
                }
                if (typeof data.force_update !== 'boolean') {
                    errors.push(`${name}: force_update boolean olmalı`);
                }
                return errors;
            };

            const errors = [
                ...(validatePlatform(android, 'Android') || []),
                ...(validatePlatform(ios, 'iOS') || [])
            ];

            if (errors.length > 0) {
                return sendJSON(res, { error: errors.join(', ') }, 400);
            }

            const filePath = getUpdateFile();

            // Read existing or create new
            let existing = {};
            if (fs.existsSync(filePath)) {
                try {
                    existing = JSON.parse(fs.readFileSync(filePath, 'utf8'));
                } catch { }
            }

            // Build new config
            const newConfig = {
                last_updated: new Date().toISOString().split('T')[0],
                android: android || existing.android || {
                    min_version: '1.0.0',
                    latest_version: '1.0.0',
                    force_update: false,
                    update_message: '',
                    store_url: ''
                },
                ios: ios || existing.ios || {
                    min_version: '1.0.0',
                    latest_version: '1.0.0',
                    force_update: false,
                    update_message: '',
                    store_url: ''
                }
            };

            // Write to file
            fs.writeFileSync(filePath, JSON.stringify(newConfig, null, 4), 'utf8');
            console.log('✅ app_update.json güncellendi');

            // Git commit & push
            let gitResult = { pushed: false, message: '' };
            try {
                execSync('git add app_update.json', { cwd: ROOT_DIR, stdio: 'pipe' });
                const commitMsg = `🔄 Güncelleme yapılandırması değiştirildi (${new Date().toLocaleDateString('tr-TR')})`;
                execSync(`git commit -m "${commitMsg}"`, { cwd: ROOT_DIR, stdio: 'pipe' });

                try {
                    execSync('git pull --rebase origin main', { cwd: ROOT_DIR, stdio: 'pipe' });
                } catch { }

                execSync('git push origin main', { cwd: ROOT_DIR, stdio: 'pipe' });
                gitResult = { pushed: true, message: 'GitHub\'a başarıyla gönderildi' };
                console.log('🚀 app_update.json GitHub\'a push edildi');
            } catch (gitErr) {
                if (gitErr.message.includes('nothing to commit')) {
                    gitResult = { pushed: true, message: 'Değişiklik yok, commit atlandı' };
                } else {
                    gitResult = { pushed: false, message: gitErr.message };
                    console.log('⚠️ Git push hatası:', gitErr.message);
                }
            }

            return sendJSON(res, {
                success: true,
                config: newConfig,
                git: gitResult
            });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    return false;
}

module.exports = handleUpdateRoutes;
