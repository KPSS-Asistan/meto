/* === modules\backup.js === */

const _BACKUP_API = () => (window.CONFIG?.API_URL || window.API || 'http://localhost:8001');

// ─── State ───
let _backupState = {
    loading: false,
    creating: false,
    downloading: false
};

// ─── Sayfa Yükleme ───
window.loadBackupPage = async function () {
    await Promise.all([loadBackupHistory(), loadBackupTags()]);
};

// ─── Commit Geçmişi ───
async function loadBackupHistory() {
    const el = document.getElementById('backupHistoryList');
    if (!el) return;
    el.innerHTML = `<div style="padding:1.5rem;text-align:center;color:var(--text-muted)">
        <span class="material-icons-round" style="font-size:2rem;display:block;margin-bottom:.5rem">hourglass_empty</span>
        Yükleniyor...
    </div>`;
    try {
        const res = await fetch(_BACKUP_API() + '/api/backup/history');
        const data = await res.json();
        if (!data.success) throw new Error(data.error);

        if (!data.commits.length) {
            el.innerHTML = `<div style="padding:1.5rem;text-align:center;color:var(--text-muted)">Henüz commit yok.</div>`;
            return;
        }

        el.innerHTML = data.commits.map((c, i) => `
            <div style="display:flex;align-items:flex-start;gap:.85rem;padding:.85rem 1.25rem;border-bottom:1px solid var(--border);${i === 0 ? 'background:rgba(99,102,241,.06);' : ''}">
                <div style="width:36px;height:36px;background:rgba(99,102,241,.15);color:#6366f1;border-radius:8px;display:grid;place-items:center;flex-shrink:0;font-size:.7rem;font-family:monospace;font-weight:700">${c.hash}</div>
                <div style="flex:1;min-width:0;">
                    <div style="font-weight:500;font-size:.9rem;color:var(--text);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${escHtmlBackup(c.subject)}</div>
                    <div style="font-size:.75rem;color:var(--text-muted);margin-top:.2rem">${formatDateBackup(c.date)} · ${escHtmlBackup(c.author)}</div>
                </div>
                ${i === 0 ? `<span style="font-size:.7rem;background:rgba(16,185,129,.15);color:#10b981;padding:2px 8px;border-radius:10px;white-space:nowrap;align-self:center;">GÜNCEL</span>` : ''}
            </div>
        `).join('');
    } catch (e) {
        el.innerHTML = `<div style="padding:1.5rem;text-align:center;color:#ef4444">Hata: ${escHtmlBackup(e.message)}</div>`;
    }
}

// ─── Etiketler (Tags) ───
async function loadBackupTags() {
    const el = document.getElementById('backupTagsList');
    if (!el) return;
    el.innerHTML = `<div style="padding:1rem;text-align:center;color:var(--text-muted);font-size:.85rem">Yükleniyor...</div>`;
    try {
        const res = await fetch(_BACKUP_API() + '/api/backup/tags');
        const data = await res.json();
        if (!data.success) throw new Error(data.error);

        if (!data.tags.length) {
            el.innerHTML = `<div style="padding:1rem;text-align:center;color:var(--text-muted);font-size:.85rem">Henüz yedek noktası yok.</div>`;
            return;
        }

        el.innerHTML = data.tags.map(t => `
            <div style="display:flex;align-items:center;gap:.75rem;padding:.65rem 1.25rem;border-bottom:1px solid var(--border);">
                <span class="material-icons-round" style="font-size:1.1rem;color:#f59e0b;flex-shrink:0;">bookmark</span>
                <div style="flex:1;font-size:.88rem;color:var(--text);font-family:monospace;">${escHtmlBackup(t.name)}</div>
            </div>
        `).join('');
    } catch (e) {
        el.innerHTML = `<div style="padding:1rem;text-align:center;color:#ef4444;font-size:.85rem">Hata: ${escHtmlBackup(e.message)}</div>`;
    }
}

// ─── Yeni Yedek Oluştur ───
window.createBackupPoint = async function () {
    if (_backupState.creating) return;
    const labelInput = document.getElementById('backupLabelInput');
    const btn = document.getElementById('createBackupBtn');
    const label = labelInput ? labelInput.value.trim() : '';

    _backupState.creating = true;
    if (btn) { btn.disabled = true; btn.textContent = 'Oluşturuluyor...'; }

    try {
        const res = await fetch(_BACKUP_API() + '/api/backup/create', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ label })
        });
        const data = await res.json();
        if (!data.success) throw new Error(data.error);

        if (window.showToast) showToast(data.message || 'Yedek oluşturuldu!', 'success');
        if (labelInput) labelInput.value = '';
        await loadBackupTags();
    } catch (e) {
        if (window.showToast) showToast('Hata: ' + e.message, 'error');
    } finally {
        _backupState.creating = false;
        if (btn) { btn.disabled = false; btn.textContent = 'Yedek Noktası Oluştur'; }
    }
};

// ─── İndir ───
window.downloadBackup = function () {
    const a = document.createElement('a');
    a.href = _BACKUP_API() + '/api/backup/download';
    a.download = `assets-yedek-${new Date().toISOString().substring(0, 10)}.zip`;
    a.click();
};

// ─── Yardımcı ───
function escHtmlBackup(str) {
    return String(str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function formatDateBackup(iso) {
    if (!iso) return '-';
    try {
        return new Date(iso).toLocaleString('tr-TR', {
            day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit'
        });
    } catch { return iso; }
}
