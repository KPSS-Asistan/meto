/* === modules\update.js === */

/**
 * Update Config Module
 * Güncelleme yapılandırması yönetimi
 */

window.loadUpdateConfig = async function () {
    try {
        const res = await fetch(`${API}/api/update/config`);
        const data = await res.json();

        if (!data.success || !data.config) {
            document.getElementById('updateStatus').innerHTML = `
                <div style="color:#ef4444; display:flex; align-items:center; gap:0.5rem">
                    <span class="material-icons-round">error</span>
                    app_update.json bulunamadı
                </div>`;
            return;
        }

        const config = data.config;

        // Last updated
        document.getElementById('updateLastUpdated').textContent = config.last_updated || '-';

        // Android fields
        fillPlatformFields('android', config.android);

        // iOS fields
        fillPlatformFields('ios', config.ios);

        document.getElementById('updateStatus').innerHTML = `
            <div style="color:#22c55e; display:flex; align-items:center; gap:0.5rem">
                <span class="material-icons-round">check_circle</span>
                Yapılandırma yüklendi
            </div>`;

    } catch (e) {
        console.error('Update config load error:', e);
        document.getElementById('updateStatus').innerHTML = `
            <div style="color:#ef4444">Hata: ${e.message}</div>`;
    }
};

function fillPlatformFields(platform, data) {
    if (!data) return;
    const prefix = platform;
    const el = (id) => document.getElementById(`${prefix}_${id}`);

    if (el('min_version')) el('min_version').value = data.min_version || '1.0.0';
    if (el('latest_version')) el('latest_version').value = data.latest_version || '1.0.0';
    if (el('force_update')) el('force_update').checked = data.force_update || false;
    if (el('update_message')) el('update_message').value = data.update_message || '';
    if (el('store_url')) el('store_url').value = data.store_url || '';
}

function collectPlatformFields(platform) {
    const el = (id) => document.getElementById(`${platform}_${id}`);
    return {
        min_version: el('min_version')?.value?.trim() || '1.0.0',
        latest_version: el('latest_version')?.value?.trim() || '1.0.0',
        force_update: el('force_update')?.checked || false,
        update_message: el('update_message')?.value?.trim() || '',
        store_url: el('store_url')?.value?.trim() || ''
    };
}

