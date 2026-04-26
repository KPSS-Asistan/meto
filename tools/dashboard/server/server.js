/**
 * KPSS Dashboard Server v2.0 - Full Integration
 * Eski question_server tüm özelliklerini modüler yapıda barındırır
 */
require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });

const http = require('http');
const fs = require('fs');
const path = require('path');
const { PORT, PUBLIC_DIR } = require('./config');

// API Route Handlers
const handleQuestionRoutes = require('./api/questions');
const handleReportRoutes = require('./api/reports');
const handleFeedbackRoutes = require('./api/feedback');
const handleDashboardRoutes = require('./api/dashboard');
const handleUserRoutes = require('./api/users');
const { handleSyncRoutes, startAutoSyncScheduler } = require('./api/sync');
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

const MIME_TYPES = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'text/javascript; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.ico': 'image/x-icon',
    '.svg': 'image/svg+xml',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2'
};

const server = http.createServer(async (req, res) => {
    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, DELETE');
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

        // === API Route Handlers (Modular) ===

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

        // Git/Sync API (auto-sync, publish to github)
        if (await handleSyncRoutes(req, res, pathname)) return;

        // AI API (generate, analyze)
        if (await handleAIRoutes(req, res, pathname)) return;

        // AI Content API (30 bölüm explanations, stories, flashcards)
        if (await handleAIContentRoutes(req, res, pathname, searchParams)) return;

        // Notifications API
        if (await handleNotificationRoutes(req, res, pathname)) return;

        // Update Config API
        if (await handleUpdateRoutes(req, res, pathname)) return;

        // Quality Check API
        if (await handleQualityCheckRoutes(req, res, pathname, searchParams)) return;

        // === Static Files ===
        let staticPath = pathname === '/' ? '/index.html' : pathname;
        let filePath = path.join(PUBLIC_DIR, staticPath);

        // Security check
        if (!filePath.startsWith(PUBLIC_DIR)) {
            res.writeHead(403);
            res.end('Forbidden');
            return;
        }

        if (fs.existsSync(filePath)) {
            if (fs.statSync(filePath).isDirectory()) {
                filePath = path.join(filePath, 'index.html');
            }

            if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
                const ext = path.extname(filePath).toLowerCase();
                const mime = MIME_TYPES[ext] || 'application/octet-stream';
                res.writeHead(200, { 'Content-Type': mime });
                fs.createReadStream(filePath).pipe(res);
                return;
            }
        }

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
║     ✓ Sync API       (/auto-sync/*, /publish-to-github, /git/*)           ║
║     ✓ AI API         (/generate-ai, /analyze-ai, /ai-review)              ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
    `);

    // Auto-sync scheduler başlat
    startAutoSyncScheduler();
    if (startNightlyScheduler) startNightlyScheduler();
});
