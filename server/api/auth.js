/**
 * Admin Authentication API
 * Simple token-based auth for admin panel access
 */
const crypto = require('crypto');
const { sendJSON, parseBody } = require('../utils/helper');

// Token TTL: 1 gün (ms)
const TOKEN_TTL = 24 * 60 * 60 * 1000;
const COOKIE_NAME = 'kpss_session';

// Token store: Map<token, { expiresAt: number, role: string }>
const validTokens = new Map();

const ADMIN_USERNAME = process.env.ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'kpss2024admin';

// Hardcode editor hesapları
const EDITOR_USERS = [
    { username: 'musami',  password: '12345' },
    { username: 'psksena', password: '12345' },
];

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

            // Tüm kullanıcıları tek listede topla
            const allUsers = [
                { username: ADMIN_USERNAME, password: ADMIN_PASSWORD, role: 'admin' },
                ...EDITOR_USERS.map(u => ({ ...u, role: 'editor' }))
            ];

            let matchedRole = null;
            for (const user of allUsers) {
                if (safeCompare(username, user.username) && safeCompare(password, user.password)) {
                    matchedRole = user.role;
                    break;
                }
            }

            if (!matchedRole) {
                return sendJSON(res, { error: 'Geçersiz kullanıcı adı veya şifre' }, 401);
            }

            // Generate secure random token with 1-day expiry
            const token = crypto.randomBytes(32).toString('hex');
            validTokens.set(token, { expiresAt: Date.now() + TOKEN_TTL, role: matchedRole });

            console.log(`✅ Login: ${username} (${matchedRole})`);
            res.setHeader('Set-Cookie', makeSessionCookie(token));
            return sendJSON(res, { success: true, token, role: matchedRole });

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
