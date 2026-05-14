/**
 * Admin Authentication API
 * Simple token-based auth for admin panel access
 * Editor hesapları Firestore'da saklanır (editor_accounts koleksiyonu)
 */
const crypto = require('crypto');
const { sendJSON, parseBody } = require('../utils/helper');
const { db: firebaseDb } = require('../firebase-admin');
const db = firebaseDb;

// Token TTL: 1 gün (ms)
const TOKEN_TTL = 24 * 60 * 60 * 1000;
const COOKIE_NAME = 'kpss_session';

// Token store: Map<token, { expiresAt: number, role: string }>
const validTokens = new Map();

const ADMIN_USERNAME = process.env.ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'kpss2024admin';

// İlk kurulumda migrate edilecek seed hesaplar
const SEED_EDITORS = [
    { username: 'musami',  password: '12345' },
    { username: 'psksena', password: '12345' },
];

// ─── Şifre Hash ───
const HASH_SALT = process.env.HASH_SALT || 'kpss_editor_salt_2024';
function hashPassword(plain) {
    return crypto.createHash('sha256').update(plain + HASH_SALT).digest('hex');
}

// ─── Editor Cache (5 dakika) ───
let _editorCache = [];
let _editorCacheTime = 0;
const EDITOR_CACHE_TTL = 5 * 60 * 1000;

async function getEditors(forceRefresh = false) {
    const now = Date.now();
    if (!forceRefresh && now - _editorCacheTime < EDITOR_CACHE_TTL && _editorCache.length > 0) {
        return _editorCache;
    }
    if (!db) return _editorCache;
    try {
        const snap = await db.collection('editor_accounts').get();
        _editorCache = snap.docs.map(d => ({ username: d.id, ...d.data() }));
        _editorCacheTime = now;
        return _editorCache;
    } catch (e) {
        console.error('[auth] Editor yükleme hatası:', e.message);
        return _editorCache;
    }
}

/** Seed'leri (ilk çalıştırma) Firestore'a yaz */
async function migrateEditors() {
    if (!db) return;
    try {
        const snap = await db.collection('editor_accounts').limit(1).get();
        if (!snap.empty) return; // Zaten migrate edilmiş
        for (const u of SEED_EDITORS) {
            await db.collection('editor_accounts').doc(u.username).set({
                passwordHash: hashPassword(u.password),
                createdAt: new Date().toISOString(),
                active: true
            });
        }
        console.log('✅ Editör hesapları Firestore\'a taşındı');
        _editorCacheTime = 0; // Cache'i sıfırla
    } catch (e) {
        console.error('[auth] Migrate hatası:', e.message);
    }
}
// Sunucu başlarken migrate et
migrateEditors();

// Süresi dolmuş tokenları periyodik temizle (her saat)
setInterval(() => {
    const now = Date.now();
    for (const [token, entry] of validTokens) {
        if (now > entry.expiresAt) validTokens.delete(token);
    }
}, 60 * 60 * 1000);

/** Farklı uzunluktaki string'leri timing-safe karşılaştırır */
function safeCompare(a, b) {
    if (typeof a !== 'string' || typeof b !== 'string') return false;
    const maxLen = Math.max(Buffer.byteLength(a, 'utf8'), Buffer.byteLength(b, 'utf8'));
    const aBuf = Buffer.alloc(maxLen);
    const bBuf = Buffer.alloc(maxLen);
    Buffer.from(a, 'utf8').copy(aBuf);
    Buffer.from(b, 'utf8').copy(bBuf);
    return crypto.timingSafeEqual(aBuf, bBuf) && a.length === b.length;
}

/** Cookie header'ından token'ı parse et */
function getTokenFromCookie(req) {
    const cookieHeader = req.headers['cookie'];
    if (!cookieHeader) return null;
    const match = cookieHeader.split(';').map(c => c.trim()).find(c => c.startsWith(COOKIE_NAME + '='));
    return match ? match.slice(COOKIE_NAME.length + 1) : null;
}

/**
 * Verify a token from the Authorization header or session cookie.
 * Returns { token, role } if valid, false otherwise.
 */
function verifyToken(req) {
    const now = Date.now();

    // 1. Authorization header
    const authHeader = req.headers['authorization'];
    if (authHeader && authHeader.startsWith('Bearer ')) {
        const token = authHeader.slice(7);
        const entry = validTokens.get(token);
        if (entry && now < entry.expiresAt) return { token, role: entry.role };
        if (entry) validTokens.delete(token); // süresi dolmuş
    }

    // 2. Cookie
    const cookieToken = getTokenFromCookie(req);
    if (cookieToken) {
        const entry = validTokens.get(cookieToken);
        if (entry && now < entry.expiresAt) return { token: cookieToken, role: entry.role };
        if (entry) validTokens.delete(cookieToken);
    }

    return false;
}

/** Set-Cookie header'ı üret */
function makeSessionCookie(token) {
    const maxAge = Math.floor(TOKEN_TTL / 1000); // saniye
    return `${COOKIE_NAME}=${token}; HttpOnly; SameSite=Strict; Path=/; Max-Age=${maxAge}`;
}

/** Cookie'yi silen header */
function clearSessionCookie() {
    return `${COOKIE_NAME}=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0`;
}

