/* === modules\sync.js === */

/**
 * KPSS Dashboard - Sync Module
 * Contains logic for Auto-Sync (Local-FS).
 */

// Ensure API URL is available
if (typeof API === 'undefined') {
    window.API = window.API_URL || 'http://localhost:3456';
}

// ══════════════════════════════════════════════════════════════════════════
// 1. AUTO-SYNC (Node.js Server Backend)
// ══════════════════════════════════════════════════════════════════════════

window.checkAutoSyncStatus = async function () {
    try {
        const res = await fetch(API + '/auto-sync/status');
        const data = await res.json();

        const indicator = document.getElementById('autoSyncIndicator');
        const icon = document.getElementById('autoSyncIcon');
        const text = document.getElementById('autoSyncText');

        if (!indicator || !icon || !text) return;

        if (data.enabled) {
            indicator.style.background = 'rgba(34, 197, 94, 0.1)';
            indicator.style.borderColor = 'rgba(34, 197, 94, 0.3)';
            icon.style.color = '#22c55e';
            icon.innerText = 'sync';
            text.style.color = '#22c55e';
            text.innerText = 'Auto-Sync';
            indicator.title = `Otomatik Sync AKTİF\nSon: ${data.lastSync}\nSonraki: ${data.nextSync}`;
        } else {
            indicator.style.background = 'rgba(239, 68, 68, 0.1)';
            indicator.style.borderColor = 'rgba(239, 68, 68, 0.3)';
            icon.style.color = '#ef4444';
            icon.innerText = 'sync_disabled';
            text.style.color = '#ef4444';
            text.innerText = 'Sync OFF';
            indicator.title = 'Otomatik Sync DEVRE DIŞI - Tıklayarak aktifleştir';
        }
    } catch (e) {
        console.log('Auto-sync status check failed:', e.message);
    }
};

window.toggleAutoSync = async function () {
    try {
        const res = await fetch(API + '/auto-sync/toggle', { method: 'POST' });
        const data = await res.json();

        if (data.success) {
            showToast(data.message, 'success');
            await checkAutoSyncStatus();
        } else {
            showToast('Auto-sync toggle hatası', 'error');
        }
    } catch (e) {
        showToast('Bağlantı hatası', 'error');
    }
};

window.triggerManualSync = async function () {
    showToast('Manuel sync başlatılıyor...', 'info');
    try {
        const res = await fetch(API + '/auto-sync/now', { method: 'POST' });
        const data = await res.json();

        if (data.success) {
            if (data.changedCount > 0) {
                showToast(`✅ ${data.changedCount} dosya senkronize edildi!`, 'success');
            } else {
                showToast('Değişiklik yok, zaten güncel.', 'success');
            }
        } else {
            showToast('Sync hatası: ' + (data.error || data.reason), 'error');
        }
    } catch (e) {
        showToast('Sync hatası: ' + e.message, 'error');
    }
};



window.smartSync = async function () {
    const btn = document.getElementById('syncBtn');
    if (btn.classList.contains('loading')) return;

    window.updateSyncBtn('loading');

    try {
        // 1. Status Check
        const statusRes = await fetch(API + '/git/status');
        const statusData = await statusRes.json();

        let hasChanges = statusData.changes.length > 0;

        if (hasChanges) {
            const msgInput = document.getElementById('customCommitMsg').value;
            const dateStr = new Date().toLocaleString('tr-TR');
            const message = msgInput || `Veri Güncellemesi: ${dateStr}`;

            showToast('Paketleniyor...', 'info');
            const commitRes = await fetch(API + '/git/commit', {
                method: 'POST', headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ message })
            });
            const commitData = await commitRes.json();
            if (!commitData.success) throw new Error(commitData.error);
        }

        // 2. Push Check
        showToast('Buluta gönderiliyor...', 'info');
        const pushRes = await fetch(API + '/git/push', { method: 'POST' });
        const pushData = await pushRes.json();

        if (pushData.success) {
            showToast('Senkronizasyon Başarılı! 🚀');
            document.getElementById('customCommitMsg').value = '';
            checkGitStatus();
        } else {
            throw new Error(pushData.error);
        }

    } catch (e) {
        showToast('Hata: ' + e.message, 'error');

        // ERROR HANDLING STRATEGIES
        if (e.message.includes('Repository not found') || e.message.includes('not found')) { // 404
            if (confirm('Repository bulunamadı. URL ayarlarını kontrol etmek ister misiniz?')) {
                configureGit();
            }
        }
        else if (e.message.includes('rejected') || e.message.includes('fetch first') || e.message.includes('contains work')) { // Conflict/Behind
            if (confirm('⚠️ Bulutta sizde olmayan yeni veriler var (Remote Ahead).\n\nVerileri indirip birleştirmek (PULL) istiyor musunuz?')) {
                showToast('Buluttan veri çekiliyor...', 'info');
                try {
                    const pullRes = await fetch(API + '/git/pull', { method: 'POST' }); // PULL isteği
                    const pullData = await pullRes.json();

                    if (pullData.success) {
                        showToast('Veriler başarıyla güncellendi! ✅\nŞimdi tekrar EŞİTLE butonuna basın.', 'success');
                        checkGitStatus();
                    } else {
                        showToast('Güncelleme hatası: ' + pullData.error, 'error');
                    }
                } catch (pe) { showToast('Pull hatası (Network)', 'error'); }
            }
        }

        window.updateSyncBtn('ready');
    }
};

window.updateSyncBtn = function (state) {
    const btn = document.getElementById('syncBtn');
    if (!btn) return;

    if (state === 'loading') {
        btn.classList.add('loading');
        btn.innerHTML = '<span class="material-icons-round">sync</span><span>SÜRÜYOR...</span>';
    } else if (state === 'ready') {
        btn.classList.remove('loading');
        btn.style.background = 'var(--accent)';
        btn.innerHTML = '<span class="material-icons-round">cloud_upload</span><span>EŞİTLE</span>';
    } else {
        btn.classList.remove('loading');
        btn.style.background = 'var(--success)';
        btn.innerHTML = '<span class="material-icons-round">check</span><span>GÜNCEL</span>';
    }
};


// ══════════════════════════════════════════════════════════════════════════
// MODULE PUBLISH FUNCTION
// ══════════════════════════════════════════════════════════════════════════



// ══════════════════════════════════════════════════════════════════════════
// INITIALIZATION
// ══════════════════════════════════════════════════════════════════════════

// Auto-sync durumunu periyodik kontrol et (her 30 saniye)
setInterval(window.checkAutoSyncStatus, 30000);

// Sayfa yüklendiğinde kontrol et
document.addEventListener('DOMContentLoaded', () => {
    // Only run if elements exist (might be loaded before DOM is ready)
    if (document.getElementById('autoSyncIndicator')) {
        window.checkAutoSyncStatus();
    }
});