window.saveUpdateConfig = async function () {
    const btn = document.getElementById('saveUpdateBtn');
    const originalHTML = btn.innerHTML;
    btn.innerHTML = '<span class="material-icons-round" style="animation:spin 1s linear infinite">sync</span> Kaydediliyor...';
    btn.disabled = true;

    try {
        const payload = {
            android: collectPlatformFields('android'),
            ios: collectPlatformFields('ios')
        };

        const res = await fetch(`${API}/api/update/config`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        const data = await res.json();

        if (!res.ok) {
            throw new Error(data.error || 'Bilinmeyen hata');
        }

        document.getElementById('updateStatus').innerHTML = `
            <div style="color:#22c55e; display:flex; align-items:center; gap:0.5rem">
                <span class="material-icons-round">check_circle</span>
                Kaydedildi!
            </div>`;

        // Update last_updated display
        if (data.config?.last_updated) {
            document.getElementById('updateLastUpdated').textContent = data.config.last_updated;
        }

    } catch (e) {
        document.getElementById('updateStatus').innerHTML = `
            <div style="color:#ef4444; display:flex; align-items:center; gap:0.5rem">
                <span class="material-icons-round">error</span>
                Hata: ${e.message}
            </div>`;
    } finally {
        btn.innerHTML = originalHTML;
        btn.disabled = false;
    }
};

// Copy same values to iOS
window.copyAndroidToIos = function () {
    const android = collectPlatformFields('android');
    fillPlatformFields('ios', android);
};

window.fetchCurrentVersion = async function () {
    try {
        const res = await fetch(`${API}/api/update/current-version`);
        const data = await res.json();

        if (data.success && data.version) {
            document.getElementById('android_latest_version').value = data.version;
            document.getElementById('ios_latest_version').value = data.version;
            document.getElementById('updateStatus').innerHTML = `
                <div style="color:#22c55e; display:flex; align-items:center; gap:0.5rem">
                    <span class="material-icons-round">check_circle</span>
                    Mevcut sürüm (${data.version}) pubspec.yaml'dan alındı. Kaydetmeyi unutmayın.
                </div>`;
        } else {
            throw new Error(data.error || 'Sürüm alınamadı');
        }
    } catch (e) {
        document.getElementById('updateStatus').innerHTML = `
            <div style="color:#ef4444; display:flex; align-items:center; gap:0.5rem">
                <span class="material-icons-round">error</span>
                Hata: ${e.message}
            </div>`;
    }
};

// ══════════════════════════════════════════════════════════════════════════
// APP INITIALIZATION & NAVIGATION
// ══════════════════════════════════════════════════════════════════════════

window.API = window.API_URL || 'http://localhost:3456';

window.showPage = function (pageId) {
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    const target = document.getElementById('page-' + pageId);
    if (target) {
        target.classList.add('active');
    }

    document.querySelectorAll('.nav-tab').forEach(b => b.classList.remove('active'));
    const nav = document.querySelector(`.nav-tab[data-page="${pageId}"]`);
    if (nav) nav.classList.add('active');

    console.log('Navigating to page:', pageId);

    // Page-specific initialization
    try {
        if (pageId === 'dashboard') {
            if (window.loadStats) window.loadStats();
        }
        if (pageId === 'add') {
            if (window.loadAddLessons) window.loadAddLessons();
            if (window.loadAddTopics) window.loadAddTopics();
        }
        if (pageId === 'users') {
            if (window.loadUsers) window.loadUsers();
        }
        if (pageId === 'reports') {
            if (window.loadReports) window.loadReports();
        }
        if (pageId === 'browse') {
            if (window.initBrowse) window.initBrowse();
            else if (window.loadBrowseTopics) window.loadBrowseTopics();
        }
        if (pageId === 'flashcards') {
            if (window.initFlashcards) window.initFlashcards();
            else if (window.loadFlashcardFiles) window.loadFlashcardFiles();
        }
        if (pageId === 'stories') {
            if (window.initStories) window.initStories();
            else if (window.loadStoryFiles) window.loadStoryFiles();
        }
        if (pageId === 'explanations') {
            if (window.initExplanations) window.initExplanations();
            else if (window.loadExplanationFiles) window.loadExplanationFiles();
        }
        if (pageId === 'matching-games') {
            if (window.initMatchingGames) window.initMatchingGames();
            else if (window.loadMatchingGameFiles) window.loadMatchingGameFiles();
        }
        if (pageId === 'notifications') {
            if (window.initNotificationsPage) window.initNotificationsPage();
        }
        if (pageId === 'modules') {
            if (window.initModulesPage) window.initModulesPage();
        }
        if (pageId === 'update') {
            if (window.loadUpdateConfig) window.loadUpdateConfig();
        }
        if (pageId === 'feedbacks') {
            if (window.loadFeedbacks) window.loadFeedbacks();
        }
        if (pageId === 'quality-check') {
            if (window.qualityCheck && !window.qualityCheck._hasRun) {
                window.qualityCheck._hasRun = true;
                window.qualityCheck.run('local');
            }
        }
        if (pageId === 'ai-analysis') {
            if (window.aiAnalysis) window.aiAnalysis.init();
        }
        if (pageId === 'ai-content') {
            if (window.refreshTopics) window.refreshTopics();
            if (window.updateCostDisplay) window.updateCostDisplay();
        }
        if (pageId === 'drafts') {
            if (window.loadAllDrafts) window.loadAllDrafts();
        }

        if (pageId === 'content-stats') {
            if (window.initContentStatsPage) window.initContentStatsPage();
        }
        if (pageId === 'cost-tracker') {
            if (window.initCostTrackerPage) window.initCostTrackerPage();
        }
        if (pageId === 'nightly') {
            if (window.initNightlyPage) window.initNightlyPage();
        }
        if (pageId === 'force-update') {
            if (window.loadForceUpdateConfig) window.loadForceUpdateConfig();
        }
    } catch (e) {
        console.error('Page init error:', e);
    }
};

// ═══════════════════════════════════════════════════════════════════════════
// FORCE UPDATE PAGE
// ═══════════════════════════════════════════════════════════════════════════

window.loadForceUpdateConfig = async function () {
    const banner = document.getElementById('fu-app-version-banner');

    // Fetch current app version from pubspec
    try {
        const vr = await fetch(`${window.API}/api/update/current-version`);
        const vd = await vr.json();
        if (vd.success && banner) {
            banner.innerHTML = `<span class="material-icons-round" style="color:#818cf8">info</span>
                <span style="font-size:0.85rem;color:#94a3b8">Mevcut pubspec versiyonu: <strong style="color:#e2e8f0">${vd.version}</strong></span>`;
        }
    } catch (_) { }

    // Fetch app_update.json config
    try {
        const r = await fetch(`${window.API}/api/update/config`);
        const d = await r.json();
        if (!d.success || !d.config) return;

        const { android, ios } = d.config;

        if (android) {
            document.getElementById('fu-android-min').value = android.min_version || '';
            document.getElementById('fu-android-latest').value = android.latest_version || '';
            document.getElementById('fu-android-msg').value = android.update_message || '';
            document.getElementById('fu-android-url').value = android.store_url || '';
            const cb = document.getElementById('fu-android-force');
            cb.checked = !!android.force_update;
            document.getElementById('fu-android-force-label').textContent = cb.checked ? '🔴 Force Update AKTİF' : 'Force Update Kapalı';
            document.getElementById('fu-android-force-label').style.color = cb.checked ? '#f87171' : '#94a3b8';
        }
        if (ios) {
            document.getElementById('fu-ios-min').value = ios.min_version || '';
            document.getElementById('fu-ios-latest').value = ios.latest_version || '';
            document.getElementById('fu-ios-msg').value = ios.update_message || '';
            document.getElementById('fu-ios-url').value = ios.store_url || '';
            const cb2 = document.getElementById('fu-ios-force');
            cb2.checked = !!ios.force_update;
            document.getElementById('fu-ios-force-label').textContent = cb2.checked ? '🔴 Force Update AKTİF' : 'Force Update Kapalı';
            document.getElementById('fu-ios-force-label').style.color = cb2.checked ? '#f87171' : '#94a3b8';
        }
    } catch (e) {
        console.error('loadForceUpdateConfig error:', e);
    }

    // Live toggle labels
    ['android', 'ios'].forEach(platform => {
        const cb = document.getElementById(`fu-${platform}-force`);
        const lbl = document.getElementById(`fu-${platform}-force-label`);
        if (cb && lbl) {
            cb.addEventListener('change', () => {
                lbl.textContent = cb.checked ? '🔴 Force Update AKTİF' : 'Force Update Kapalı';
                lbl.style.color = cb.checked ? '#f87171' : '#94a3b8';
            });
        }
    });
};

window.saveForceUpdateConfig = async function () {
    const statusEl = document.getElementById('fu-status');

    const versionPattern = /^\d+\.\d+\.\d+$/;
    const androidMin = document.getElementById('fu-android-min').value.trim();
    const androidLatest = document.getElementById('fu-android-latest').value.trim();
    const iosMin = document.getElementById('fu-ios-min').value.trim();
    const iosLatest = document.getElementById('fu-ios-latest').value.trim();

    if (!versionPattern.test(androidMin) || !versionPattern.test(androidLatest) ||
        !versionPattern.test(iosMin) || !versionPattern.test(iosLatest)) {
        statusEl.style.display = 'block';
        statusEl.style.background = 'rgba(239,68,68,0.15)';
        statusEl.style.border = '1px solid rgba(239,68,68,0.4)';
        statusEl.style.color = '#fca5a5';
        statusEl.textContent = '❌ Versiyon formatı hatalı. x.y.z formatında olmalı (örn: 1.2.3)';
        return;
    }

    const payload = {
        android: {
            min_version: androidMin,
            latest_version: androidLatest,
            force_update: document.getElementById('fu-android-force').checked,
            update_message: document.getElementById('fu-android-msg').value.trim(),
            store_url: document.getElementById('fu-android-url').value.trim()
        },
        ios: {
            min_version: iosMin,
            latest_version: iosLatest,
            force_update: document.getElementById('fu-ios-force').checked,
            update_message: document.getElementById('fu-ios-msg').value.trim(),
            store_url: document.getElementById('fu-ios-url').value.trim()
        }
    };

    statusEl.style.display = 'block';
    statusEl.style.background = 'rgba(99,102,241,0.1)';
    statusEl.style.border = '1px solid rgba(99,102,241,0.3)';
    statusEl.style.color = '#a5b4fc';
    statusEl.textContent = '⏳ Kaydediliyor...';

    try {
        const r = await fetch(`${window.API}/api/update/config`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const d = await r.json();

        if (d.success) {
            statusEl.style.background = 'rgba(52,211,153,0.1)';
            statusEl.style.border = '1px solid rgba(52,211,153,0.3)';
            statusEl.style.color = '#6ee7b7';
            statusEl.textContent = `✅ app_update.json kaydedildi.`;
        } else {
            statusEl.style.background = 'rgba(239,68,68,0.1)';
            statusEl.style.border = '1px solid rgba(239,68,68,0.3)';
            statusEl.style.color = '#fca5a5';
            statusEl.textContent = `❌ Hata: ${d.error}`;
        }
    } catch (e) {
        statusEl.style.background = 'rgba(239,68,68,0.1)';
        statusEl.style.border = '1px solid rgba(239,68,68,0.3)';
        statusEl.style.color = '#fca5a5';
        statusEl.textContent = `❌ İstek hatası: ${e.message}`;
    }
};

// ═══════════════════════════════════════════════════════════════════════════
// MODULES MANAGEMENT - Lesson/Topic Tree + Inline Item Editor
// ═══════════════════════════════════════════════════════════════════════════

let _modulesPageType = 'explanations';
let _modulesPageFile = null;
let _modulesTopics = [];
let _modulesAllFiles = [];
let _modulesCurrentItems = [];

const _MODULE_PATHS = {
    explanations: 'explanations',
    flashcards: 'flashcards',
    stories: 'stories',
    matching_games: 'matching_games'
};

const _LESSON_ICONS = {
    'TARİH': 'history_edu', 'MATEMATİK': 'calculate', 'COĞRAFYA': 'public',
    'VATANDAŞLIK': 'gavel', 'TÜRKÇE': 'spellcheck', 'GÜNCEL BİLGİLER': 'newspaper',
    'DİN': 'mosque', 'FEN': 'science', 'default': 'school'
};
const _LESSON_COLORS = {
    'TARİH': '#f59e0b', 'MATEMATİK': '#6366f1', 'COĞRAFYA': '#22c55e',
    'VATANDAŞLIK': '#ef4444', 'TÜRKÇE': '#0ea5e9', 'GÜNCEL BİLGİLER': '#a78bfa',
    'default': '#64748b'
};
const _PREFIX_LESSON = {
    'MAT': 'MATEMATİK', 'GUNCEL': 'GÜNCEL BİLGİLER', 'TARIH': 'TARİH',
    'COGRAFYA': 'COĞRAFYA', 'VATANDAS': 'VATANDAŞLIK', 'TURKCE': 'TÜRKÇE'
};

function _modGetTopicInfo(filename) {
    const id = filename.replace('.json', '');
    const found = _modulesTopics.find(t => t.id === id);
    if (found) return { name: found.name, lesson: found.lesson };
    for (const [prefix, lesson] of Object.entries(_PREFIX_LESSON)) {
        if (id.toUpperCase().startsWith(prefix + '_')) {
            const raw = id.slice(prefix.length + 1).replace(/_/g, ' ');
            const name = raw.split(' ').map(w => w.charAt(0) + w.slice(1).toLowerCase()).join(' ');
            return { name, lesson };
        }
    }
    return { name: id, lesson: 'Diğer' };
}

// ─── Tab + Tree helpers ────────────────────────────────────────────────────

function _modUpdateTabStyles(activeType) {
    document.querySelectorAll('.module-type-btn').forEach(btn => {
        const isActive = btn.dataset.type === activeType;
        btn.style.background = isActive ? 'var(--primary)' : 'transparent';
        btn.style.color = isActive ? 'white' : 'var(--text-muted)';
    });
}

async function _modLoadTopics() {
    try {
        const res = await fetch(`${window.API}/api/topics`);
        const data = await res.json();
        _modulesTopics = data.topics || [];
    } catch (_) { _modulesTopics = []; }
}

function _modRenderTree(files) {
    const treeEl = document.getElementById('modLessonTree');
    if (!treeEl) return;

    const badge = document.getElementById(`mod-badge-${_modulesPageType}`);
    if (badge) badge.textContent = files.length;

    if (files.length === 0) {
        treeEl.innerHTML = `<div style="padding:20px;text-align:center;color:var(--text-muted);font-size:0.82rem;">Bu modülde henüz dosya yok</div>`;
        return;
    }

    const groups = {};
    files.forEach(f => {
        const { name, lesson } = _modGetTopicInfo(f.name);
        if (!groups[lesson]) groups[lesson] = [];
        groups[lesson].push({ file: f.name, name });
    });

    const lessonOrder = ['TARİH', 'COĞRAFYA', 'VATANDAŞLIK', 'TÜRKÇE', 'MATEMATİK', 'GÜNCEL BİLGİLER'];
    const sortedLessons = Object.keys(groups).sort((a, b) => {
        const ia = lessonOrder.indexOf(a); const ib = lessonOrder.indexOf(b);
        if (ia === -1 && ib === -1) return a.localeCompare(b, 'tr');
        if (ia === -1) return 1; if (ib === -1) return -1;
        return ia - ib;
    });

    treeEl.innerHTML = sortedLessons.map(lesson => {
        const topics = groups[lesson];
        const icon = _LESSON_ICONS[lesson] || _LESSON_ICONS.default;
        const color = _LESSON_COLORS[lesson] || _LESSON_COLORS.default;
        const isOpen = topics.some(t => t.file === _modulesPageFile);
        return `
        <div class="mod-lesson-group${isOpen ? ' open' : ''}">
          <div onclick="this.closest('.mod-lesson-group').classList.toggle('open')"
            style="padding:10px 14px;cursor:pointer;display:flex;align-items:center;gap:8px;
                   border-bottom:1px solid var(--border);user-select:none;background:var(--bg-hover);">
            <span class="material-icons-round" style="font-size:15px;color:${color};">${icon}</span>
            <span style="font-size:0.78rem;font-weight:700;color:var(--text);text-transform:uppercase;letter-spacing:0.04em;flex:1;">${lesson}</span>
            <span style="background:var(--bg);border:1px solid var(--border);border-radius:10px;padding:1px 7px;font-size:0.7rem;color:var(--text-muted);">${topics.length}</span>
            <span class="material-icons-round mod-chevron" style="font-size:16px;color:var(--text-muted);transition:transform 0.2s;">expand_more</span>
          </div>
          <div class="mod-lesson-topics">
            ${topics.map(t => {
            const isActive = _modulesPageFile === t.file;
            return `<div onclick="loadModuleFile('${t.file}')"
                  style="padding:9px 14px 9px 38px;cursor:pointer;display:flex;align-items:center;gap:8px;
                         border-bottom:1px solid var(--border);transition:background 0.12s;
                         background:${isActive ? `${color}18` : 'transparent'};"
                  onmouseover="if('${t.file}'!==window._modulesPageFile)this.style.background='${color}0d';"
                  onmouseout="if('${t.file}'!==window._modulesPageFile)this.style.background='';">
                  <span class="material-icons-round" style="font-size:12px;color:${isActive ? color : 'var(--text-muted)'};">
                    ${isActive ? 'radio_button_checked' : 'radio_button_unchecked'}
                  </span>
                  <span style="font-size:0.82rem;color:${isActive ? color : 'var(--text)'};font-weight:${isActive ? '600' : '400'};
                               flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${t.name}</span>
                </div>`;
        }).join('')}
          </div>
        </div>`;
    }).join('');

}

// ─── Page init / type switch ───────────────────────────────────────────────

window.initModulesPage = async function () {
    if (!_modulesPageType) _modulesPageType = 'explanations';
    _modUpdateTabStyles(_modulesPageType);
    if (_modulesTopics.length === 0) await _modLoadTopics();
    await refreshModuleFiles();
};

window.selectModuleType = async function (type) {
    _modulesPageType = type;
    _modulesPageFile = null;
    window._modulesPageFile = null;
    _modulesCurrentItems = [];
    _modUpdateTabStyles(type);
    _modShowItemPanel('empty');
    await refreshModuleFiles();
};

window.refreshModuleFiles = async function () {
    const treeEl = document.getElementById('modLessonTree');
    if (!treeEl) return;
    treeEl.innerHTML = `<div style="padding:16px;display:flex;align-items:center;gap:8px;color:var(--text-muted);font-size:0.82rem;">
        <span class="material-icons-round" style="font-size:15px;animation:spin 1s linear infinite;">sync</span>Yükleniyor...</div>`;
    try {
        const res = await fetch(`${window.API}/api/ai-content/files?module=${_MODULE_PATHS[_modulesPageType]}`);
        const data = await res.json();
        _modulesAllFiles = data.files || [];
        _modRenderTree(_modulesAllFiles);
    } catch (_) {
        treeEl.innerHTML = `<div style="padding:16px;text-align:center;color:#ef4444;font-size:0.82rem;">Bağlantı hatası</div>`;
    }
};

function _modShowItemPanel(state) {
    const empty = document.getElementById('modItemEmpty');
    const loading = document.getElementById('modItemLoading');
    const list = document.getElementById('modItemList');
    const header = document.getElementById('modItemHeader');
    if (empty) empty.style.display = state === 'empty' ? 'flex' : 'none';
    if (loading) loading.style.display = state === 'loading' ? 'flex' : 'none';
    if (list) list.style.display = state === 'list' ? 'block' : 'none';
    if (header) header.style.display = state === 'empty' ? 'none' : 'flex';
}

// ─── Load file → render items ──────────────────────────────────────────────

window.loadModuleFile = async function (filename) {
    _modulesPageFile = filename;
    window._modulesPageFile = filename;

    const { name, lesson } = _modGetTopicInfo(filename);
    const lessonEl = document.getElementById('modItemLesson');
    const topicEl = document.getElementById('modItemTopicName');
    if (lessonEl) lessonEl.textContent = lesson;
    if (topicEl) topicEl.textContent = name;

    _modShowItemPanel('loading');
    _modRenderTree(_modulesAllFiles); // update selection highlight

    try {
        const res = await fetch(`${window.API}/api/ai-content/file?module=${_MODULE_PATHS[_modulesPageType]}&filename=${encodeURIComponent(filename)}`);
        const data = await res.json();
        if (data.success && data.content) {
            try { _modulesCurrentItems = JSON.parse(data.content); } catch (_) { _modulesCurrentItems = []; }
        } else { _modulesCurrentItems = []; }
        _modRenderItems();
        _modShowItemPanel('list');
    } catch (e) {
        console.error(e);
        _modShowItemPanel('empty');
        showToast('Dosya yüklenemedi: ' + e.message, 'error');
    }
};

function _modRenderItems() {
    const listEl = document.getElementById('modItemList');
    if (!listEl) return;
    const countEl = document.getElementById('modItemCount');
    if (countEl) countEl.textContent = `${_modulesCurrentItems.length} öğe`;

    if (_modulesCurrentItems.length === 0) {
        listEl.innerHTML = `<div style="padding:30px;text-align:center;color:var(--text-muted);font-size:0.88rem;">
            Henüz içerik yok.<br><span style="font-size:0.78rem;opacity:0.6;">Yukarıdaki "Yeni Ekle" ile başlayın.</span></div>`;
        return;
    }
    listEl.innerHTML = _modulesCurrentItems.map((item, i) => _modItemCard(item, i)).join('');
}

// ─── Item card + inline editor ─────────────────────────────────────────────

const _BLOCK_COLORS = { heading: '#6366f1', text: '#64748b', bulletList: '#0ea5e9', highlighted: '#f59e0b', example: '#22c55e', tip: '#a78bfa' };

function _modItemCard(item, i) {
    const type = _modulesPageType;
    let summary = '';
    if (type === 'flashcards' || type === 'matching_games') {
        summary = `<div style="font-size:0.85rem;font-weight:500;color:var(--text);line-height:1.4;">${item.question || '<em style="opacity:0.5">Soru yok</em>'}</div>
                   <div style="font-size:0.75rem;color:var(--text-muted);margin-top:3px;">${(item.answer || '').substring(0, 80)}${(item.answer || '').length > 80 ? '…' : ''}</div>`;
    } else if (type === 'explanations') {
        summary = `<div style="font-size:0.85rem;font-weight:500;color:var(--text);">${item.title || '<em style="opacity:0.5">Başlık yok</em>'}</div>
                   <div style="font-size:0.75rem;color:var(--text-muted);margin-top:3px;">${item.difficulty || 'medium'} · ${(item.content || []).length} blok</div>`;
    } else if (type === 'stories') {
        summary = `<div style="font-size:0.85rem;font-weight:500;color:var(--text);">${item.title || '<em style="opacity:0.5">Başlık yok</em>'}</div>
                   <div style="font-size:0.75rem;color:var(--text-muted);margin-top:3px;">${(item.key_points || []).length} anahtar nokta · ${Math.round((item.content || '').length / 1000)}k karakter</div>`;
    }

    return `<div id="mod-item-${i}" style="border:1px solid var(--border);border-radius:12px;overflow:hidden;margin-bottom:8px;">
      <div style="padding:11px 14px;display:flex;align-items:center;gap:10px;background:var(--bg-card);">
        <span style="background:var(--primary);color:white;border-radius:6px;padding:2px 8px;font-size:0.7rem;font-weight:700;flex-shrink:0;">${i + 1}</span>
        <div style="flex:1;min-width:0;">${summary}</div>
        <div style="display:flex;gap:5px;flex-shrink:0;">
          <button onclick="editModuleItem(${i})"
            style="padding:5px 10px;border-radius:7px;border:1px solid var(--border);background:transparent;color:var(--text-muted);cursor:pointer;font-size:0.75rem;display:flex;align-items:center;gap:3px;white-space:nowrap;"
            onmouseover="this.style.borderColor='var(--primary)';this.style.color='var(--primary)';"
            onmouseout="this.style.borderColor='var(--border)';this.style.color='var(--text-muted)';">
            <span class="material-icons-round" style="font-size:13px;">edit</span>Düzenle
          </button>
          <button onclick="deleteModuleItem(${i})"
            style="padding:5px 8px;border-radius:7px;border:1px solid rgba(239,68,68,0.3);background:transparent;color:#ef4444;cursor:pointer;display:flex;align-items:center;"
            onmouseover="this.style.background='rgba(239,68,68,0.1)';" onmouseout="this.style.background='transparent';">
            <span class="material-icons-round" style="font-size:14px;">delete</span>
          </button>
        </div>
      </div>
      <div id="mod-editor-${i}" style="display:none;padding:14px;border-top:1px solid var(--border);background:var(--bg);">
        ${_modEditorForm(item, i)}
      </div>
    </div>`;
}

function _modEditorForm(item, i) {
    const type = _modulesPageType;
    const field = (id, label, rows, val) => `
        <div style="margin-bottom:12px;">
          <label style="font-size:0.72rem;font-weight:700;color:var(--text-muted);display:block;margin-bottom:4px;text-transform:uppercase;letter-spacing:0.05em;">${label}</label>
          ${rows === 1
            ? `<input type="text" id="mod-f-${i}-${id}" value="${String(val || '').replace(/"/g, '&quot;').replace(/\n/g, ' ')}"
                 style="width:100%;padding:8px 10px;border:1px solid var(--border);border-radius:8px;background:var(--bg-card);color:var(--text);font-size:0.85rem;outline:none;box-sizing:border-box;"
                 onfocus="this.style.borderColor='var(--primary)'" onblur="this.style.borderColor='var(--border)'">`
            : `<textarea id="mod-f-${i}-${id}" rows="${rows}"
                 style="width:100%;padding:8px 10px;border:1px solid var(--border);border-radius:8px;background:var(--bg-card);color:var(--text);font-size:0.85rem;resize:vertical;outline:none;font-family:inherit;box-sizing:border-box;"
                 onfocus="this.style.borderColor='var(--primary)'" onblur="this.style.borderColor='var(--border)'">${String(val || '').replace(/</g, '&lt;').replace(/>/g, '&gt;')}</textarea>`}
        </div>`;

    const actions = `<div style="display:flex;justify-content:flex-end;gap:8px;margin-top:4px;">
        <button onclick="cancelEditModuleItem(${i})" style="padding:7px 14px;border-radius:8px;border:1px solid var(--border);background:transparent;color:var(--text-muted);cursor:pointer;font-size:0.82rem;">İptal</button>
        <button onclick="saveModuleItem(${i})" style="padding:7px 16px;border-radius:8px;border:none;background:var(--primary);color:white;cursor:pointer;font-size:0.82rem;font-weight:600;display:flex;align-items:center;gap:5px;">
          <span class="material-icons-round" style="font-size:14px;">save</span>Kaydet
        </button>
      </div>`;

    if (type === 'matching_games') {
        return field('question', 'Kart (Sol)', 2, item.question) + field('answer', 'Eşleşme (Sağ)', 2, item.answer) + actions;
    }
    if (type === 'flashcards') {
        return field('question', 'Soru', 3, item.question) + field('answer', 'Cevap', 3, item.answer) + field('additionalInfo', 'Ek Bilgi (opsiyonel)', 2, item.additionalInfo) + actions;
    }
    if (type === 'explanations') {
        const blocks = (item.content || []).map((b, bi) => `
          <div data-bi="${bi}" style="display:flex;gap:8px;align-items:flex-start;margin-bottom:8px;">
            <span style="padding:3px 7px;border-radius:5px;font-size:0.62rem;font-weight:700;background:${_BLOCK_COLORS[b.type] || '#64748b'}22;color:${_BLOCK_COLORS[b.type] || '#64748b'};white-space:nowrap;margin-top:6px;min-width:64px;text-align:center;" data-block-type="${b.type || 'text'}">${b.type || 'text'}</span>
            <textarea class="mod-block-ta" data-index="${i}" rows="3"
              style="flex:1;padding:8px 10px;border:1px solid var(--border);border-radius:8px;background:var(--bg-card);color:var(--text);font-size:0.82rem;resize:vertical;outline:none;font-family:inherit;"
              onfocus="this.style.borderColor='var(--primary)'" onblur="this.style.borderColor='var(--border)'">${String(b.text || '').replace(/</g, '&lt;').replace(/>/g, '&gt;')}</textarea>
            <button onclick="this.closest('[data-bi]').remove()" style="margin-top:6px;padding:4px;border:none;background:transparent;color:#ef4444;cursor:pointer;">
              <span class="material-icons-round" style="font-size:15px;">close</span>
            </button>
          </div>`).join('');
        return `
          <div style="display:grid;grid-template-columns:1fr auto;gap:10px;margin-bottom:12px;">
            ${field('title', 'Başlık', 1, item.title)}
            <div>
              <label style="font-size:0.72rem;font-weight:700;color:var(--text-muted);display:block;margin-bottom:4px;text-transform:uppercase;letter-spacing:0.05em;">Zorluk</label>
              <select id="mod-f-${i}-difficulty" style="padding:8px 10px;border:1px solid var(--border);border-radius:8px;background:var(--bg-card);color:var(--text);font-size:0.85rem;outline:none;">
                <option value="easy" ${item.difficulty === 'easy' ? 'selected' : ''}>Kolay</option>
                <option value="medium" ${(!item.difficulty || item.difficulty === 'medium') ? 'selected' : ''}>Orta</option>
                <option value="hard" ${item.difficulty === 'hard' ? 'selected' : ''}>Zor</option>
              </select>
            </div>
          </div>
          <label style="font-size:0.72rem;font-weight:700;color:var(--text-muted);display:block;margin-bottom:6px;text-transform:uppercase;letter-spacing:0.05em;">İçerik Bloklar</label>
          <div id="mod-blocks-${i}">${blocks}</div>
          <button onclick="addExpBlock(${i})" style="width:100%;padding:7px;border:1px dashed var(--border);border-radius:8px;background:transparent;color:var(--text-muted);cursor:pointer;font-size:0.78rem;margin-bottom:14px;">
            + Blok Ekle
          </button>
          ${actions}`;
    }
    if (type === 'stories') {
        const kpRows = (item.key_points || []).map((kp, ki) => `
          <div style="display:flex;gap:8px;align-items:center;margin-bottom:6px;">
            <span style="color:var(--primary);font-size:1rem;flex-shrink:0;">•</span>
            <input type="text" class="mod-kp-input" data-index="${i}" value="${String(kp).replace(/"/g, '&quot;')}"
              style="flex:1;padding:6px 10px;border:1px solid var(--border);border-radius:7px;background:var(--bg-card);color:var(--text);font-size:0.82rem;outline:none;"
              onfocus="this.style.borderColor='var(--primary)'" onblur="this.style.borderColor='var(--border)'">
            <button onclick="this.closest('div').remove()" style="padding:3px;border:none;background:transparent;color:#ef4444;cursor:pointer;">
              <span class="material-icons-round" style="font-size:15px;">close</span>
            </button>
          </div>`).join('');
        return field('title', 'Başlık', 1, item.title) +
            field('content', 'Hikaye', 10, item.content) +
            `<label style="font-size:0.72rem;font-weight:700;color:var(--text-muted);display:block;margin-bottom:6px;text-transform:uppercase;letter-spacing:0.05em;">Anahtar Noktalar</label>
            <div id="mod-keypoints-${i}">${kpRows}</div>
            <button onclick="addKeyPoint(${i})" style="width:100%;padding:7px;border:1px dashed var(--border);border-radius:8px;background:transparent;color:var(--text-muted);cursor:pointer;font-size:0.78rem;margin-bottom:14px;">
              + Nokta Ekle
            </button>` + actions;
    }
    return `<div style="color:var(--text-muted)">Bilinmeyen tür</div>` + actions;
}

