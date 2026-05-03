/**
 * KPSS Dashboard Server v2.0 - Full Integration
 */
const http = require('http');
const { PORT, ENV_FILE } = require('./config');
require('dotenv').config({ path: ENV_FILE });

// API Route Handlers
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
