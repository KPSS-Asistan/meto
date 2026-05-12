/* === modules\ui.js === */

/**
 * KPSS Dashboard - UI Module
 * Contains user interface helpers, notifications, and rendering logic.
 */

// 1. Toast Notification System
window.showToast = function (msg, type = 'info') {
    const toast = document.getElementById('toast');
    if (!toast) return;

    // Set icon based on type
    const iconMap = {
        success: 'check_circle',
        error: 'error',
        warning: 'warning',
        info: 'info'
    };
    const icon = iconMap[type] || 'info';

    toast.innerHTML = `<span class="material-icons-round">${icon}</span><span>${msg}</span>`;
    toast.className = `toast show ${type}`;

    // Position
    toast.style.position = 'fixed';
    toast.style.bottom = '20px';
    toast.style.right = '20px';
    toast.style.zIndex = '10001';

    // Auto-hide after 3 seconds
    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
};

// Copy Template to Clipboard
window.copyTemplate = async function (templateId) {
    const el = document.getElementById(templateId);
    if (!el) return;

    const text = el.textContent;
    try {
        await navigator.clipboard.writeText(text);
        showToast('Şablon kopyalandı!', 'success');
    } catch (err) {
        // Fallback
        const textarea = document.createElement('textarea');
        textarea.value = text;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        showToast('Şablon kopyalandı!', 'success');
    }
};

// ══════════════════════════════════════════════════════════════════════════
// 2. HTML Helper: Escape Unsafe Characters
window.escapeHtml = function (text) {
    if (typeof text !== 'string') return text;
    const div = document.createElement('div');
    div.textContent = text || '';
    return div.innerHTML;
};

// 3. Render Validation Results Panel
window.showValidationPanel = function (results, title = 'Validasyon Sonucu') {
    const errorEl = document.getElementById('jsonError');
    if (!errorEl) return;

    const validCount = results.filter(r => r.isValid).length;
    const invalidCount = results.filter(r => !r.isValid).length;
    const totalCount = results.length;

    let html = `
    <div style="background: var(--card); border: 1px solid ${invalidCount > 0 ? 'rgba(239, 68, 68, 0.4)' : 'rgba(34, 197, 94, 0.4)'}; border-radius: 12px; overflow: hidden; font-family: inherit; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3);">
        
        <!-- Header -->
        <div style="background: ${invalidCount > 0 ? 'rgba(239, 68, 68, 0.1)' : 'rgba(34, 197, 94, 0.1)'}; padding: 1.25rem 1.5rem; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border);">
            <div style="display: flex; align-items: center; gap: 1rem;">
                <span class="material-icons-round" style="font-size: 2rem; color: ${invalidCount > 0 ? '#ef4444' : '#22c55e'};">${invalidCount > 0 ? 'report_problem' : 'check_circle'}</span>
                <div>
                    <div style="font-size: 1.1rem; font-weight: 700; color: var(--text);">${title}</div>
                    <div style="font-size: 0.85rem; color: var(--text-muted);">${totalCount} soru analiz edildi</div>
                </div>
            </div>
            <div style="display: flex; gap: 0.75rem;">
                <div style="background: rgba(34, 197, 94, 0.15); padding: 0.5rem 1rem; border-radius: 10px; text-align: center; border: 1px solid rgba(34, 197, 94, 0.2);">
                    <div style="font-size: 1.25rem; font-weight: 800; color: #22c55e;">${validCount}</div>
                    <div style="font-size: 0.65rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.05em;">Geçerli</div>
                </div>
                <div style="background: rgba(239, 68, 68, 0.15); padding: 0.5rem 1rem; border-radius: 10px; text-align: center; border: 1px solid rgba(239, 68, 68, 0.2);">
                    <div style="font-size: 1.25rem; font-weight: 800; color: #ef4444;">${invalidCount}</div>
                    <div style="font-size: 0.65rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.05em;">Hatalı</div>
                </div>
            </div>
        </div>
        
        <!-- Question List -->
        <div style="max-height: 400px; overflow-y: auto; background: rgba(15, 23, 42, 0.3);">
    `;

    results.forEach((r, idx) => {
        const isError = !r.isValid;
        const statusColor = isError ? '#ef4444' : '#22c55e';
        const bgColor = isError ? 'rgba(239, 68, 68, 0.03)' : 'transparent';
        const borderColor = isError ? 'rgba(239, 68, 68, 0.1)' : 'rgba(255, 255, 255, 0.03)';

        html += `
            <div style="display: flex; align-items: center; padding: 1rem 1.5rem; border-bottom: 1px solid ${borderColor}; background: ${bgColor}; transition: background 0.2s;">
                <!-- Status Icon -->
                <span class="material-icons-round" style="font-size: 1.25rem; color: ${statusColor}; margin-right: 1rem;">${isError ? 'cancel' : 'check_circle'}</span>
                
                <!-- Question Number -->
                <div style="background: ${isError ? 'rgba(239, 68, 68, 0.2)' : 'rgba(34, 197, 94, 0.2)'}; color: ${statusColor}; padding: 0.25rem 0.75rem; border-radius: 6px; font-size: 0.75rem; font-weight: 700; min-width: 3rem; text-align: center; margin-right: 1.25rem; border: 1px solid ${statusColor}33;">
                    #${r.index}
                </div>
                
                <!-- Preview -->
                <div style="flex: 1; min-width: 0;">
                    <div style="color: var(--text); font-size: 0.9rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; font-weight: 500;">
                        ${window.escapeHtml(r.preview)}
                    </div>
                    ${isError ? `<div style="color: #fca5a5; font-size: 0.8rem; margin-top: 0.25rem; font-weight: 400; display: flex; align-items: center; gap: 0.25rem;">
                        <span class="material-icons-round" style="font-size: 0.9rem;">info</span>
                        ${r.errors.join(' • ')}
                    </div>` : ''}
                </div>
                
                <!-- Action Button -->
                ${isError ? `
                <button onclick="document.getElementById('editModal').style.display='flex';" style="margin-left: 1rem; background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); color: var(--text-muted); border-radius: 6px; padding: 0.4rem; cursor: pointer; transition: all 0.2s;">
                    <span class="material-icons-round" style="font-size: 1.2rem;">edit</span>
                </button>` : `
                <button style="margin-left: 1rem; background: transparent; border: none; color: #22c55e; opacity: 0.5;">
                    <span class="material-icons-round" style="font-size: 1.2rem;">verified</span>
                </button>`}
            </div>
        `;
    });

    html += `
        </div>
        <!-- Footer -->
        <div style="background: var(--card); padding: 0.75rem; display: flex; justify-content: flex-end; border-top: 1px solid var(--border);">
            <button onclick="document.getElementById('jsonError').style.display='none'" style="background: var(--input-bg); color: var(--text); border: none; padding: 0.5rem 1.25rem; border-radius: 8px; font-weight: 500; cursor: pointer; transition: background 0.2s;">
                Kapat
            </button>
        </div>
    </div>`;

    errorEl.innerHTML = html;
    errorEl.style.display = 'block';
};