// ─── Edit / Cancel / Save / Delete / Add ──────────────────────────────────

window.editModuleItem = function (index) {
    document.querySelectorAll('[id^="mod-editor-"]').forEach(el => { el.style.display = 'none'; });
    const ed = document.getElementById(`mod-editor-${index}`);
    if (ed) {
        ed.style.display = 'block';
        ed.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
};

window.cancelEditModuleItem = function (index) {
    const ed = document.getElementById(`mod-editor-${index}`);
    if (ed) ed.style.display = 'none';
};

window.saveModuleItem = async function (index) {
    const type = _modulesPageType;
    const item = JSON.parse(JSON.stringify(_modulesCurrentItems[index]));
    const g = (id) => document.getElementById(`mod-f-${index}-${id}`)?.value ?? '';

    if (type === 'matching_games') {
        item.question = g('question'); item.answer = g('answer');
    } else if (type === 'flashcards') {
        item.question = g('question'); item.answer = g('answer'); item.additionalInfo = g('additionalInfo');
    } else if (type === 'explanations') {
        item.title = g('title');
        item.difficulty = g('difficulty') || 'medium';
        const blockRows = document.querySelectorAll(`#mod-blocks-${index} [data-bi]`);
        item.content = Array.from(blockRows).map((row, bi) => {
            const ta = row.querySelector('.mod-block-ta');
            const typeLabel = row.querySelector('[data-block-type]');
            return { type: typeLabel?.dataset.blockType || 'text', text: ta?.value || '' };
        });
    } else if (type === 'stories') {
        item.title = g('title');
        item.content = g('content');
        const kpInputs = document.querySelectorAll(`#mod-keypoints-${index} .mod-kp-input`);
        item.key_points = Array.from(kpInputs).map(inp => inp.value).filter(v => v.trim());
    }
    item.updatedAt = new Date().toISOString();
    _modulesCurrentItems[index] = item;

    try {
        await _modSaveCurrentItems();
        _modRenderItems();
        showToast('Kaydedildi ✓', 'success');
    } catch (e) {
        showToast('Kayıt hatası: ' + e.message, 'error');
    }
};

async function _modSaveCurrentItems() {
    const res = await fetch(`${window.API}/api/ai-content/file`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ module: _MODULE_PATHS[_modulesPageType], filename: _modulesPageFile, content: JSON.stringify(_modulesCurrentItems, null, 2) })
    });
    const data = await res.json();
    if (!data.success) throw new Error(data.error || 'Bilinmeyen hata');
}

