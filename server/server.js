/**
 * KPSS Dashboard Server v2.0 - Full Integration
 */
const http = require('http');
const fs = require('fs');
const path = require('path');
const { PORT, ENV_FILE } = require('./config');
require('dotenv').config({ path: ENV_FILE });

const CLIENT_DIR = path.join(__dirname, '..', 'client');

function serveStatic(res, filePath) {
    const ext = path.extname(filePath).toLowerCase();
    const mime = {
        '.html': 'text/html',
        '.js': 'application/javascript',
        '.css': 'text/css',
        '.json': 'application/json',
        '.png': 'image/png',
        '.ico': 'image/x-icon',
        '.svg': 'image/svg+xml'
    };
    const contentType = mime[ext] || 'text/plain';
    try {
        const data = fs.readFileSync(filePath);
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(data);
    } catch {
        res.writeHead(404);
        res.end('Not Found');
    }
}

// API Route Handlers
const { handleAuthRoutes, verifyToken } = require('./api/auth');
const handleQuestionRoutes = require('./api/questions');
const handleReportRoutes = require('./api/reports');
const handleFeedbackRoutes = require('./api/feedback');
const handleDashboardRoutes = require('./api/dashboard');
const handleUserRoutes = require('./api/users');
const { handleSyncRoutes } = require('./api/sync');
const handleAIRoutes = require('./api/ai');
// AI Content Routes - DEBUG
let handleAIContentRoutes, startNightlyScheduler;
try {
    const aiContent = require('./api/ai-content');
    handleAIContentRoutes = aiContent;
    startNightlyScheduler = aiContent.startNightlyScheduler;
    console.log('✅ ai-content modülü yüklendi');
} catch (e) {
    console.log('❌ ai-content modülü yüklenemedi:', e.message);
    console.log(e.stack);
    process.exit(1);
}
const handleNotificationRoutes = require('./api/notifications');
const handleUpdateRoutes = require('./api/update');
const handleQualityCheckRoutes = require('./api/quality-check');

// New Module Handlers
const handleFlashcardRoutes = require('./api/flashcards');
const handleStoryRoutes = require('./api/stories');
const handleExplanationRoutes = require('./api/explanations');
const handleMatchingGamesRoutes = require('./api/matching_games');
const handleGlossaryRoutes = require('./api/glossary');
const handleEditorRoutes = require('./api/editor');

