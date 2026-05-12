function setupNavigation() {
    document.querySelectorAll('.nav-tab').forEach(link => {
        link.addEventListener('click', (e) => {
            const pageId = link.getAttribute('data-page');
            if (pageId) {
                e.preventDefault();
                window.showPage(pageId);
            }
        });
    });
}

async function initApp() {
    console.log('KPSS Dashboard Initializing...');

    if (window.loadStats) await window.loadStats();

    if (window.checkGitStatus) window.checkGitStatus();
    if (window.checkAutoSyncStatus) window.checkAutoSyncStatus();

    setupNavigation();
}

// initApp auth doğrulandıktan sonra index.html'den çağrılır
window.initApp = initApp;

// ═══════════════════════════════════════════════════════════════════════════
// QUALITY CHECK MODULE
// ═══════════════════════════════════════════════════════════════════════════

