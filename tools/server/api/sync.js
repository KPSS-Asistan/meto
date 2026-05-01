const { sendJSON } = require('../utils/helper');

async function handleSyncRoutes(req, res, pathname) {
    // Return mock success for any old sync endpoints hit by cached frontend
    if (pathname.startsWith('/auto-sync/')) {
        return sendJSON(res, { success: true, message: 'Sync is disabled. Local disk is the ultimate source of truth.', disabled: true });
    }
    return false;
}

module.exports = { handleSyncRoutes };