const server = http.createServer(async (req, res) => {
    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, DELETE, PATCH');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Title');

    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }

    try {
        const urlObj = new URL(req.url, `http://${req.headers.host}`);
        const pathname = urlObj.pathname;
        const searchParams = urlObj.searchParams;

        // === Auth Routes (public - no token required) ===
        if (await handleAuthRoutes(req, res, pathname)) return;

        // === Auth Guard: protect all /api/* and other API routes ===
        const isApiRoute = pathname.startsWith('/api/') ||
            pathname.startsWith('/users') ||
            pathname.startsWith('/topics') ||
            pathname.startsWith('/questions') ||
            pathname.startsWith('/reports') ||
            pathname.startsWith('/feedback') ||
            pathname.startsWith('/stats') ||
            pathname.startsWith('/activities') ||
            pathname.startsWith('/generate') ||
            pathname.startsWith('/analyze') ||
            pathname.startsWith('/ai') ||
            pathname.startsWith('/notifications') ||
            pathname.startsWith('/update') ||
            pathname.startsWith('/quality') ||
            pathname.startsWith('/sync') ||
            pathname.startsWith('/flashcards') ||
            pathname.startsWith('/stories') ||
            pathname.startsWith('/explanations') ||
            pathname.startsWith('/matching-games') ||
            pathname.startsWith('/glossary') ||
            pathname.startsWith('/editor');

        // RevenueCat webhook ve dev-reload auth'dan muaf
        const isPublicRoute = pathname === '/webhooks/revenuecat' || pathname === '/dev-reload';

        const tokenInfo = isApiRoute && !isPublicRoute ? verifyToken(req) : null;

        if (isApiRoute && !isPublicRoute && !tokenInfo) {
            res.writeHead(401, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: 'Yetkisiz erişim. Lütfen giriş yapın.' }));
            return;
        }

        // Editör rolü yalnızca /editor/* ve /auth/* erişebilir
        if (tokenInfo && tokenInfo.role === 'editor' &&
            !pathname.startsWith('/editor') && !pathname.startsWith('/auth')) {
            res.writeHead(403, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: 'Bu işlem için yetkiniz yok.' }));
            return;
        }

        // === API Route Handlers (Modular) ===

        // Editor API (review queue)
        if (await handleEditorRoutes(req, res, pathname, searchParams)) return;

        // Questions API (CRUD, topics, browse)
        if (await handleQuestionRoutes(req, res, pathname, searchParams)) return;

        // New Module APIs
        if (await handleFlashcardRoutes(req, res, pathname, searchParams)) return;
        if (await handleStoryRoutes(req, res, pathname, searchParams)) return;
        if (await handleExplanationRoutes(req, res, pathname, searchParams)) return;
        if (await handleMatchingGamesRoutes(req, res, pathname, searchParams)) return;
        if (await handleGlossaryRoutes(req, res, pathname, searchParams)) return;

        // Reports API
        if (await handleReportRoutes(req, res, pathname)) return;

        // Feedback API
        if (await handleFeedbackRoutes(req, res, pathname)) return;

        // Dashboard API (stats, activities)
        if (await handleDashboardRoutes(req, res, pathname, searchParams)) return;

        // Users API
        if (await handleUserRoutes(req, res, pathname)) return;

        // Sync API (local-only)
        if (await handleSyncRoutes(req, res, pathname)) return;

        // AI API (generate, analyze)
        if (await handleAIRoutes(req, res, pathname)) return;

        // Dev Reload SSE
        if (pathname === '/dev-reload') {
            res.writeHead(200, {
                'Content-Type': 'text/event-stream',
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive'
            });
            res.write('data: connected\n\n');
            return;
        }

        // AI Content API (30 bölüm explanations, stories, flashcards)
        if (await handleAIContentRoutes(req, res, pathname, searchParams)) return;

        // Notifications API
        if (await handleNotificationRoutes(req, res, pathname)) return;

        // Update Config API
        if (await handleUpdateRoutes(req, res, pathname)) return;

        // Quality Check API
        if (await handleQualityCheckRoutes(req, res, pathname, searchParams)) return;

        // === Static file serving (client) ===
        if (req.method === 'GET') {
            let filePath;
            if (pathname === '/' || pathname === '/index.html') {
                filePath = path.join(CLIENT_DIR, 'index.html');
            } else {
                filePath = path.join(CLIENT_DIR, pathname);
            }
            // Güvenlik: CLIENT_DIR dışına çıkılmasın
            if (filePath.startsWith(CLIENT_DIR) && fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
                return serveStatic(res, filePath);
            }
        }

        // === End of API routes ===
        res.writeHead(404);
        res.end('Not Found');

    } catch (e) {
        console.error('Server error:', e);
        res.writeHead(500);
        res.end('Internal Server Error: ' + e.message);
    }
});

server.listen(PORT, () => {
    console.log(`
╔═══════════════════════════════════════════════════════════════════════════╗
║  🎯 KPSS Dashboard Server v2.0 - Full Integration                         ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  🌐 http://localhost:${PORT}                                                ║
║                                                                           ║
║  📦 Modüler API Yapısı:                                                   ║
║     ✓ Questions API  (/topics, /questions, /add, /find-question)          ║
║     ✓ Dashboard API  (/stats, /activities)                                ║
║     ✓ Reports API    (/reports)                                           ║
║     ✓ Feedback API   (/feedback)                                          ║
║     ✓ Users API      (/users)                                             ║
║     ✓ Sync API       (local)                                ║
║     ✓ AI API         (/generate-ai, /analyze-ai, /ai-review)              ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
    `);

    if (startNightlyScheduler) startNightlyScheduler();
});