window.deleteModuleItem = async function (index) {
    if (!confirm(`${index + 1}. öğeyi silmek istediğinize emin misiniz?`)) return;
    _modulesCurrentItems.splice(index, 1);
    try { await _modSaveCurrentItems(); _modRenderItems(); showToast('Silindi', 'success'); }
    catch (e) { showToast('Hata: ' + e.message, 'error'); _modulesCurrentItems.splice(index, 0, _modulesCurrentItems[index]); }
};

window.addNewModuleItem = function () {
    const type = _modulesPageType;
    const topicId = (_modulesPageFile || '').replace('.json', '');
    const ts = Date.now();
    const defaults = {
        flashcards: { topicId, question: '', answer: '', additionalInfo: '', id: `flash_${ts}_new` },
        matching_games: { topicId, question: '', answer: '', id: `match_${ts}_new` },
        explanations: { topicId, title: 'Yeni Bölüm', content: [{ type: 'text', text: '' }], difficulty: 'medium', type: 'detailed', id: `exp_${ts}_new` },
        stories: { topicId, title: 'Yeni Bölüm', content: '', key_points: [], type: 'story', id: `story_${ts}_new` }
    };
    _modulesCurrentItems.push(defaults[type] || { topicId, id: `item_${ts}` });
    _modRenderItems();
    const newIdx = _modulesCurrentItems.length - 1;
    setTimeout(() => {
        document.getElementById(`mod-item-${newIdx}`)?.scrollIntoView({ behavior: 'smooth' });
        editModuleItem(newIdx);
    }, 80);
};