async function handleAuthRoutes(req, res, pathname) {
    // POST /auth/login
    if (pathname === '/auth/login' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { username, password } = body;

            if (!username || !password) {
                return sendJSON(res, { error: 'Kullanıcı adı ve şifre gerekli' }, 400);
            }

            // Admin kontrolü (plaintext, .env'den)
            if (safeCompare(username, ADMIN_USERNAME) && safeCompare(password, ADMIN_PASSWORD)) {
                const token = crypto.randomBytes(32).toString('hex');
                validTokens.set(token, { expiresAt: Date.now() + TOKEN_TTL, role: 'admin' });
                console.log(`✅ Login: ${username} (admin)`);
                res.setHeader('Set-Cookie', makeSessionCookie(token));
                return sendJSON(res, { success: true, token, role: 'admin' });
            }

            // Editör kontrolü (Firestore'dan, hash karşılaştırma)
            const editors = await getEditors();
            const inputHash = hashPassword(password);
            const editor = editors.find(e =>
                safeCompare(username, e.username) &&
                safeCompare(inputHash, e.passwordHash) &&
                e.active !== false
            );

            if (editor) {
                const token = crypto.randomBytes(32).toString('hex');
                validTokens.set(token, { expiresAt: Date.now() + TOKEN_TTL, role: 'editor' });
                console.log(`✅ Login: ${username} (editor)`);
                res.setHeader('Set-Cookie', makeSessionCookie(token));
                return sendJSON(res, { success: true, token, role: 'editor' });
            }

            return sendJSON(res, { error: 'Geçersiz kullanıcı adı veya şifre' }, 401);

        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ─── Editör Yönetimi (sadece admin) ───

    // GET /auth/editors — listeyi getir
    if (pathname === '/auth/editors' && req.method === 'GET') {
        const auth = verifyToken(req);
        if (!auth || auth.role !== 'admin') return sendJSON(res, { error: 'Unauthorized' }, 401);
        const editors = await getEditors();
        return sendJSON(res, {
            success: true,
            editors: editors.map(e => ({ username: e.username, active: e.active !== false, createdAt: e.createdAt }))
        });
    }

    // POST /auth/editors — yeni editör ekle
    if (pathname === '/auth/editors' && req.method === 'POST') {
        const auth = verifyToken(req);
        if (!auth || auth.role !== 'admin') return sendJSON(res, { error: 'Unauthorized' }, 401);
        try {
            const { username, password } = await parseBody(req);
            if (!username || !password) return sendJSON(res, { error: 'username ve password zorunlu' }, 400);
            if (!/^[a-z0-9_]{3,30}$/i.test(username)) return sendJSON(res, { error: 'Geçersiz kullanıcı adı (3-30 karakter, harf/rakam/_)' }, 400);
            if (password.length < 6) return sendJSON(res, { error: 'Şifre en az 6 karakter olmalı' }, 400);
            if (!db) return sendJSON(res, { error: 'Firestore bağlantısı yok' }, 500);
            await db.collection('editor_accounts').doc(username).set({
                passwordHash: hashPassword(password),
                createdAt: new Date().toISOString(),
                active: true
            });
            _editorCacheTime = 0; // Cache'i geçersiz kıl
            console.log(`✅ Yeni editör oluşturuldu: ${username}`);
            return sendJSON(res, { success: true, username });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // PUT /auth/editors/:username — şifre veya aktiflik güncelle
    if (pathname.startsWith('/auth/editors/') && req.method === 'PUT') {
        const auth = verifyToken(req);
        if (!auth || auth.role !== 'admin') return sendJSON(res, { error: 'Unauthorized' }, 401);
        const username = decodeURIComponent(pathname.slice('/auth/editors/'.length));
        if (!username) return sendJSON(res, { error: 'username gerekli' }, 400);
        try {
            const body = await parseBody(req);
            const update = {};
            if (body.password) {
                if (body.password.length < 6) return sendJSON(res, { error: 'Şifre en az 6 karakter olmalı' }, 400);
                update.passwordHash = hashPassword(body.password);
            }
            if (typeof body.active === 'boolean') update.active = body.active;
            if (!Object.keys(update).length) return sendJSON(res, { error: 'Güncellenecek alan yok' }, 400);
            if (!db) return sendJSON(res, { error: 'Firestore bağlantısı yok' }, 500);
            await db.collection('editor_accounts').doc(username).update(update);
            _editorCacheTime = 0;
            return sendJSON(res, { success: true });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // DELETE /auth/editors/:username — editörü sil
    if (pathname.startsWith('/auth/editors/') && req.method === 'DELETE') {
        const auth = verifyToken(req);
        if (!auth || auth.role !== 'admin') return sendJSON(res, { error: 'Unauthorized' }, 401);
        const username = decodeURIComponent(pathname.slice('/auth/editors/'.length));
        if (!username) return sendJSON(res, { error: 'username gerekli' }, 400);
        if (!db) return sendJSON(res, { error: 'Firestore bağlantısı yok' }, 500);
        try {
            await db.collection('editor_accounts').doc(username).delete();
            _editorCacheTime = 0;
            return sendJSON(res, { success: true });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /auth/logout
    if (pathname === '/auth/logout' && req.method === 'POST') {
        const authHeader = req.headers['authorization'];
        if (authHeader && authHeader.startsWith('Bearer ')) {
            validTokens.delete(authHeader.slice(7));
        }
        const cookieToken = getTokenFromCookie(req);
        if (cookieToken) validTokens.delete(cookieToken);
        res.setHeader('Set-Cookie', clearSessionCookie());
        return sendJSON(res, { success: true });
    }

    // GET /auth/verify
    if (pathname === '/auth/verify' && req.method === 'GET') {
        const result = verifyToken(req);
        if (result) {
            const { token, role } = result;
            // Cookie süresini yenile
            res.setHeader('Set-Cookie', makeSessionCookie(token));
            validTokens.set(token, { expiresAt: Date.now() + TOKEN_TTL, role });
            return sendJSON(res, { success: true, authenticated: true, token, role });
        }
        return sendJSON(res, { authenticated: false }, 401);
    }

    return false;
}

module.exports = { handleAuthRoutes, verifyToken };