window.addExpBlock = function (index) {
    const container = document.getElementById(`mod-blocks-${index}`);
    if (!container) return;
    const bi = container.children.length;
    const div = document.createElement('div');
    div.dataset.bi = bi;
    div.style.cssText = 'display:flex;gap:8px;align-items:flex-start;margin-bottom:8px;';
    div.innerHTML = `
      <span style="padding:3px 7px;border-radius:5px;font-size:0.62rem;font-weight:700;background:#64748b22;color:#64748b;white-space:nowrap;margin-top:6px;min-width:64px;text-align:center;" data-block-type="text">text</span>
      <textarea class="mod-block-ta" data-index="${index}" rows="3"
        style="flex:1;padding:8px 10px;border:1px solid var(--border);border-radius:8px;background:var(--bg-card);color:var(--text);font-size:0.82rem;resize:vertical;outline:none;font-family:inherit;"
        onfocus="this.style.borderColor='var(--primary)'" onblur="this.style.borderColor='var(--border)'"></textarea>
      <button onclick="this.closest('[data-bi]').remove()" style="margin-top:6px;padding:4px;border:none;background:transparent;color:#ef4444;cursor:pointer;">
        <span class="material-icons-round" style="font-size:15px;">close</span>
      </button>`;
    container.appendChild(div);
};

window.addKeyPoint = function (index) {
    const container = document.getElementById(`mod-keypoints-${index}`);
    if (!container) return;
    const div = document.createElement('div');
    div.style.cssText = 'display:flex;gap:8px;align-items:center;margin-bottom:6px;';
    div.innerHTML = `
      <span style="color:var(--primary);font-size:1rem;flex-shrink:0;">•</span>
      <input type="text" class="mod-kp-input" data-index="${index}" value=""
        style="flex:1;padding:6px 10px;border:1px solid var(--border);border-radius:7px;background:var(--bg-card);color:var(--text);font-size:0.82rem;outline:none;"
        onfocus="this.style.borderColor='var(--primary)'" onblur="this.style.borderColor='var(--border)'">
      <button onclick="this.closest('div').remove()" style="padding:3px;border:none;background:transparent;color:#ef4444;cursor:pointer;">
        <span class="material-icons-round" style="font-size:15px;">close</span>
      </button>`;
    container.appendChild(div);
    container.lastChild.querySelector('input').focus();
};

