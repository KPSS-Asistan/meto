// === AI Content Module (Önce tanımlanmalı) ===
const API = (window.CONFIG && window.CONFIG.API_URL) ? window.CONFIG.API_URL : window.location.origin;
let _aiTopics = [];
let _generating = false;
let _loadingButtons = new Set(); // Her buton için ayrı loading state

// Global state for drafts modal
let _currentDrafts = [];
let _currentTopicId = null;
let _currentTopicName = '';
let _currentModuleType = '';

// Global state for drafts page
let _allPageDrafts = [];

function aiLog(msg, type = 'info', details = null) {
    const log = document.getElementById('aiLog');
    if (!log) return;

    // Boş log mesajını kaldır
    const placeholder = log.querySelector('[style*="text-align: center"]');
    if (placeholder) placeholder.remove();

    const config = {
        info: { color: '#60a5fa', bg: 'rgba(96, 165, 250, 0.1)', icon: 'ℹ️', label: 'INFO' },
        success: { color: '#34d399', bg: 'rgba(52, 211, 153, 0.1)', icon: '✅', label: 'OK' },
        error: { color: '#f87171', bg: 'rgba(248, 113, 113, 0.1)', icon: '❌', label: 'ERR' },
        warn: { color: '#fbbf24', bg: 'rgba(251, 191, 36, 0.1)', icon: '⚠️', label: 'WARN' },
        debug: { color: '#a78bfa', bg: 'rgba(167, 139, 250, 0.1)', icon: '🔍', label: 'DEBUG' },
        api: { color: '#f472b6', bg: 'rgba(244, 114, 182, 0.1)', icon: '📡', label: 'API' },
        ai: { color: '#22d3ee', bg: 'rgba(34, 211, 238, 0.1)', icon: '🤖', label: 'AI' }
    };

    const c = config[type] || config.info;
    const time = new Date().toLocaleTimeString('tr-TR', { hour12: false });
    const ms = new Date().getMilliseconds().toString().padStart(3, '0');

    const entry = document.createElement('div');
    entry.style.cssText = `
        color: ${c.color}; 
        margin: 4px 0; 
        padding: 6px 10px;
        background: ${c.bg};
        border-left: 3px solid ${c.color};
        border-radius: 0 4px 4px 0;
        font-family: 'JetBrains Mono', monospace;
        font-size: 0.75rem;
        line-height: 1.5;
    `;

    let html = `<span style="opacity: 0.6; font-size: 0.7rem;">[${time}.${ms}]</span> <b>${c.icon} [${c.label}]</b> ${msg}`;

    if (details) {
        const detailsStr = typeof details === 'object' ? JSON.stringify(details, null, 2) : details;
        html += `<div style="margin-top: 4px; padding-left: 20px; opacity: 0.8; white-space: pre-wrap; font-size: 0.7rem;">${detailsStr}</div>`;
    }

    entry.innerHTML = html;
    log.appendChild(entry);
    log.scrollTop = log.scrollHeight;

    // Console'a da yaz
    console.log(`[AI-${c.label}] ${msg}`, details || '');
}

window.clearAILog = function () {
    const log = document.getElementById('aiLog');
    if (log) log.innerHTML = '<div style="color: var(--text-muted);">AI üretim logu burada görünecek...</div>';
};

async function refreshTopics() {
    const startTime = performance.now();
    aiLog('═══════════════════════════════════════', 'info');
    aiLog('🔄 KONU LİSTESİ YÜKLEME BAŞLATILIYOR', 'info');
    aiLog('═══════════════════════════════════════', 'info');

    try {
        // API URL
        const url = `${API}/api/ai-content/topics?_=${Date.now()}`;
        aiLog(`📡 API Endpoint: ${url}`, 'api');
        aiLog(`⏱️  İstek zamanı: ${new Date().toISOString()}`, 'debug');

        // Fetch
        aiLog('📤 GET isteği gönderiliyor...', 'api');
        const res = await fetch(url);

        // HTTP Durumu
        const httpTime = performance.now();
        const httpDuration = (httpTime - startTime).toFixed(2);
        aiLog(`📥 HTTP Yanıt: ${res.status} ${res.statusText}`, res.ok ? 'success' : 'error');
        aiLog(`   ⏱️  Yanıt süresi: ${httpDuration}ms`, 'debug');
        aiLog(`   📋 Content-Type: ${res.headers.get('content-type') || 'N/A'}`, 'debug');

        if (!res.ok) {
            throw new Error(`HTTP ${res.status} - ${res.statusText}`);
        }

        // JSON Parse
        aiLog('🔍 JSON parse ediliyor...', 'debug');
        const data = await res.json();
        const parseTime = performance.now();
        const parseDuration = (parseTime - httpTime).toFixed(2);
        aiLog(`✅ JSON parse tamamlandı (${parseDuration}ms)`, 'success');

        // Veri analizi
        _aiTopics = data.topics || [];
        const topicCount = _aiTopics.length;

        aiLog('📊 VERİ ANALİZİ:', 'info');
        aiLog(`   📁 Toplam konu: ${topicCount}`, 'info');

        // Modül bazlı istatistikler
        let totalExplanations = 0;
        let totalStories = 0;
        let totalFlashcards = 0;
        let totalMatching = 0;
        let withContent = 0;

        _aiTopics.forEach(t => {
            const exp = t.status?.explanations || 0;
            const st = t.status?.stories || 0;
            const fl = t.status?.flashcards || 0;
            const ma = t.status?.matching_games || 0;
            const qu = t.status?.questions || 0;

            totalExplanations += exp;
            totalStories += st;
            totalFlashcards += fl;
            totalMatching += ma;

            if (exp > 0 || st > 0 || fl > 0 || ma > 0 || qu > 0) {
                withContent++;
            }
        });

        aiLog(`   📚 Toplam Anlatım: ${totalExplanations} bölüm`, 'info');
        aiLog(`   📖 Toplam Hikaye: ${totalStories} hikaye`, 'info');
        aiLog(`   🃏 Toplam Flashcard: ${totalFlashcards} kart`, 'info');
        aiLog(`   🔗 Toplam Eşleştirme: ${totalMatching} çift`, 'info');
        aiLog(`   ✅ İçerikli konu: ${withContent}/${topicCount}`, 'success');

        // Render
        aiLog('🎨 Tablo render ediliyor...', 'info');
        const renderStart = performance.now();
        renderTopicTable();
        const renderEnd = performance.now();
        const renderDuration = (renderEnd - renderStart).toFixed(2);
        aiLog(`✅ Render tamamlandı (${renderDuration}ms)`, 'success');

        // Toplam süre
        const totalDuration = (renderEnd - startTime).toFixed(2);
        aiLog('═══════════════════════════════════════', 'success');
        aiLog(`✅ İŞLEM TAMAMLANDI - Toplam: ${totalDuration}ms`, 'success');
        aiLog('═══════════════════════════════════════', 'success');

    } catch (e) {
        console.error('Topic refresh error:', e);
        aiLog('═══════════════════════════════════════', 'error');
        aiLog(`❌ YÜKLEME HATASI: ${e.message}`, 'error');
        aiLog(`   💡 İpucu: Sunucu çalışıyor mu? (${API})`, 'warn');
        aiLog(`   🔧 Çözüm: Sayfayı yenileyin (F5)`, 'warn');
        aiLog('═══════════════════════════════════════', 'error');
    }

    // Productivity kategorilerini de yükle (KPSS topic'lerinden bağımsız)
    refreshProductivityCategories().catch(e => console.error('Productivity refresh:', e));
}

/// Productivity (Verimlilik) — Flutter StudyTechnique kategorileri
async function refreshProductivityCategories() {
    const tbody = document.getElementById('productivityCategoriesBody');
    if (!tbody) return;

    try {
        const res = await fetch(`${API}/api/ai-content/productivity-categories?_=${Date.now()}`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        console.log(data);
        const categories = data.categories || [];

        if (categories.length === 0) {
            tbody.innerHTML = '<tr><td colspan="4" style="text-align:center;padding:1.5rem;color:#334155">Kategori bulunamadı</td></tr>';
            return;
        }

        tbody.innerHTML = categories.map(c => {
            const count = c.status?.productivity || 0;
            const drafts = c.drafts || 0;
            const btnId = `btn-prod-${c.id}`;

            const delBtn = count > 0
                ? `<button onclick="deleteModuleContent('${c.id}', '${c.name.replace(/'/g, "\\'")}', 'productivity')"
                    style="background:transparent;border:none;color:#ef4444;cursor:pointer;font-size:0.75rem;padding:0;margin-left:0.3rem"
                    title="Sil">×</button>` : '';

            return `<tr style="border-bottom:1px solid var(--border)">
                <td style="padding:0.5rem 0.75rem;font-weight:500;font-size:0.82rem">
                    <div style="color:#e2e8f0">${c.name}</div>
                    <div style="font-size:0.65rem;color:#64748b;font-family:monospace">${c.id}</div>
                </td>
                <td style="text-align:center;padding:0.5rem">
                    <span style="background:${count > 0 ? '#10b981' : '#374151'};color:#fff;padding:0.15rem 0.45rem;border-radius:4px;font-size:0.72rem;font-weight:600">${count}</span>
                    ${delBtn}
                </td>
                <td style="text-align:center;padding:0.5rem">
                    ${drafts > 0
                    ? `<button onclick="showDraftsModal('${c.id}','${c.name.replace(/'/g, "\\'")}','productivity')" style="background:#f59e0b;border:none;color:#fff;padding:0.2rem 0.5rem;border-radius:4px;font-size:0.72rem;cursor:pointer">${drafts} 📝</button>`
                    : '<span style="color:#475569;font-size:0.72rem">—</span>'}
                </td>
                <td style="text-align:center;padding:0.5rem;background:rgba(99,102,241,0.05)">
                    <button id="${btnId}" onclick="generateWithAI('${c.id}','${c.name.replace(/'/g, "\\'")}','productivity',getGenCount('productivity'),'${btnId}')"
                        style="background:#6366f1;border:none;color:#fff;padding:0.3rem 0.65rem;border-radius:5px;font-size:0.8rem;cursor:pointer;font-weight:600"
                        title="Bu kategoride yeni teknik üret">⚡ Üret</button>
                </td>
            </tr>`;
        }).join('');
    } catch (e) {
        tbody.innerHTML = `<tr><td colspan="4" style="text-align:center;padding:1.5rem;color:#ef4444">❌ ${e.message}</td></tr>`;
    }
}
window.refreshProductivityCategories = refreshProductivityCategories;

// Global filtreleme değişkenleri
let _filteredTopics = [];
let _currentFilter = { search: '', module: '' };

function renderTopicTable() {
    // Sadece AI tablosunu güncelle (yeni yapı)
    const tbody = document.getElementById('aiTopicTableBody');
    const topicCountEl = document.getElementById('topicCount');
    if (!tbody) return;

    // Filtreleme uygula
    let topicsToShow = _aiTopics;

    if (_currentFilter.search) {
        const searchLower = _currentFilter.search.toLowerCase();
        topicsToShow = topicsToShow.filter(t => t.name.toLowerCase().includes(searchLower));
    }

    if (_currentFilter.module) {
        if (_currentFilter.module === 'any') {
            // Hiç içerik olmayanlar
            topicsToShow = topicsToShow.filter(t => {
                const total = (t.status?.explanations || 0) + (t.status?.stories || 0) +
                    (t.status?.flashcards || 0) + (t.status?.matching_games || 0) + (t.status?.questions || 0) + (t.status?.productivity || 0);
                return total === 0;
            });
        } else {
            // Belirli modülde içerik olmayanlar
            topicsToShow = topicsToShow.filter(t => !(t.status?.[_currentFilter.module] > 0));
        }
    }

    _filteredTopics = topicsToShow;

    // Konu sayısını güncelle
    if (topicCountEl) {
        const total = _aiTopics.length;
        const filtered = topicsToShow.length;
        topicCountEl.textContent = filtered === total ? `Tüm Konular (${total})` : `Gösterilen: ${filtered}/${total}`;
    }

    if (topicsToShow.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; padding: 2rem; color: var(--text-muted);">Filtreye uygun konu bulunamadı</td></tr>';
        return;
    }

    const rowsHtml = topicsToShow.map(t => {
        const explanations = t.status?.explanations || 0;
        const stories = t.status?.stories || 0;
        const flashcards = t.status?.flashcards || 0;
        const matching = t.status?.matching_games || 0;
        const questions = t.status?.questions || 0;

        // Silme butonu (sadece içerik varsa) - küçük
        const delBtn = (count, type) => count > 0
            ? `<button onclick="deleteModuleContent('${t.id}', '${t.name.replace(/'/g, "\\'")}', '${type}')" 
                style="background: transparent; border: none; color: #ef4444; cursor: pointer; font-size: 0.7rem; padding: 0; margin-left: 0.2rem;" 
                title="Sil">×</button>`
            : '';

        // Modül hücresi - sadece sayı ve silme butonu
        const cellContent = (count, type) => `
            <div style="display: flex; align-items: center; justify-content: center;">
                <span style="background: ${count > 0 ? '#10b981' : '#374151'}; color: white; 
                    padding: 0.1rem 0.3rem; border-radius: 3px; font-size: 0.7rem; font-weight: 600;">
                    ${count}
                </span>
                ${delBtn(count, type)}
            </div>
        `;

        // Üretim butonları - count tıklama anında inputs'tan okunur
        const genBtn = (type, icon) => {
            const btnId = `btn-${t.id}-${type}`;
            return `<button id="${btnId}" onclick="generateWithAI('${t.id}', '${t.name.replace(/'/g, "\\'")}', '${type}', getGenCount('${type}'), '${btnId}')"
                style="background: #6366f1; border: none; color: white; cursor: pointer;
                font-size: 0.75rem; padding: 0.25rem 0.4rem; border-radius: 4px; margin: 0 0.1rem;
                transition: all 0.2s; position: relative; overflow: hidden;"
                onmousedown="this.style.transform='scale(0.95)'; this.style.background='#4f46e5';"
                onmouseup="this.style.transform='scale(1)'; this.style.background='#6366f1';"
                onmouseleave="this.style.transform='scale(1)'; this.style.background='#6366f1';"
                title="Üret (yukarıdaki sayı kadar)">${icon}</button>`;
        };

        const explanationsBtns = genBtn('explanations', '📚');
        const storiesBtns = genBtn('stories', '📖');
        const flashcardsBtns = genBtn('flashcards', '🃏');
        const matchingBtns = genBtn('matching_games', '🔗');
        const questionsBtns = genBtn('questions', '❓');
        // ⚡ Productivity butonu buradan kaldırıldı — KPSS topic'leri Flutter
        // StudyTechnique kategorileriyle eşleşmediği için ayrı panelde (⚡ Verimlilik Kategorileri) üretiliyor.

        return `<tr style="border-bottom: 1px solid var(--border);">
            <td style="padding: 0.4rem 0.5rem; font-weight: 500; font-size: 0.8rem; vertical-align: middle;">${t.name}</td>
            <td style="text-align: center; padding: 0.4rem; vertical-align: middle;">${cellContent(explanations, 'explanations')}</td>
            <td style="text-align: center; padding: 0.4rem; vertical-align: middle;">${cellContent(stories, 'stories')}</td>
            <td style="text-align: center; padding: 0.4rem; vertical-align: middle;">${cellContent(flashcards, 'flashcards')}</td>
            <td style="text-align: center; padding: 0.4rem; vertical-align: middle;">${cellContent(matching, 'matching_games')}</td>
            <td style="text-align: center; padding: 0.4rem; vertical-align: middle;">${cellContent(questions, 'questions')}</td>
            <td style="text-align: center; padding: 0.4rem; background: rgba(99, 102, 241, 0.05); vertical-align: middle;">
                <div style="display: flex; flex-wrap: wrap; justify-content: center; align-items: center; gap: 0.15rem;">
                    ${explanationsBtns}
                    ${storiesBtns}
                    ${flashcardsBtns}
                    ${matchingBtns}
                    ${questionsBtns}
                </div>
            </td>
        </tr>`;
    }).join('');

    tbody.innerHTML = rowsHtml;
}

// Filtreleme fonksiyonu
window.filterTopics = function () {
    const searchInput = document.getElementById('topicSearch');
    const moduleSelect = document.getElementById('topicModuleFilter');

    _currentFilter = {
        search: searchInput ? searchInput.value : '',
        module: moduleSelect ? moduleSelect.value : ''
    };

    renderTopicTable();

    aiLog(`🔍 Filtreleme: "${_currentFilter.search}" | Modül: ${_currentFilter.module || 'Tümü'}`, 'debug');
};

window.deleteModuleContent = async function (topicId, topicName, moduleType) {
    const moduleNames = {
        'explanations': '📚 Konu Anlatımı',
        'stories': '📖 Hikaye',
        'flashcards': '🃏 Flashcard',
        'matching_games': '🔗 Eşleştirme',
        'questions': '❓ Sorular',
        'productivity': '⚡ Verimlilik'
    };
    const moduleLabel = moduleNames[moduleType] || moduleType;

    if (!confirm(`⚠️ SİLME ONAYI\n\nKonu: "${topicName}"\nModül: ${moduleLabel}\n\nBu içerik KALICI olarak silinecek!\n\nDevam etmek istiyor musunuz?`)) {
        aiLog(`⏹️ "${topicName}" silme işlemi iptal edildi`, 'warn');
        return;
    }

    aiLog(`🗑️ [${topicName}] ${moduleLabel} siliniyor...`, 'info');
    aiLog(`   📡 API isteği gönderiliyor...`, 'info');

    try {
        const res = await fetch(`${API}/api/ai-content/delete-published`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ moduleType, topicId, topicName }),
        });

        aiLog(`   📥 HTTP ${res.status} ${res.statusText}`, res.ok ? 'success' : 'error');

        // Yanıt içeriğini kontrol et
        const rawText = await res.text();
        if (!rawText || !rawText.trim()) {
            throw new Error('Sunucu boş yanıt döndürdü. Sunucu loglarını kontrol edin.');
        }

        let data;
        try {
            data = JSON.parse(rawText);
        } catch (parseErr) {
            console.error('JSON parse hatası:', rawText.substring(0, 200));
            throw new Error(`Sunucu yanıtı JSON formatında değil: ${parseErr.message}`);
        }

        if (!data.success) {
            throw new Error(data.error || 'Bilinmeyen hata');
        }

        aiLog(`✅ [${topicName}] ${moduleLabel} başarıyla silindi:`, 'success');
        aiLog(`   📊 Silinen: ${data.published || 0} yayınlanmış + ${data.drafts || 0} taslak = ${data.deleted} toplam`, 'success');
        aiLog(`   🔄 Liste yenileniyor...`, 'info');

        await refreshTopics();

        aiLog(`✅ İşlem tamamlandı`, 'success');
    } catch (e) {
        aiLog(`❌ [${topicName}] ${moduleLabel} silme hatası:`, 'error');
        aiLog(`   ⚠️ ${e.message}`, 'error');
        aiLog(`   💡 Hata detayı: Console'a bakınız (F12)`, 'warn');
        console.error('deleteModuleContent Error:', e);
    }
};

// ═══════════════════════════════════════════════════════════════════════════
// AI CONTENT GENERATION SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

// Model seçimi için kart tıklama fonksiyonu
window.selectModel = function (modelId) {
    // Gizli select'i güncelle
    const select = document.getElementById('aiModel');
    if (select) {
        select.value = modelId;
    }

    // Tüm kartlardan selected class'ını kaldır
    document.querySelectorAll('.model-card').forEach(card => {
        card.classList.remove('selected');
        card.style.borderColor = 'var(--border)';
        card.style.background = 'var(--bg)';
        card.style.boxShadow = 'none';
    });

    // Seçili karta stil uygula
    const selectedCard = document.querySelector(`[data-model="${modelId}"]`);
    if (selectedCard) {
        selectedCard.classList.add('selected');
        selectedCard.style.borderColor = '#6366f1';
        selectedCard.style.background = 'rgba(99, 102, 241, 0.1)';
        selectedCard.style.boxShadow = '0 0 0 2px rgba(99, 102, 241, 0.3)';
    }

    // Model ismini ve maliyeti güncelle (2026 Nisan)
    const modelNames = {
        // TOP TIER
        'deepseek/deepseek-v3.2': 'DeepSeek V3.2',
        'google/gemini-3-flash-preview': 'Gemini 3 Flash',
        'minimax/minimax-m2.5': 'MiniMax M2.5',
        'minimax/minimax-m2.7': 'MiniMax M2.7',
        'google/gemini-2.5-flash': 'Gemini 2.5 Flash',
        'x-ai/grok-4.1-fast': 'Grok 4.1 Fast',
        // FREE
        'nvidia/nemotron-3-super-120b-a12b:free': 'Nemotron 3 Super',
        // BUDGET
        'google/gemini-2.5-flash-lite': 'Gemini 2.5 Flash Lite',
        'google/gemini-3.1-flash-lite-preview': 'Gemini 3.1 Flash Lite',
        'moonshotai/kimi-k2.5': 'Kimi K2.5',
        'openai/gpt-5-nano': 'GPT-5 Nano',
        'openai/gpt-4o-mini': 'GPT-4o Mini',
        // PREMIUM
        'openai/gpt-5.2': 'GPT-5.2',
        'google/gemini-3.1-pro-preview': 'Gemini 3.1 Pro',
        'anthropic/claude-haiku-4.5': 'Claude Haiku 4.5',
        'anthropic/claude-sonnet-4.6': 'Claude Sonnet 4.6',
    };

    // Ortalama $/M token (input+output için tahmini)
    const modelPrices = {
        'deepseek/deepseek-v3.2': 0.32,
        'google/gemini-3-flash-preview': 1.75,
        'minimax/minimax-m2.5': 0.55,
        'minimax/minimax-m2.7': 0.75,
        'google/gemini-2.5-flash': 1.40,
        'x-ai/grok-4.1-fast': 0.35,
        'nvidia/nemotron-3-super-120b-a12b:free': 0,
        'google/gemini-2.5-flash-lite': 0.25,
        'google/gemini-3.1-flash-lite-preview': 0.88,
        'moonshotai/kimi-k2.5': 1.05,
        'openai/gpt-5-nano': 0.23,
        'openai/gpt-4o-mini': 0.38,
        'openai/gpt-5.2': 7.88,
        'google/gemini-3.1-pro-preview': 7.00,
        'anthropic/claude-haiku-4.5': 3.00,
        'anthropic/claude-sonnet-4.6': 9.00,
    };

    const modelNameEl = document.getElementById('currentModelName');
    const costEl = document.getElementById('estimatedCost');

    if (modelNameEl) {
        modelNameEl.textContent = modelNames[modelId] || modelId;
    }

    updateCostDisplay();
    aiLog(`🤖 Model seçildi: ${modelNames[modelId] || modelId}`, 'info');
};

// Üretim başına adet - inputs'tan oku (tıklama anında)
window.getGenCount = function (type) {
    const ids = { explanations: 'countExplanations', stories: 'countStories', flashcards: 'countFlashcards', matching_games: 'countMatching', questions: 'countQuestions', productivity: 'countProductivity' };
    const defaults = { explanations: 5, stories: 5, flashcards: 10, matching_games: 5, questions: 20, productivity: 5 };
    const el = document.getElementById(ids[type]);
    return Math.max(1, parseInt(el?.value) || defaults[type] || 5);
};

// API çağrısı ve maliyet tahminini güncelle
window.updateCostDisplay = function () {
    const select = document.getElementById('aiModel');
    const model = select?.value || 'google/gemini-2.5-flash';
    const modelPrices = {
        'deepseek/deepseek-v3.2': 0.32,
        'google/gemini-3-flash-preview': 1.75,
        'google/gemini-2.5-flash': 1.40,
        'x-ai/grok-4.1-fast': 0.35,
        'minimax/minimax-m2.5': 0.55,
        'minimax/minimax-m2.7': 0.75,
        'moonshotai/kimi-k2.5': 1.05,
        'nvidia/nemotron-3-super-120b-a12b:free': 0,
        'google/gemini-2.5-flash-lite': 0.25,
        'google/gemini-3.1-flash-lite-preview': 0.88,
        'openai/gpt-5-nano': 0.23,
        'openai/gpt-4o-mini': 0.38,
        'anthropic/claude-haiku-4.5': 3.00,
        'google/gemini-3.1-pro-preview': 7.00,
        'openai/gpt-5.2': 7.88,
        'anthropic/claude-sonnet-4.6': 9.00,
    };
    const price = modelPrices[model] || 0.32;

    const counts = {
        explanations: getGenCount('explanations'),
        stories: getGenCount('stories'),
        flashcards: getGenCount('flashcards'),
        matching_games: getGenCount('matching_games'),
        questions: parseInt(document.getElementById('countQuestions')?.value) || 0
    };

    // Her modül: 1 syllabus + N içerik = N+1 API çağrısı
    const totalApiPerTopic = Object.values(counts).reduce((s, c) => s + c + 1, 0);
    // Ortalama ~1500 token/çağrı (input+output)
    const totalTokens = totalApiPerTopic * 1500;
    const estimatedCost = (price * totalTokens / 1_000_000).toFixed(3);

    const costEl = document.getElementById('estimatedCost');
    const apiCountEl = document.getElementById('singleTopicApiCount');
    if (costEl) costEl.textContent = `~$${estimatedCost} · ${totalApiPerTopic} API`;
    if (apiCountEl) {
        apiCountEl.textContent = totalApiPerTopic;
        apiCountEl.style.color = totalApiPerTopic > 50 ? '#ef4444' : totalApiPerTopic > 20 ? '#f59e0b' : '#34d399';
    }
};

window.generateWithAI = async function (topicId, topicName, moduleType, count = 30, btnId = null) {
    // Bu buton zaten loading mi kontrol et (aynı anda çoklu üretim için buton bazlı lock)
    if (btnId && _loadingButtons.has(btnId)) {
        aiLog('⚠️ Bu konu için zaten üretim devam ediyor', 'warn');
        showToast('Bu konu için zaten üretim devam ediyor...', 'warning');
        return;
    }
    // Global lock sadece gerçekten gerekirse (eski kod uyumluluğu)
    if (!btnId && _generating) {
        aiLog('⚠️ Zaten bir üretim işlemi devam ediyor, lütfen bekleyin', 'warn');
        showToast('Zaten üretim devam ediyor...', 'warning');
        return;
    }

    const modelSelect = document.getElementById('aiModel');
    const model = modelSelect ? modelSelect.value : 'google/gemini-2.5-flash-lite';

    // Loading state takibi
    if (btnId) _loadingButtons.add(btnId);
    _generating = true;

    // Sayfa kapatma uyarısı
    const beforeUnloadHandler = (e) => {
        e.preventDefault();
        e.returnValue = 'YZ üretimi devam ediyor. Sayfayı kapatırsanız işlem yarım kalacak.';
        return e.returnValue;
    };
    window.addEventListener('beforeunload', beforeUnloadHandler);

    const btn = btnId ? document.getElementById(btnId) : null;
    const originalContent = btn ? btn.innerHTML : null;
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<span style="display:inline-block;animation:spin 1s linear infinite">⏳</span>';
        btn.style.cssText += ';background:#4f46e5;cursor:not-allowed;opacity:0.8';
    }

    const moduleNames = { explanations: '📚 Konu Anlatımı', stories: '📖 Hikaye', flashcards: '🃏 Flashcard', matching_games: '🔗 Eşleştirme', questions: '❓ Sorular', productivity: '⚡ Verimlilik' };
    const moduleLabel = moduleNames[moduleType] || moduleType;

    aiLog('═══════════════════════════════════════════', 'info');
    aiLog(`🤖 YZ ÜRETİM BAŞLATILIYOR`, 'info');
    aiLog(`   📋 Konu: ${topicName}`, 'info');
    aiLog(`   📦 Modül: ${moduleLabel}  🔢 Adet: ${count}`, 'info');
    aiLog(`   🤖 Model: ${model.split('/').pop()}`, 'info');
    aiLog('═══════════════════════════════════════════', 'info');

    const resetBtn = (icon, color, delay) => {
        if (!btn) return;
        btn.innerHTML = icon;
        btn.style.background = color;
        setTimeout(() => {
            btn.innerHTML = originalContent;
            btn.style.background = '#6366f1';
            btn.disabled = false;
            btn.style.cursor = 'pointer';
            btn.style.opacity = '1';
        }, delay);
    };

    try {
        const aiSettings = (typeof getAISettingsForAPI === 'function') ? getAISettingsForAPI() : {};

        aiLog(`📡 İş başlatılıyor...`, 'api');
        const startRes = await fetch(`${API}/api/ai-content/generate`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                moduleType, topicId, topicName, count, model,
                difficulty: aiSettings.difficulty || 'medium',
                enableQualityCheck: aiSettings.enableQualityCheck === true ? true : false,
                useReferenceQuestions: aiSettings.useReferenceQuestions === true,
                maxRetries: aiSettings.maxRetries || 2
            })
        });

        const startData = await startRes.json();
        if (!startData.success) throw new Error(startData.error || 'İş başlatılamadı');

        const jobId = startData.jobId;
        aiLog(`⚡ İş kuyruğa alındı (${jobId})`, 'success');
        aiLog(`⏳ Üretim arka planda devam ediyor, loglar canlı görünecek...`, 'info');

        // Polling: 2 saniyede bir job durumunu sorgula
        await _pollJobStatus(jobId, count);

        aiLog(`💡 Onaylamak için "Taslaklar" sayfasına gidin`, 'info');
        showToast(`${topicName} - ${count} ${moduleLabel} taslaklara kaydedildi!`, 'success');
        resetBtn('✅', '#10b981', 2000);

    } catch (e) {
        aiLog('═══════════════════════════════════════════', 'error');
        aiLog(`❌ HATA: ${e.message}`, 'error');
        aiLog('═══════════════════════════════════════════', 'error');
        console.error('AI Generation Error:', e);
        showToast('YZ üretim hatası: ' + e.message, 'error');
        resetBtn('❌', '#ef4444', 3000);
    } finally {
        if (btnId) _loadingButtons.delete(btnId);
        // Global lock sadece hiç loading buton kalmadıysa kaldır
        if (_loadingButtons.size === 0) {
            _generating = false;
        }
        window.removeEventListener('beforeunload', beforeUnloadHandler);
    }
};

// Job polling - 2 sn'de bir sorgular, logları canlı gösterir
async function _pollJobStatus(jobId, expectedCount) {
    let logOffset = 0;
    let lastProgress = -1;
    let pollCount = 0;
    const MAX_POLL_COUNT = 150; // 2 sn × 150 = 5 dakika timeout

    return new Promise((resolve, reject) => {
        // Global timeout - 5 dakika sonra otomatik iptal
        const timeoutId = setTimeout(() => {
            clearInterval(interval);
            reject(new Error('⏱️ Zaman aşımı: İşlem 5 dakika içinde tamamlanmadı. Sayfayı yenileyip tekrar deneyin.'));
        }, 300000);

        const interval = setInterval(async () => {
            try {
                pollCount++;
                const res = await fetch(`${API}/api/ai-content/job-status?jobId=${encodeURIComponent(jobId)}&since=${logOffset}`);
                if (!res.ok) { clearTimeout(timeoutId); clearInterval(interval); reject(new Error(`Job sorgu hatası: HTTP ${res.status}`)); return; }

                const data = await res.json();
                if (!data.success) { clearTimeout(timeoutId); clearInterval(interval); reject(new Error(data.error || 'Job sorgu hatası')); return; }

                // Yeni logları göster
                if (data.logs && data.logs.length > 0) {
                    data.logs.forEach(log => aiLog(log.message || String(log), log.type || 'info'));
                    logOffset = data.logOffset || logOffset + data.logs.length;
                }

                // İlerleme güncelle (sadece değişince)
                if (data.progress > lastProgress && data.total > 0) {
                    lastProgress = data.progress;
                    const pct = Math.round((data.progress / data.total) * 100);
                    aiLog(`📊 İlerleme: ${data.progress}/${data.total} bölüm (${pct}%)`, 'info');
                }

                if (data.status === 'done') {
                    clearTimeout(timeoutId);
                    clearInterval(interval);
                    aiLog(`✅ ${data.generated} bölüm tamamlandı! Toplam taslak: ${data.total_drafts}`, 'success');
                    resolve(data);
                } else if (data.status === 'error') {
                    clearTimeout(timeoutId);
                    clearInterval(interval);
                    reject(new Error(data.error || 'Üretim sırasında hata oluştu'));
                } else if (pollCount > MAX_POLL_COUNT) {
                    // Failsafe: çok fazla poll yapıldıysa timeout et
                    clearTimeout(timeoutId);
                    clearInterval(interval);
                    reject(new Error('⏱️ İşlem çok uzun sürdü. Lütfen sunucu loglarını kontrol edin.'));
                }
                // data.status === 'running' veya başka bir değerse devam et
            } catch (e) {
                clearTimeout(timeoutId);
                clearInterval(interval);
                reject(e);
            }
        }, 2000);
    });
}

async function generateExplanationsBatch(topicId, topicName, count) {
    aiLog(`📚 ${topicName} için ${count} bölüm anlatım üretiliyor...`, 'ai');

    for (let i = 1; i <= count; i++) {
        aiLog(`   📝 Bölüm ${i}/${count} üretiliyor...`, 'info');

        // Simülasyon - gerçek API entegrasyonu buraya gelecek
        await simulateAIRequest(2000);

        aiLog(`   ✅ Bölüm ${i} tamamlandı`, 'success');
    }

    aiLog(`📚 ${count} bölüm anlatım üretildi`, 'success');
}

async function generateStoriesBatch(topicId, topicName, count) {
    aiLog(`📖 ${topicName} için ${count} hikaye üretiliyor...`, 'ai');

    for (let i = 1; i <= count; i++) {
        aiLog(`   📜 Hikaye ${i}/${count} üretiliyor...`, 'info');
        await simulateAIRequest(1500);
        aiLog(`   ✅ Hikaye ${i} tamamlandı`, 'success');
    }

    aiLog(`📖 ${count} hikaye üretildi`, 'success');
}

async function generateFlashcardsBatch(topicId, topicName, count) {
    aiLog(`🃏 ${topicName} için ${count} flashcard üretiliyor...`, 'ai');

    for (let i = 1; i <= count; i++) {
        aiLog(`   🎴 Flashcard ${i}/${count} üretiliyor...`, 'info');
        await simulateAIRequest(800);
        aiLog(`   ✅ Flashcard ${i} tamamlandı`, 'success');
    }

    aiLog(`🃏 ${count} flashcard üretildi`, 'success');
}

async function generateMatchingBatch(topicId, topicName, count) {
    aiLog(`🔗 ${topicName} için ${count} eşleştirme çifti üretiliyor...`, 'ai');

    for (let i = 1; i <= count; i++) {
        aiLog(`   🔗 Eşleştirme ${i}/${count} üretiliyor...`, 'info');
        await simulateAIRequest(1000);
        aiLog(`   ✅ Eşleştirme ${i} tamamlandı`, 'success');
    }

    aiLog(`🔗 ${count} eşleştirme çifti üretildi`, 'success');
}

function simulateAIRequest(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// ═══════════════════════════════════════════════════════════════════════════
// DRAFTS & APPROVAL SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

window.showDraftsModal = async function (topicId, topicName, moduleType) {
    const moduleNames = {
        'explanations': '📚 Konu Anlatımı',
        'stories': '📖 Hikaye',
        'flashcards': '🃏 Flashcard',
        'matching_games': '🔗 Eşleştirme',
        'questions': '❓ Sorular',
        'productivity': '⚡ Verimlilik Teknikleri'
    };
    const moduleLabel = moduleNames[moduleType] || moduleType;

    aiLog(`📋 [${topicName}] ${moduleLabel} taslakları yükleniyor...`, 'info');

    try {
        const res = await fetch(`${API}/api/ai-content/drafts?topicId=${topicId}&moduleType=${moduleType}`);
        const data = await res.json();

        if (!data.success || !data.drafts || data.drafts.length === 0) {
            aiLog(`⚠️ [${topicName}] Henüz taslak yok. "🤖 Üret" butonuna tıklayın.`, 'warn');
            alert('Henüz taslak yok! 🤖 Üret butonuna tıklayarak içerik üretin.');
            return;
        }

        const drafts = data.drafts;
        _currentDrafts = drafts; // Global değişkene ata
        _currentTopicId = topicId;
        _currentTopicName = topicName;
        _currentModuleType = moduleType;

        aiLog(`✅ ${drafts.length} taslak yüklendi`, 'success');

        renderDraftsModal(drafts, topicId, topicName, moduleType, moduleLabel);

    } catch (e) {
        aiLog(`❌ [${topicName}] Taslak yükleme hatası: ${e.message}`, 'error');
        alert('Taslaklar yüklenirken hata oluştu!');
    }
};

function renderDraftsModal(drafts, topicId, topicName, moduleType, moduleLabel) {
    // Mevcut modalı kaldır
    const existingModal = document.getElementById('draftsModal');
    if (existingModal) existingModal.remove();

    const modal = document.createElement('div');
    modal.id = 'draftsModal';
    modal.style.cssText = `
        position: fixed; top: 0; left: 0; width: 100%; height: 100%;
        background: rgba(0,0,0,0.85); z-index: 10000;
        display: flex; align-items: center; justify-content: center;
        padding: 1rem; overflow: auto;
    `;

    const previewContent = (draft, index) => {
        if (moduleType === 'explanations') {
            const contentPreview = draft.content?.slice(0, 2).map(c => {
                if (c.type === 'heading') return `<b># ${c.text?.substring(0, 40)}</b>`;
                if (c.type === 'text') return c.text.substring(0, 60) + '...';
                return '';
            }).join('<br>') || 'İçerik yok';
            return `<div style="font-size: 0.75rem; color: #94a3b8; margin-top: 0.3rem; line-height: 1.4;">${contentPreview}</div>`;
        } else if (moduleType === 'stories') {
            return `<div style="font-size: 0.75rem; color: #94a3b8; margin-top: 0.3rem;">${draft.content?.substring(0, 100)}...</div>`;
        } else if (moduleType === 'flashcards') {
            const q = draft.front || draft.question || '';
            return `<div style="font-size: 0.75rem; color: #94a3b8; margin-top: 0.3rem;"><b>S:</b> ${q.substring(0, 60)}...</div>`;
        } else if (moduleType === 'questions') {
            return `<div style="font-size: 0.75rem; color: #94a3b8; margin-top: 0.3rem;">${draft.question?.substring(0, 100) || draft.q?.substring(0, 100) || ''}...</div>`;
        } else if (moduleType === 'productivity') {
            const shortDesc = draft.shortDescription || draft.fullDescription?.substring(0, 120) || '';
            const stepsCount = Array.isArray(draft.steps) ? draft.steps.length : 0;
            const tipsCount = Array.isArray(draft.tips) ? draft.tips.length : 0;
            const benefitsCount = Array.isArray(draft.benefits) ? draft.benefits.length : 0;
            return `<div style="font-size: 0.75rem; color: #94a3b8; margin-top: 0.3rem; line-height: 1.4;">
                ${shortDesc}${shortDesc.length >= 100 ? '...' : ''}
                <div style="margin-top: 0.25rem; display: flex; gap: 0.5rem; flex-wrap: wrap;">
                    <span style="background:#1e293b;padding:0.1rem 0.35rem;border-radius:3px;font-size:0.65rem">📋 ${stepsCount} adım</span>
                    <span style="background:#1e293b;padding:0.1rem 0.35rem;border-radius:3px;font-size:0.65rem">✨ ${benefitsCount} fayda</span>
                    <span style="background:#1e293b;padding:0.1rem 0.35rem;border-radius:3px;font-size:0.65rem">💡 ${tipsCount} ipucu</span>
                    ${draft.id ? `<span style="background:#0f172a;padding:0.1rem 0.35rem;border-radius:3px;font-size:0.6rem;font-family:monospace;color:#64748b">${draft.id}</span>` : ''}
                </div>
            </div>`;
        } else {
            return `<div style="font-size: 0.75rem; color: #94a3b8; margin-top: 0.3rem;">${draft.left || ''} ↔️ ${draft.right || ''}</div>`;
        }
    };

    modal.innerHTML = `
        <div style="background: #0f172a; border: 1px solid #334155; border-radius: 12px; max-width: 900px; width: 100%; max-height: 95vh; overflow: hidden; display: flex; flex-direction: column;">
            <div style="padding: 1.25rem; border-bottom: 1px solid #334155; background: #1e293b; display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <h2 style="margin: 0; color: #f8fafc; font-size: 1.1rem; display: flex; align-items: center; gap: 0.5rem;">
                        📋 ${topicName}
                        <span style="background: #6366f1; color: white; padding: 0.2rem 0.6rem; border-radius: 4px; font-size: 0.75rem;">${drafts.length}</span>
                    </h2>
                    <p style="margin: 0.3rem 0 0 0; color: #94a3b8; font-size: 0.8rem;">${moduleLabel} taslakları onay bekliyor</p>
                </div>
                <button onclick="closeDraftsModal()" style="background: transparent; border: none; color: #94a3b8; font-size: 1.5rem; cursor: pointer; padding: 0.5rem;">✕</button>
            </div>
            
            <div style="padding: 1rem; border-bottom: 1px solid #334155; background: #1e293b; display: flex; gap: 0.5rem; flex-wrap: wrap; align-items: center;">
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                    <input type="checkbox" id="selectAllDrafts" onchange="toggleSelectAllDrafts(this.checked)" style="width: 1.2rem; height: 1.2rem; cursor: pointer;">
                    <label for="selectAllDrafts" style="color: #e2e8f0; font-size: 0.85rem; cursor: pointer;">Tümünü Seç</label>
                </div>
                <div style="margin-left: auto; display: flex; gap: 0.5rem;">
                    <button onclick="approveSelectedDraftsBulk()" id="approveSelectedBtn" disabled
                        style="background: linear-gradient(135deg, #10b981, #059669); border: none; color: white; padding: 0.6rem 1.25rem; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 0.85rem; opacity: 0.5; transition: all 0.2s;">
                        ✓ Seçilenleri Onayla (<span id="selectedCount">0</span>)
                    </button>
                    <button onclick="deleteSelectedDraftsBulk()" id="deleteSelectedBtn" disabled
                        style="background: #ef4444; border: none; color: white; padding: 0.6rem 1.25rem; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 0.85rem; opacity: 0.5; transition: all 0.2s;">
                        🗑️ Seçilenleri Sil (<span id="deleteCount">0</span>)
                    </button>
                </div>
            </div>
            
            <div style="padding: 1rem; overflow-y: auto; flex: 1; max-height: 60vh;">
                <div style="display: flex; flex-direction: column; gap: 0.5rem;">
                    ${drafts.map((draft, index) => `
                        <div id="draftItem-${index}" style="background: #1e293b; border: 1px solid #334155; border-radius: 8px; padding: 0.75rem; transition: all 0.2s;" onmouseenter="this.style.borderColor='#475569'" onmouseleave="this.style.borderColor='#334155'">
                            <div style="display: flex; align-items: flex-start; gap: 0.75rem;">
                                <input type="checkbox" class="draft-checkbox" data-index="${index}" onchange="updateDraftSelection()" 
                                    style="width: 1.1rem; height: 1.1rem; cursor: pointer; margin-top: 0.2rem; flex-shrink: 0;">
                                
                                <div style="flex: 1; min-width: 0;">
                                    <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.25rem;">
                                        <span style="background: #6366f1; color: white; padding: 0.15rem 0.4rem; border-radius: 3px; font-size: 0.7rem; font-weight: 600;">#${index + 1}</span>
                                        <b style="color: #f8fafc; font-size: 0.85rem; white-space: normal; overflow: hidden; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; line-height: 1.3;">${getDraftTitle(draft, index)}</b>
                                    </div>
                                    ${previewContent(draft, index)}
                                </div>
                                
                                <div style="display: flex; gap: 0.3rem; flex-shrink: 0;">
                                    <button onclick="previewDraftDetail(${index})" title="Detaylı Görüntüle"
                                        style="background: #475569; border: none; color: white; padding: 0.35rem 0.5rem; border-radius: 4px; cursor: pointer; font-size: 0.7rem;">
                                        👁️
                                    </button>
                                    <button onclick="openInlineEditor(${index})" title="Düzenle"
                                        style="background: #f59e0b; border: none; color: white; padding: 0.35rem 0.5rem; border-radius: 4px; cursor: pointer; font-size: 0.7rem;">
                                        ✏️
                                    </button>
                                    <button onclick="approveSingleDraft('${topicId}', '${topicName.replace(/'/g, "\\'")}', '${moduleType}', ${index})" title="Onayla"
                                        style="background: #10b981; border: none; color: white; padding: 0.35rem 0.5rem; border-radius: 4px; cursor: pointer; font-size: 0.7rem; font-weight: 600;">
                                        ✓
                                    </button>
                                </div>
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
            
            <div style="padding: 1rem; border-top: 1px solid #334155; background: #1e293b; display: flex; justify-content: space-between; align-items: center;">
                <button onclick="approveAllDrafts('${topicId}', '${topicName.replace(/'/g, "\\'")}', '${moduleType}')" 
                    style="background: linear-gradient(135deg, #6366f1, #8b5cf6); border: none; color: white; padding: 0.75rem 1.5rem; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 0.85rem;">
                    ✅ Tümünü Onayla (${drafts.length})
                </button>
                <button onclick="closeDraftsModal()" 
                    style="background: transparent; border: 1px solid #475569; color: #94a3b8; padding: 0.75rem 1.5rem; border-radius: 6px; cursor: pointer; font-weight: 500;">
                    Kapat
                </button>
            </div>
        </div>
    `;

    document.body.appendChild(modal);
    aiLog(`📋 [${topicName}] Gelişmiş taslak modal açıldı (${drafts.length} taslak)`, 'success');
}

window.closeDraftsModal = function () {
    const modal = document.getElementById('draftsModal');
    if (modal) {
        modal.remove();
        aiLog('📋 Modal kapatıldı', 'debug');
    }
};

window.approveSingleDraft = async function (topicId, topicName, moduleType, index) {
    const moduleNames = {
        'explanations': '📚 Konu Anlatımı',
        'stories': '📖 Hikaye',
        'flashcards': '🃏 Flashcard',
        'matching_games': '🔗 Eşleştirme',
        'questions': '❓ Sorular'
    };
    const moduleLabel = moduleNames[moduleType] || moduleType;

    if (!confirm(`✅ ONAY\n\n"${topicName}" - ${moduleLabel}\nSadece #${index + 1} numaralı taslak onaylanacak.\n\nDevam?`)) return;

    aiLog(`✅ [${topicName}] #${index + 1} onaylanıyor...`, 'ai');

    try {
        const res = await fetch(`${API}/api/ai-content/approve-draft`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ moduleType, topicId, topicName, indices: [index] })
        });

        const data = await res.json();

        if (!data.success) throw new Error(data.error);

        aiLog(`✅ [${topicName}] #${index + 1} başarıyla yayınlandı!`, 'success');
        aiLog(`   📊 Toplam canlı içerik: ${data.total}`, 'success');

        closeDraftsModal();
        await refreshTopics();

        showToast(`${topicName} - #${index + 1} yayınlandı!`, 'success');
    } catch (e) {
        aiLog(`❌ [${topicName}] Onay hatası: ${e.message}`, 'error');
        alert('Onay hatası: ' + e.message);
    }
};

window.approveAllDrafts = async function (topicId, topicName, moduleType) {
    const moduleNames = {
        'explanations': '📚 Konu Anlatımı',
        'stories': '📖 Hikaye',
        'flashcards': '🃏 Flashcard',
        'matching_games': '🔗 Eşleştirme',
        'questions': '❓ Sorular'
    };
    const moduleLabel = moduleNames[moduleType] || moduleType;

    if (!confirm(`🚀 TOPLU ONAY\n\n"${topicName}" - ${moduleLabel}\nTÜM taslaklar onaylanacak ve canlıya alınacak!\n\nDevam?`)) return;

    aiLog(`🚀 [${topicName}] Tüm taslaklar onaylanıyor...`, 'ai');

    try {
        const res = await fetch(`${API}/api/ai-content/approve-draft`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ moduleType, topicId, topicName })
        });

        const data = await res.json();

        if (!data.success) throw new Error(data.error);

        aiLog(`🚀 [${topicName}] ${data.published} taslak başarıyla yayınlandı!`, 'success');
        aiLog(`   📊 Toplam canlı içerik: ${data.total}`, 'success');


        closeDraftsModal();
        await refreshTopics();

        showToast(`${topicName} - ${data.published} içerik yayınlandı!`, 'success');
    } catch (e) {
        aiLog(`❌ [${topicName}] Toplu onay hatası: ${e.message}`, 'error');
        alert('Onay hatası: ' + e.message);
    }
};

// ═══════════════════════════════════════════════════════════════════════════
// DRAFT MULTI-SELECT & BULK OPERATIONS
// ═══════════════════════════════════════════════════════════════════════════

window.toggleSelectAllDrafts = function (checked) {
    const checkboxes = document.querySelectorAll('.draft-checkbox');
    checkboxes.forEach(cb => cb.checked = checked);
    updateDraftSelection();
};

window.updateDraftSelection = function () {
    const checkboxes = document.querySelectorAll('.draft-checkbox:checked');
    const selectedCount = checkboxes.length;

    const approveBtn = document.getElementById('approveSelectedBtn');
    const deleteBtn = document.getElementById('deleteSelectedBtn');
    const countSpan = document.getElementById('selectedCount');
    const deleteCountSpan = document.getElementById('deleteCount');

    if (countSpan) countSpan.textContent = selectedCount;
    if (deleteCountSpan) deleteCountSpan.textContent = selectedCount;

    if (approveBtn) {
        approveBtn.disabled = selectedCount === 0;
        approveBtn.style.opacity = selectedCount === 0 ? '0.5' : '1';
    }
    if (deleteBtn) {
        deleteBtn.disabled = selectedCount === 0;
        deleteBtn.style.opacity = selectedCount === 0 ? '0.5' : '1';
    }
};

window.approveSelectedDraftsBulk = async function () {
    const checkboxes = document.querySelectorAll('.draft-checkbox:checked');
    if (checkboxes.length === 0) {
        alert('Lütfen en az bir taslak seçin!');
        return;
    }

    const indices = Array.from(checkboxes).map(cb => parseInt(cb.dataset.index));
    const moduleNames = {
        'explanations': '📚 Konu Anlatımı',
        'stories': '📖 Hikaye',
        'flashcards': '🃏 Flashcard',
        'matching_games': '🔗 Eşleştirme',
        'questions': '❓ Sorular'
    };
    const moduleLabel = moduleNames[_currentModuleType] || _currentModuleType;

    if (!confirm(`✓ TOPLU ONAY\n\n${_currentTopicName} - ${moduleLabel}\n${indices.length} taslak onaylanacak!\n\nDevam?`)) return;

    aiLog(`✓ [${_currentTopicName}] ${indices.length} taslak onaylanıyor...`, 'ai');

    try {
        const res = await fetch(`${API}/api/ai-content/approve-draft`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                moduleType: _currentModuleType,
                topicId: _currentTopicId,
                topicName: _currentTopicName,
                indices: indices
            })
        });

        const data = await res.json();

        if (!data.success) throw new Error(data.error);

        aiLog(`✓ [${_currentTopicName}] ${data.published} taslak onaylandı!`, 'success');
        closeDraftsModal();
        await refreshTopics();
        showToast(`${_currentTopicName} - ${data.published} içerik yayınlandı!`, 'success');
    } catch (e) {
        aiLog(`❌ Onay hatası: ${e.message}`, 'error');
        alert('Onay hatası: ' + e.message);
    }
};

window.deleteSelectedDraftsBulk = async function () {
    const checkboxes = document.querySelectorAll('.draft-checkbox:checked');
    if (checkboxes.length === 0) {
        alert('Lütfen en az bir taslak seçin!');
        return;
    }

    const indices = Array.from(checkboxes).map(cb => parseInt(cb.dataset.index));

    if (!confirm(`🗑️ TASLAK SİLME\n\n${indices.length} taslak kalıcı olarak SİLİNECEK!\n\nBu işlem geri alınamaz!\n\nDevam?`)) return;

    aiLog(`🗑️ ${_currentTopicName} - ${indices.length} taslak siliniyor...`, 'warn');

    // Taslakları filtrele
    const remainingDrafts = _currentDrafts.filter((_, i) => !indices.includes(i));

    try {
        // API'ye güncellenmiş taslağı gönder (sadece kalanlar)
        // TODO: API endpoint'i eklenecek
        aiLog(`🗑️ ${indices.length} taslak silindi`, 'success');
        renderDraftsModal(remainingDrafts, _currentTopicId, _currentTopicName, _currentModuleType,
            { 'explanations': '📚', 'stories': '📖', 'flashcards': '🃏', 'matching_games': '🔗', 'questions': '❓' }[_currentModuleType]);
        showToast(`${indices.length} taslak silindi`, 'success');
    } catch (e) {
        aiLog(`❌ Silme hatası: ${e.message}`, 'error');
    }
};

window.previewDraftDetail = function (index) {
    console.log('🔍 previewDraftDetail çağrıldı:', index);
    const draft = _currentDrafts[index];
    if (!draft) {
        console.log('❌ Draft bulunamadı:', index);
        return;
    }

    const moduleType = _currentModuleType;
    let content = '';

    if (moduleType === 'explanations') {
        content = draft.content?.map(c => {
            if (c.type === 'heading') return `<h3 style="color: #f8fafc; margin: 1rem 0 0.5rem 0;">${c.text}</h3>`;
            if (c.type === 'text') return `<p style="color: #94a3b8; line-height: 1.6; margin: 0.5rem 0;">${c.text}</p>`;
            if (c.type === 'bulletList') return `<ul style="color: #94a3b8; margin: 0.5rem 0; padding-left: 1.5rem;">${c.text?.split('\\n').map(l => `<li>${l}</li>`).join('')}</ul>`;
            return '';
        }).join('') || 'İçerik yok';
    } else if (moduleType === 'stories') {
        content = `<p style="color: #94a3b8; line-height: 1.8; white-space: pre-wrap;">${draft.content}</p>`;
    } else if (moduleType === 'flashcards') {
        content = `
            <div style="background: #1e293b; padding: 1rem; border-radius: 8px; margin-bottom: 1rem;">
                <div style="color: #6366f1; font-weight: 600; margin-bottom: 0.5rem;">SORU:</div>
                <div style="color: #f8fafc;">${draft.front}</div>
            </div>
            <div style="background: #0f172a; padding: 1rem; border-radius: 8px;">
                <div style="color: #10b981; font-weight: 600; margin-bottom: 0.5rem;">CEVAP:</div>
                <div style="color: #94a3b8;">${draft.back}</div>
            </div>
        `;
    } else if (moduleType === 'questions') {
        content = `
            <div style="background: #1e293b; padding: 1rem; border-radius: 8px; margin-bottom: 1rem;">
                <div style="color: #6366f1; font-weight: 600; margin-bottom: 0.5rem;">SORU:</div>
                <div style="color: #f8fafc;">${draft.question}</div>
            </div>
            <div style="background: #0f172a; padding: 1rem; border-radius: 8px;">
                <div style="color: #10b981; font-weight: 600; margin-bottom: 0.5rem;">CEVAP:</div>
                <div style="color: #94a3b8;">${draft.answer}</div>
            </div>
        `;
    } else {
        content = `
            <div style="display: flex; justify-content: center; align-items: center; gap: 2rem; padding: 2rem;">
                <div style="background: #1e293b; padding: 1.5rem; border-radius: 8px; text-align: center;">
                    <div style="color: #6366f1; font-size: 2rem; font-weight: 600;">${draft.left}</div>
                </div>
                <div style="color: #94a3b8; font-size: 1.5rem;">↔️</div>
                <div style="background: #1e293b; padding: 1.5rem; border-radius: 8px; text-align: center;">
                    <div style="color: #10b981; font-size: 2rem; font-weight: 600;">${draft.right}</div>
                </div>
            </div>
        `;
    }

    const modal = document.createElement('div');
    modal.id = 'draftPreviewModal';
    modal.style.cssText = `
        position: fixed; top: 0; left: 0; width: 100%; height: 100%;
        background: rgba(0,0,0,0.9); z-index: 10001;
        display: flex; align-items: center; justify-content: center;
        padding: 2rem; overflow: auto;
    `;

    modal.innerHTML = `
        <div style="background: #1e293b; border: 1px solid #334155; border-radius: 12px; max-width: 700px; width: 100%; max-height: 85vh; overflow: auto;">
            <div style="padding: 1.25rem; border-bottom: 1px solid #334155; display: flex; justify-content: space-between; align-items: center;">
                <h3 style="margin: 0; color: #f8fafc; font-size: 1.1rem;">👁️ Detaylı Önizleme - #${index + 1}</h3>
                <button onclick="closePreviewModal()" style="background: transparent; border: none; color: #94a3b8; font-size: 1.5rem; cursor: pointer;">✕</button>
            </div>
            <div style="padding: 1.5rem;">
                <h2 style="color: #f8fafc; margin: 0 0 1rem 0; font-size: 1.25rem;">${getDraftTitle(draft, index)}</h2>
                ${content}
            </div>
            <div style="padding: 1rem; border-top: 1px solid #334155; display: flex; gap: 0.75rem; justify-content: flex-end;">
                <button onclick="closePreviewModal()" style="background: #475569; border: none; color: white; padding: 0.6rem 1.25rem; border-radius: 6px; cursor: pointer;">Kapat</button>
                <button onclick="closePreviewModal(); approveSingleDraft('${_currentTopicId}', '${_currentTopicName.replace(/'/g, "\\'")}', '${moduleType}', ${index});" 
                    style="background: #10b981; border: none; color: white; padding: 0.6rem 1.25rem; border-radius: 6px; cursor: pointer; font-weight: 600;">✓ Onayla</button>
            </div>
        </div>
    `;

    document.body.appendChild(modal);
};

window.closePreviewModal = function () {
    const modal = document.getElementById('draftPreviewModal');
    if (modal) modal.remove();
};

// ═══════════════════════════════════════════════════════════════════════════
// INLINE EDITOR (WYSIWYG) FOR DRAFTS
// ═══════════════════════════════════════════════════════════════════════════

window.openInlineEditor = function (index) {
    console.log('✏️ openInlineEditor çağrıldı:', index);
    const draft = _currentDrafts[index];
    if (!draft) {
        console.log('❌ Draft bulunamadı:', index);
        return;
    }

    const moduleType = _currentModuleType;
    let editorContent = '';

    if (moduleType === 'explanations') {
        editorContent = `
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">Başlık</label>
                <input type="text" id="editTitle-${index}" value="${draft.title || ''}" 
                    style="width: 100%; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px; color: #f8fafc; font-size: 1rem;">
            </div>
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">İçerik Blokları (Her satır bir blok)</label>
                <div id="contentBlocks-${index}">
                    ${(draft.content || []).map((block, bi) => `
                        <div class="content-block" data-index="${bi}" style="margin-bottom: 0.75rem; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px;">
                            <div style="display: flex; gap: 0.5rem; margin-bottom: 0.5rem;">
                                <select class="block-type" style="padding: 0.3rem 0.5rem; background: #0f172a; border: 1px solid #334155; border-radius: 4px; color: #e2e8f0; font-size: 0.8rem;">
                                    <option value="text" ${block.type === 'text' ? 'selected' : ''}>Metin</option>
                                    <option value="heading" ${block.type === 'heading' ? 'selected' : ''}>Başlık</option>
                                    <option value="bulletList" ${block.type === 'bulletList' ? 'selected' : ''}>Liste</option>
                                    <option value="warning" ${block.type === 'warning' ? 'selected' : ''}>Uyarı</option>
                                    <option value="highlighted" ${block.type === 'highlighted' ? 'selected' : ''}>Vurgu</option>
                                </select>
                                <button onclick="this.closest('.content-block').remove()" style="padding: 0.3rem 0.5rem; background: #ef4444; border: none; border-radius: 4px; color: white; cursor: pointer; font-size: 0.8rem;">Sil</button>
                            </div>
                            <textarea class="block-content" rows="3" style="width: 100%; padding: 0.5rem; background: #0f172a; border: 1px solid #334155; border-radius: 4px; color: #e2e8f0; font-size: 0.85rem; resize: vertical;">${block.text || ''}</textarea>
                        </div>
                    `).join('')}
                </div>
                <button onclick="addContentBlock(${index})" style="margin-top: 0.5rem; padding: 0.5rem 1rem; background: #6366f1; border: none; border-radius: 6px; color: white; cursor: pointer; font-size: 0.85rem;">+ Yeni Blok Ekle</button>
            </div>
        `;
    } else if (moduleType === 'stories') {
        editorContent = `
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">Başlık</label>
                <input type="text" id="editTitle-${index}" value="${draft.title || ''}" 
                    style="width: 100%; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px; color: #f8fafc; font-size: 1rem;">
            </div>
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">Hikaye İçeriği</label>
                <textarea id="editContent-${index}" rows="10" style="width: 100%; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px; color: #e2e8f0; font-size: 0.9rem; line-height: 1.6; resize: vertical;">${draft.content || ''}</textarea>
            </div>
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">Anahtar Noktalar (virgülle ayırın)</label>
                <input type="text" id="editKeyPoints-${index}" value="${(draft.key_points || []).join(', ')}" 
                    style="width: 100%; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px; color: #e2e8f0; font-size: 0.9rem;">
            </div>
        `;
    } else if (moduleType === 'flashcards') {
        editorContent = `
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">Soru (Ön Yüz)</label>
                <textarea id="editFront-${index}" rows="3" style="width: 100%; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px; color: #f8fafc; font-size: 0.9rem; resize: vertical;">${draft.front || ''}</textarea>
            </div>
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">Cevap (Arka Yüz)</label>
                <textarea id="editBack-${index}" rows="5" style="width: 100%; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px; color: #e2e8f0; font-size: 0.9rem; resize: vertical;">${draft.back || ''}</textarea>
            </div>
        `;
    } else if (moduleType === 'questions') {
        // Soru alanları: q (soru), o (şıklar array), a (doğru cevap index), e (açıklama)
        const opts = (draft.o || []).map((opt, i) =>
            `<div style="display:flex;gap:0.5rem;margin-bottom:0.5rem;">
                <input type="radio" name="editCorrect-${index}" value="${i}" ${i === draft.a ? 'checked' : ''} style="margin-top:0.3rem;">
                <input type="text" id="editOption-${index}-${i}" value="${opt || ''}" placeholder="${['A', 'B', 'C', 'D', 'E'][i]} şıkkı" 
                    style="flex:1;padding:0.5rem;background:#1e293b;border:1px solid #334155;border-radius:4px;color:#f8fafc;">
            </div>`
        ).join('');
        editorContent = `
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">Soru Metni</label>
                <textarea id="editQuestion-${index}" rows="3" style="width: 100%; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px; color: #f8fafc; font-size: 0.9rem; resize: vertical;">${draft.q || draft.question || ''}</textarea>
            </div>
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">Şıklar (Doğru olanı seç)</label>
                ${opts}
            </div>
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">Açıklama (e)</label>
                <textarea id="editExplanation-${index}" rows="3" style="width: 100%; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px; color: #e2e8f0; font-size: 0.9rem; resize: vertical;">${draft.e || ''}</textarea>
            </div>
        `;
    } else if (moduleType === 'productivity') {
        // Verimlilik alanları: title, content, tips (array), steps (array)
        const tips = (draft.tips || []).map((tip, i) =>
            `<input type="text" id="editTip-${index}-${i}" value="${tip || ''}" placeholder="İpucu ${i + 1}" 
                style="width:100%;padding:0.5rem;background:#1e293b;border:1px solid #334155;border-radius:4px;color:#f8fafc;margin-bottom:0.5rem;">`
        ).join('');
        const steps = (draft.steps || []).map((step, i) =>
            `<input type="text" id="editStep-${index}-${i}" value="${step || ''}" placeholder="Adım ${i + 1}" 
                style="width:100%;padding:0.5rem;background:#1e293b;border:1px solid #334155;border-radius:4px;color:#f8fafc;margin-bottom:0.5rem;">`
        ).join('');
        editorContent = `
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">Başlık</label>
                <input type="text" id="editTitle-${index}" value="${draft.title || ''}" 
                    style="width: 100%; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px; color: #f8fafc; font-size: 1rem;">
            </div>
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">İçerik</label>
                <textarea id="editContent-${index}" rows="5" style="width: 100%; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px; color: #e2e8f0; font-size: 0.9rem; resize: vertical;">${draft.content || ''}</textarea>
            </div>
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">İpuçları</label>
                ${tips}
            </div>
            <div style="margin-bottom: 1rem;">
                <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">Adımlar</label>
                ${steps}
            </div>
        `;
    } else {
        editorContent = `
            <div style="display: flex; gap: 1rem; margin-bottom: 1rem;">
                <div style="flex: 1;">
                    <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">Sol Taraf</label>
                    <input type="text" id="editLeft-${index}" value="${draft.left || ''}" 
                        style="width: 100%; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px; color: #f8fafc; font-size: 1rem;">
                </div>
                <div style="flex: 1;">
                    <label style="display: block; color: #94a3b8; font-size: 0.8rem; margin-bottom: 0.5rem;">Sağ Taraf</label>
                    <input type="text" id="editRight-${index}" value="${draft.right || ''}" 
                        style="width: 100%; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px; color: #f8fafc; font-size: 1rem;">
                </div>
            </div>
        `;
    }

    const modal = document.createElement('div');
    modal.id = 'inlineEditorModal';
    modal.style.cssText = `
        position: fixed; top: 0; left: 0; width: 100%; height: 100%;
        background: rgba(0,0,0,0.9); z-index: 10002;
        display: flex; align-items: center; justify-content: center;
        padding: 2rem; overflow: auto;
    `;

    modal.innerHTML = `
        <div style="background: #0f172a; border: 1px solid #334155; border-radius: 12px; max-width: 800px; width: 100%; max-height: 90vh; overflow: auto;">
            <div style="padding: 1.25rem; border-bottom: 1px solid #334155; background: #1e293b;">
                <h3 style="margin: 0; color: #f8fafc; font-size: 1.1rem;">✏️ Taslak Düzenle - #${index + 1}</h3>
            </div>
            <div style="padding: 1.5rem;">
                ${editorContent}
            </div>
            <div style="padding: 1rem; border-top: 1px solid #334155; background: #1e293b; display: flex; gap: 0.75rem; justify-content: flex-end;">
                <button onclick="closeInlineEditor()" style="padding: 0.6rem 1.25rem; background: transparent; border: 1px solid #475569; border-radius: 6px; color: #94a3b8; cursor: pointer;">İptal</button>
                <button onclick="saveDraftChanges(${index})" style="padding: 0.6rem 1.5rem; background: #10b981; border: none; border-radius: 6px; color: white; cursor: pointer; font-weight: 600;">💾 Kaydet</button>
            </div>
        </div>
    `;

    document.body.appendChild(modal);
};

window.closeInlineEditor = function () {
    const modal = document.getElementById('inlineEditorModal');
    if (modal) modal.remove();
};

window.addContentBlock = function (draftIndex) {
    const container = document.getElementById(`contentBlocks-${draftIndex}`);
    const blockCount = container.querySelectorAll('.content-block').length;

    const newBlock = document.createElement('div');
    newBlock.className = 'content-block';
    newBlock.dataset.index = blockCount;
    newBlock.style.cssText = 'margin-bottom: 0.75rem; padding: 0.75rem; background: #1e293b; border: 1px solid #334155; border-radius: 6px;';

    newBlock.innerHTML = `
        <div style="display: flex; gap: 0.5rem; margin-bottom: 0.5rem;">
            <select class="block-type" style="padding: 0.3rem 0.5rem; background: #0f172a; border: 1px solid #334155; border-radius: 4px; color: #e2e8f0; font-size: 0.8rem;">
                <option value="text" selected>Metin</option>
                <option value="heading">Başlık</option>
                <option value="bulletList">Liste</option>
                <option value="warning">Uyarı</option>
                <option value="highlighted">Vurgu</option>
            </select>
            <button onclick="this.closest('.content-block').remove()" style="padding: 0.3rem 0.5rem; background: #ef4444; border: none; border-radius: 4px; color: white; cursor: pointer; font-size: 0.8rem;">Sil</button>
        </div>
        <textarea class="block-content" rows="3" style="width: 100%; padding: 0.5rem; background: #0f172a; border: 1px solid #334155; border-radius: 4px; color: #e2e8f0; font-size: 0.85rem; resize: vertical;" placeholder="İçerik..."> </textarea>
    `;

    container.appendChild(newBlock);
};

window.saveDraftChanges = function (index) {
    const moduleType = _currentModuleType;
    const draft = _currentDrafts[index];

    if (moduleType === 'explanations') {
        draft.title = document.getElementById(`editTitle-${index}`).value;

        // Content bloklarını topla
        const blocks = [];
        document.querySelectorAll(`#contentBlocks-${index} .content-block`).forEach(block => {
            const type = block.querySelector('.block-type').value;
            const text = block.querySelector('.block-content').value;
            if (text.trim()) {
                blocks.push({ type, text });
            }
        });
        draft.content = blocks;

    } else if (moduleType === 'stories') {
        draft.title = document.getElementById(`editTitle-${index}`).value;
        draft.content = document.getElementById(`editContent-${index}`).value;
        draft.key_points = document.getElementById(`editKeyPoints-${index}`).value.split(',').map(s => s.trim()).filter(s => s);

    } else if (moduleType === 'flashcards') {
        draft.front = document.getElementById(`editFront-${index}`).value;
        draft.back = document.getElementById(`editBack-${index}`).value;

    } else if (moduleType === 'questions') {
        // Soru alanlarını doğru yapıda kaydet: q, o, a, e
        draft.q = document.getElementById(`editQuestion-${index}`).value;
        draft.e = document.getElementById(`editExplanation-${index}`).value;

        // Şıkları topla
        draft.o = [];
        for (let i = 0; i < 5; i++) {
            const optEl = document.getElementById(`editOption-${index}-${i}`);
            if (optEl) draft.o.push(optEl.value);
        }

        // Doğru cevabı al (radio button)
        const correctRadio = document.querySelector(`input[name="editCorrect-${index}"]:checked`);
        draft.a = correctRadio ? parseInt(correctRadio.value) : 0;

    } else if (moduleType === 'productivity') {
        // Verimlilik alanlarını kaydet: title, content, tips, steps
        draft.title = document.getElementById(`editTitle-${index}`).value;
        draft.content = document.getElementById(`editContent-${index}`).value;

        // İpuçlarını topla
        draft.tips = [];
        for (let i = 0; i < 5; i++) {
            const tipEl = document.getElementById(`editTip-${index}-${i}`);
            if (tipEl && tipEl.value.trim()) draft.tips.push(tipEl.value.trim());
        }

        // Adımları topla
        draft.steps = [];
        for (let i = 0; i < 5; i++) {
            const stepEl = document.getElementById(`editStep-${index}-${i}`);
            if (stepEl && stepEl.value.trim()) draft.steps.push(stepEl.value.trim());
        }

    } else {
        draft.left = document.getElementById(`editLeft-${index}`).value;
        draft.right = document.getElementById(`editRight-${index}`).value;
    }

    // Değişiklikleri kaydet
    _currentDrafts[index] = draft;

    // Modalı kapat ve listeyi yenile
    closeInlineEditor();

    // Taslak modalını yeniden render et
    const moduleNames = { 'explanations': '📚', 'stories': '📖', 'flashcards': '🃏', 'matching_games': '🔗', 'questions': '❓', 'productivity': '⚡' };
    renderDraftsModal(_currentDrafts, _currentTopicId, _currentTopicName, _currentModuleType, moduleNames[_currentModuleType]);

    aiLog(`✏️ Taslak #${index + 1} düzenlendi ve kaydedildi`, 'success');
    showToast(`Taslak #${index + 1} güncellendi!`, 'success');
};

// ═══════════════════════════════════════════════════════════════════════════
// AI SETTINGS (Prompt Editor)
// ═══════════════════════════════════════════════════════════════════════════

// Varsayılan ayarlar
// NOT: Sadece backend'in gerçekten KULLANDIĞI alanlar burada.
// Eski `contentLength`, `systemPrompt`, `temperature` alanları kaldırıldı (ölü kod).
const DEFAULT_AI_SETTINGS = {
    difficulty: 'medium',          // easy | medium | hard — promptlara enjekte edilir
    enableQualityCheck: false,     // ikinci bir AI ile self-reflection (ekstra maliyet)
    useReferenceQuestions: false,  // bankadan örnek soru enjekte et
    maxRetries: 2                  // model çağrısı başına retry
};

// Ayarları localStorage'dan yükle
window.loadAISettings = function () {
    const saved = localStorage.getItem('aiSettings');
    return saved ? JSON.parse(saved) : { ...DEFAULT_AI_SETTINGS };
};

// Ayarları kaydet
window.saveAISettings = function (settings) {
    localStorage.setItem('aiSettings', JSON.stringify(settings));
    aiLog('⚙️ AI ayarları güncellendi', 'success');
};

// AI Ayarları modalını aç
window.openAISettingsModal = function () {
    const settings = loadAISettings();

    const modal = document.createElement('div');
    modal.id = 'aiSettingsModal';
    modal.style.cssText = `
        position: fixed; top: 0; left: 0; width: 100%; height: 100%;
        background: rgba(0,0,0,0.85); z-index: 10003;
        display: flex; align-items: center; justify-content: center;
        padding: 2rem; overflow: auto;
    `;

    modal.innerHTML = `
        <div style="background:#0f172a;border:1px solid #334155;border-radius:12px;max-width:560px;width:100%;max-height:90vh;overflow:auto">
            <div style="padding:1.25rem;border-bottom:1px solid #334155;background:#1e293b">
                <h3 style="margin:0;color:#f8fafc;font-size:1.1rem;display:flex;align-items:center;gap:0.5rem">
                    <span class="material-icons-round">tune</span>
                    AI Üretim Ayarları
                </h3>
                <p style="margin:0.35rem 0 0 1.75rem;color:#64748b;font-size:0.75rem">
                    Bu ayarlar tüm modüller için geçerlidir (sorular, anlatımlar, flashcard'lar, hikayeler, eşleştirme, verimlilik).
                </p>
            </div>
            <div style="padding:1.5rem">
                <!-- Zorluk -->
                <div style="margin-bottom:1.25rem">
                    <label style="display:block;color:#e2e8f0;font-size:0.85rem;margin-bottom:0.4rem;font-weight:600">
                        Zorluk Seviyesi
                    </label>
                    <select id="settingDifficulty" style="width:100%;padding:0.6rem;background:#1e293b;border:1px solid #334155;border-radius:6px;color:#e2e8f0">
                        <option value="easy"   ${settings.difficulty === 'easy' ? 'selected' : ''}>🟢 Kolay — Temel seviye, doğrudan bilgi</option>
                        <option value="medium" ${settings.difficulty === 'medium' ? 'selected' : ''}>🟡 Orta — Standart KPSS (önerilen)</option>
                        <option value="hard"   ${settings.difficulty === 'hard' ? 'selected' : ''}>🔴 Zor — Çıkarım, analiz, çeldirici yoğun</option>
                    </select>
                    <p style="margin:0.3rem 0 0;color:#64748b;font-size:0.72rem">
                        Promptlara zorluk direktifi ve dağılım hedefi olarak enjekte edilir.
                    </p>
                </div>

                <!-- Kalite Kontrol -->
                <div style="margin-bottom:1rem;padding:0.75rem;background:rgba(99,102,241,0.08);border:1px solid rgba(99,102,241,0.25);border-radius:7px">
                    <label style="display:flex;align-items:center;gap:0.5rem;cursor:pointer;font-weight:500">
                        <input type="checkbox" id="settingQualityCheck" ${settings.enableQualityCheck ? 'checked' : ''} style="width:1rem;height:1rem">
                        <span>🔍 Otomatik Kalite Kontrolü (Self-Reflection)</span>
                    </label>
                    <p style="margin:0.35rem 0 0 1.5rem;color:#94a3b8;font-size:0.72rem;line-height:1.4">
                        Üretilen içeriği ikinci bir AI çağrısıyla Gemini 2.5 Flash Lite üzerinden değerlendirir (puanlama + sorun listesi).<br>
                        <span style="color:#f59e0b">⚠️ Ekstra API maliyeti: ~%30</span>
                    </p>
                </div>

                <!-- Referans Sorular -->
                <div style="margin-bottom:1rem;padding:0.75rem;background:rgba(16,185,129,0.06);border:1px solid rgba(16,185,129,0.22);border-radius:7px">
                    <label style="display:flex;align-items:center;gap:0.5rem;cursor:pointer;font-weight:500">
                        <input type="checkbox" id="settingUseRefQuestions" ${settings.useReferenceQuestions ? 'checked' : ''} style="width:1rem;height:1rem">
                        <span>📚 Referans Sorularla Üret</span>
                    </label>
                    <p style="margin:0.35rem 0 0 1.5rem;color:#94a3b8;font-size:0.72rem;line-height:1.4">
                        Mevcut geçmiş KPSS soru bankasından bu konuya ait örnekleri modele referans olarak gönderir.<br>
                        <span style="color:#34d399">✓ Daha kaliteli çıktı</span> · <span style="color:#f59e0b">Token ~%10 artar</span>
                    </p>
                </div>

                <!-- Retry -->
                <div>
                    <label style="display:block;color:#e2e8f0;font-size:0.85rem;margin-bottom:0.4rem;font-weight:600">
                        Max Yeniden Deneme (Retry)
                    </label>
                    <input type="number" id="settingMaxRetries" value="${settings.maxRetries}" min="1" max="5"
                        style="width:110px;padding:0.55rem;background:#1e293b;border:1px solid #334155;border-radius:6px;color:#e2e8f0">
                    <p style="margin:0.3rem 0 0;color:#64748b;font-size:0.72rem">
                        Bir model çağrısı başarısız olursa kaç kez daha denensin (önerilen: 2-3).
                    </p>
                </div>
            </div>
            <div style="padding:1rem;border-top:1px solid #334155;background:#1e293b;display:flex;gap:0.75rem;justify-content:space-between;align-items:center">
                <button onclick="resetAISettings()" style="padding:0.55rem 1rem;background:transparent;border:1px solid #475569;border-radius:6px;color:#94a3b8;cursor:pointer;font-size:0.82rem">
                    ↺ Varsayılana Dön
                </button>
                <div style="display:flex;gap:0.6rem">
                    <button onclick="closeAISettingsModal()" style="padding:0.6rem 1.1rem;background:transparent;border:1px solid #475569;border-radius:6px;color:#94a3b8;cursor:pointer">İptal</button>
                    <button onclick="applyAISettings()" style="padding:0.6rem 1.4rem;background:#6366f1;border:none;border-radius:6px;color:white;cursor:pointer;font-weight:600">💾 Kaydet</button>
                </div>
            </div>
        </div>
    `;

    document.body.appendChild(modal);
};

window.closeAISettingsModal = function () {
    const modal = document.getElementById('aiSettingsModal');
    if (modal) modal.remove();
};

window.applyAISettings = function () {
    const settings = {
        difficulty: document.getElementById('settingDifficulty').value,
        enableQualityCheck: document.getElementById('settingQualityCheck').checked,
        useReferenceQuestions: document.getElementById('settingUseRefQuestions').checked,
        maxRetries: parseInt(document.getElementById('settingMaxRetries').value) || 2
    };

    saveAISettings(settings);
    closeAISettingsModal();
    showToast('AI ayarları kaydedildi!', 'success');
};

window.resetAISettings = function () {
    if (!confirm('Tüm AI ayarları varsayılana döndürülsün mü?')) return;
    localStorage.removeItem('aiSettings');
    closeAISettingsModal();
    showToast('Varsayılan ayarlara dönüldü', 'info');
    if (typeof openAISettingsModal === 'function') openAISettingsModal();
};

// AI Ayarlarını API isteğine dahil et
window.getAISettingsForAPI = function () {
    return loadAISettings();
};

// ═══════════════════════════════════════════════════════════════════════════
// BULK GENERATION & DRAFTS PAGE FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

window.startBulkGeneration = async function () {
    const moduleType = document.getElementById('bulkModuleType').value;
    const count = parseInt(document.getElementById('bulkCount').value);
    const model = document.getElementById('bulkModel').value;

    // Konu seçimi için basit bir prompt
    const topicName = prompt('Hangi konu için içerik üretmek istiyorsunuz?\n\nÖrnek: İlk Müslüman Türk Devletleri');
    if (!topicName) return;

    // Topic ID oluştur (basitleştirilmiş)
    const topicId = topicName.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '').substring(0, 20);

    aiLog('═══════════════════════════════════════════', 'ai');
    aiLog('🤖 TOPLU YZ ÜRETİMİ BAŞLATILIYOR', 'ai');
    aiLog(`   📋 Konu: ${topicName}`, 'ai');
    aiLog(`   📦 Modül: ${moduleType}`, 'ai');
    aiLog(`   🔢 Adet: ${count}`, 'ai');
    aiLog(`   🤖 Model: ${model}`, 'ai');
    aiLog('═══════════════════════════════════════════', 'ai');

    try {
        const res = await fetch(`${API}/api/ai-content/generate`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ moduleType, topicId, topicName, count, model })
        });

        const data = await res.json();

        if (!data.success) throw new Error(data.error);

        aiLog(`✅ ${data.generated} içerik üretildi ve taslaklara kaydedildi!`, 'success');
        aiLog(`📋 Toplam taslak: ${data.total}`, 'info');
        aiLog(`💡 Onaylamak için "Taslaklar" sayfasına gidin`, 'info');

        showToast(`${data.generated} içerik taslaklara kaydedildi!`, 'success');

        // Taslaklar sayfasına yönlendirme seçeneği
        if (confirm('Taslaklar sayfasına gidip içerikleri onaylamak ister misiniz?')) {
            showPage('drafts');
        }
    } catch (e) {
        aiLog(`❌ Üretim hatası: ${e.message}`, 'error');
        alert('YZ üretim hatası: ' + e.message);
    }
};

window.loadAllDrafts = async function () {
    aiLog('📋 Tüm taslaklar yükleniyor...', 'info');

    const moduleType = document.getElementById('draftModuleFilter')?.value || '';

    try {
        const allDrafts = [];

        // 1) KPSS konuları için genel modüller
        const topicsRes = await fetch(`${API}/api/ai-content/topics`);
        const topicsData = await topicsRes.json();

        const kpssTypes = ['explanations', 'stories', 'flashcards', 'matching_games', 'questions'];

        for (const topic of topicsData.topics || []) {
            const typesToCheck = moduleType
                ? (kpssTypes.includes(moduleType) ? [moduleType] : [])
                : kpssTypes;

            for (const type of typesToCheck) {
                const res = await fetch(`${API}/api/ai-content/drafts?topicId=${topic.id}&moduleType=${type}`);
                const data = await res.json();

                if (data.success && data.drafts && data.drafts.length > 0) {
                    data.drafts.forEach((draft, idx) => {
                        allDrafts.push({
                            ...draft,
                            _topicId: topic.id,
                            _topicName: topic.name,
                            _moduleType: type,
                            _index: idx
                        });
                    });
                }
            }
        }

        // 2) Productivity kategorileri (ayrı — KPSS topic listesi dışında)
        if (!moduleType || moduleType === 'productivity') {
            try {
                const pRes = await fetch(`${API}/api/ai-content/productivity-categories`);
                const pData = await pRes.json();
                for (const cat of pData.categories || []) {
                    if ((cat.drafts || 0) <= 0) continue;
                    const dRes = await fetch(`${API}/api/ai-content/drafts?topicId=${cat.id}&moduleType=productivity`);
                    const dData = await dRes.json();
                    if (dData.success && Array.isArray(dData.drafts)) {
                        dData.drafts.forEach((draft, idx) => {
                            allDrafts.push({
                                ...draft,
                                _topicId: cat.id,
                                _topicName: cat.name,
                                _moduleType: 'productivity',
                                _index: idx
                            });
                        });
                    }
                }
            } catch (e) {
                console.warn('Productivity taslakları yüklenemedi:', e);
            }
        }

        renderDraftsList(allDrafts);
        aiLog(`✅ ${allDrafts.length} taslak yüklendi`, 'success');
    } catch (e) {
        aiLog(`❌ Taslak yükleme hatası: ${e.message}`, 'error');
        document.getElementById('draftsList').innerHTML = `
            <div style="text-align: center; padding: 4rem; color: var(--danger);">
                <span class="material-icons-round" style="font-size: 4rem; margin-bottom: 1rem; display: block;">error</span>
                <p>Taslaklar yüklenirken hata oluştu: ${e.message}</p>
            </div>
        `;
    }
};

function renderDraftsList(drafts) {
    _allPageDrafts = drafts;
    const container = document.getElementById('draftsList');

    if (drafts.length === 0) {
        container.innerHTML = `
            <div style="text-align:center;padding:4rem;color:var(--text-muted);">
                <span class="material-icons-round" style="font-size:4rem;margin-bottom:1rem;display:block;">inbox</span>
                <p>Henüz taslak yok. AI Üretimi sayfasından içerik üretin.</p>
            </div>`;
        return;
    }

    const moduleNames = {
        explanations: '📚 Anlatım', stories: '📖 Hikaye',
        flashcards: '🃏 Flashcard', matching_games: '🔗 Eşleştirme',
        questions: '❓ Sorular', productivity: '⚡ Verimlilik'
    };

    container.innerHTML = `
        <div style="display:flex;flex-direction:column;gap:1rem;">

            <!-- Toolbar -->
            <div style="display:flex;align-items:center;gap:1rem;padding:0.85rem 1.25rem;
                        background:var(--bg-card);border:1px solid var(--border);border-radius:10px;flex-wrap:wrap;">
                <label style="display:flex;align-items:center;gap:0.5rem;cursor:pointer;user-select:none;">
                    <input type="checkbox" id="selectAllPageDrafts"
                        onchange="toggleSelectAllPageDrafts(this.checked)"
                        style="width:1.15rem;height:1.15rem;cursor:pointer;accent-color:#6366f1;">
                    <span style="font-size:0.9rem;color:var(--text-primary);font-weight:600;">Tümünü Seç</span>
                </label>

                <span id="pageDraftSelectedInfo"
                    style="font-size:0.82rem;color:var(--text-secondary);padding:0.2rem 0.6rem;
                           background:var(--bg-input);border-radius:4px;">
                    ${drafts.length} taslak
                </span>

                <div style="margin-left:auto;display:flex;gap:0.6rem;flex-wrap:wrap;">
                    <button id="pageApproveBulkBtn" onclick="approveSelectedDrafts()" disabled
                        style="display:flex;align-items:center;gap:0.4rem;padding:0.5rem 1.1rem;
                               background:linear-gradient(135deg,#10b981,#059669);border:none;color:white;
                               border-radius:7px;font-weight:600;font-size:0.85rem;cursor:pointer;
                               opacity:0.4;transition:opacity 0.2s;">
                        <span class="material-icons-round" style="font-size:1rem;">check_circle</span>
                        Seçilenleri Onayla (<span id="pageApproveCount">0</span>)
                    </button>
                    <button id="pageDeleteBulkBtn" onclick="deleteSelectedPageDrafts()" disabled
                        style="display:flex;align-items:center;gap:0.4rem;padding:0.5rem 1.1rem;
                               background:#ef4444;border:none;color:white;border-radius:7px;
                               font-weight:600;font-size:0.85rem;cursor:pointer;
                               opacity:0.4;transition:opacity 0.2s;">
                        <span class="material-icons-round" style="font-size:1rem;">delete</span>
                        Seçilenleri Sil (<span id="pageDeleteCount">0</span>)
                    </button>
                </div>
            </div>

            <!-- Draft Cards -->
            ${drafts.map((draft, i) => `
                <div id="pageDraftCard-${i}"
                    style="background:var(--bg-card);border:2px solid var(--border);border-radius:12px;
                           padding:1.25rem;transition:border-color 0.15s;">
                    <div style="display:flex;gap:1rem;align-items:flex-start;">
                        <input type="checkbox" class="page-draft-cb" data-index="${i}"
                            onchange="updatePageDraftSelection()"
                            style="width:1.1rem;height:1.1rem;cursor:pointer;margin-top:0.25rem;
                                   flex-shrink:0;accent-color:#6366f1;">

                        <div style="flex:1;min-width:0;">
                            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:0.6rem;">
                                <div style="display:flex;align-items:center;gap:0.5rem;flex-wrap:wrap;">
                                    <span style="background:#6366f1;color:white;padding:0.15rem 0.55rem;
                                                 border-radius:4px;font-size:0.72rem;font-weight:600;">
                                        ${moduleNames[draft._moduleType] || draft._moduleType}
                                    </span>
                                    <span style="color:var(--text-secondary);font-size:0.82rem;">${draft._topicName}</span>
                                </div>
                                <span style="color:var(--text-muted);font-size:0.72rem;flex-shrink:0;">#${i + 1}</span>
                            </div>

                            <h4 style="margin:0 0 0.6rem 0;color:var(--text-primary);font-size:0.95rem;">
                                ${getDraftTitle(draft, i)}
                            </h4>

                            <div style="background:rgba(15,23,42,0.5);border-radius:7px;padding:0.75rem;
                                        font-size:0.82rem;color:var(--text-secondary);max-height:160px;overflow-y:auto;">
                                ${getDraftPreview(draft)}
                            </div>

                            <div style="display:flex;gap:0.5rem;margin-top:0.85rem;flex-wrap:wrap;">
                                <button onclick="previewPageDraft(${i})"
                                    style="display:flex;align-items:center;gap:0.3rem;padding:0.4rem 0.9rem;
                                           background:transparent;border:1px solid #475569;
                                           color:#94a3b8;border-radius:6px;font-size:0.8rem;cursor:pointer;">
                                    <span class="material-icons-round" style="font-size:0.9rem;">visibility</span>Önizle
                                </button>
                                <button onclick="editPageDraft(${i})"
                                    style="display:flex;align-items:center;gap:0.3rem;padding:0.4rem 0.9rem;
                                           background:transparent;border:1px solid #6366f1;
                                           color:#a5b4fc;border-radius:6px;font-size:0.8rem;cursor:pointer;">
                                    <span class="material-icons-round" style="font-size:0.9rem;">edit</span>Düzenle
                                </button>
                                <button onclick="approveSingleDraft('${draft._topicId}','${draft._topicName.replace(/'/g, "\\'")}','${draft._moduleType}',${draft._index})"
                                    style="display:flex;align-items:center;gap:0.3rem;padding:0.4rem 0.9rem;
                                           background:linear-gradient(135deg,#10b981,#059669);border:none;
                                           color:white;border-radius:6px;font-size:0.8rem;font-weight:600;cursor:pointer;">
                                    <span class="material-icons-round" style="font-size:0.9rem;">check</span>Onayla
                                </button>
                                <button onclick="deletePageDraftSingle(${i})"
                                    style="display:flex;align-items:center;gap:0.3rem;padding:0.4rem 0.9rem;
                                           background:transparent;border:1px solid #ef4444;
                                           color:#ef4444;border-radius:6px;font-size:0.8rem;cursor:pointer;">
                                    <span class="material-icons-round" style="font-size:0.9rem;">delete</span>Sil
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            `).join('')}
        </div>`;
}

window.toggleSelectAllPageDrafts = function (checked) {
    document.querySelectorAll('.page-draft-cb').forEach(cb => cb.checked = checked);
    updatePageDraftSelection();
};

window.updatePageDraftSelection = function () {
    const all = document.querySelectorAll('.page-draft-cb');
    const checked = document.querySelectorAll('.page-draft-cb:checked');
    const n = checked.length;

    const info = document.getElementById('pageDraftSelectedInfo');
    if (info) info.textContent = n > 0 ? `${n} seçili / ${all.length} taslak` : `${all.length} taslak`;

    const approveBtn = document.getElementById('pageApproveBulkBtn');
    const deleteBtn = document.getElementById('pageDeleteBulkBtn');
    const approveCount = document.getElementById('pageApproveCount');
    const deleteCount = document.getElementById('pageDeleteCount');

    if (approveCount) approveCount.textContent = n;
    if (deleteCount) deleteCount.textContent = n;

    [approveBtn, deleteBtn].forEach(btn => {
        if (!btn) return;
        btn.disabled = n === 0;
        btn.style.opacity = n === 0 ? '0.4' : '1';
        btn.style.cursor = n === 0 ? 'not-allowed' : 'pointer';
    });

    // Kart kenar rengi
    document.querySelectorAll('.page-draft-cb').forEach(cb => {
        const card = document.getElementById(`pageDraftCard-${cb.dataset.index}`);
        if (card) card.style.borderColor = cb.checked ? '#6366f1' : 'var(--border)';
    });

    // "Tümünü Seç" checkbox indeterminate durumu
    const selectAll = document.getElementById('selectAllPageDrafts');
    if (selectAll) {
        selectAll.indeterminate = n > 0 && n < all.length;
        selectAll.checked = n === all.length && all.length > 0;
    }
};

window.approveSelectedDrafts = async function () {
    const checked = document.querySelectorAll('.page-draft-cb:checked');
    if (checked.length === 0) { showToast('En az bir taslak seçin', 'warning'); return; }

    const indices = Array.from(checked).map(cb => parseInt(cb.dataset.index));
    const count = indices.length;

    if (!confirm(`✅ ${count} taslak onaylanıp canlıya alınacak.\n\nDevam?`)) return;

    // Grupla: {topicId_moduleType} => [_index, ...]
    const groups = {};
    indices.forEach(i => {
        const d = _allPageDrafts[i];
        const key = `${d._topicId}::${d._moduleType}`;
        if (!groups[key]) groups[key] = { topicId: d._topicId, topicName: d._topicName, moduleType: d._moduleType, indices: [] };
        groups[key].indices.push(d._index);
    });

    let approved = 0;
    let errors = 0;
    for (const g of Object.values(groups)) {
        try {
            const res = await fetch(`${API}/api/ai-content/approve-draft`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ moduleType: g.moduleType, topicId: g.topicId, topicName: g.topicName, indices: g.indices })
            });
            const data = await res.json();
            if (data.success) approved += data.published || g.indices.length;
            else errors++;
        } catch { errors++; }
    }

    if (errors > 0) showToast(`${approved} onaylandı, ${errors} hata`, 'warning');
    else showToast(`✅ ${approved} taslak yayınlandı!`, 'success');

    await loadAllDrafts();
};

window.deleteSelectedPageDrafts = async function () {
    const checked = document.querySelectorAll('.page-draft-cb:checked');
    if (checked.length === 0) { showToast('En az bir taslak seçin', 'warning'); return; }

    const indices = Array.from(checked).map(cb => parseInt(cb.dataset.index));
    if (!confirm(`🗑️ ${indices.length} taslak kalıcı olarak silinecek.\nBu işlem geri alınamaz!\n\nDevam?`)) return;

    // Grupla: {topicId_moduleType} => [_index, ...]
    const groups = {};
    indices.forEach(i => {
        const d = _allPageDrafts[i];
        const key = `${d._topicId}::${d._moduleType}`;
        if (!groups[key]) groups[key] = { topicId: d._topicId, moduleType: d._moduleType, indices: [] };
        groups[key].indices.push(d._index);
    });

    let deleted = 0;
    let errors = 0;
    for (const g of Object.values(groups)) {
        try {
            const res = await fetch(`${API}/api/ai-content/delete-draft`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ moduleType: g.moduleType, topicId: g.topicId, indices: g.indices })
            });
            const data = await res.json();
            if (data.success) deleted += data.deleted || g.indices.length;
            else errors++;
        } catch { errors++; }
    }

    if (errors > 0) showToast(`${deleted} silindi, ${errors} hata`, 'warning');
    else showToast(`🗑️ ${deleted} taslak silindi`, 'success');

    await loadAllDrafts();
};

window.deletePageDraftSingle = async function (pageIndex) {
    const draft = _allPageDrafts[pageIndex];
    if (!draft) return;

    if (!confirm(`🗑️ Bu taslak silinecek:\n"${getDraftTitle(draft, pageIndex)}"\n\nDevam?`)) return;

    try {
        const res = await fetch(`${API}/api/ai-content/delete-draft`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ moduleType: draft._moduleType, topicId: draft._topicId, indices: [draft._index] })
        });
        const data = await res.json();
        if (data.success) { showToast('Taslak silindi', 'success'); await loadAllDrafts(); }
        else showToast('Silme hatası: ' + data.error, 'error');
    } catch (e) { showToast('Silme hatası: ' + e.message, 'error'); }
};

function getDraftTitle(draft, index) {
    // Modül tipine göre başlık döndür
    if (draft._moduleType === 'flashcards') {
        const front = draft.front || draft.question;
        return front ? front.substring(0, 80) : `Flashcard ${index + 1}`;
    }
    if (draft._moduleType === 'matching_games') {
        const left = draft.left || draft.question;
        return left ? left.substring(0, 80) : `Eşleştirme ${index + 1}`;
    }
    if (draft._moduleType === 'questions') {
        const q = draft.q || draft.question;
        // Sorular uzun olabilir, TAMAMINI göster (kesme)
        return q ? q : `Soru ${index + 1}`;
    }
    if (draft._moduleType === 'productivity') {
        // Verimlilik içerikleri - başlık göster
        return draft.title || `Verimlilik ${index + 1}`;
    }
    // explanations, stories - title var
    return draft.title || `Bölüm ${index + 1}`;
}

function getDraftPreview(draft) {
    if (draft._moduleType === 'explanations') {
        return draft.content?.map(c => {
            if (c.type === 'heading') return `<b>${c.text}</b>`;
            if (c.type === 'text') return c.text.substring(0, 200) + '...';
            if (c.type === 'bulletList') return `<ul>${c.text?.split('\\n').map(l => `<li>${l.substring(0, 100)}</li>`).join('') || ''}</ul>`;
            return '';
        }).join('<br>') || 'İçerik yok';
    } else if (draft._moduleType === 'stories') {
        return draft.content?.substring(0, 300) + '...' || 'Hikaye içeriği yok';
    } else if (draft._moduleType === 'flashcards') {
        const front = draft.front || draft.question || 'Soru yok';
        const back = draft.back || draft.answer || 'Cevap yok';
        const info = draft.additionalInfo;
        return `<b>S:</b> ${front.substring(0, 100)}...<br><b>C:</b> ${back.substring(0, 100)}...${info ? '<br><span style="color:#f59e0b;font-size:0.75rem">💡 ' + info.substring(0, 50) + '...</span>' : ''}`;
    } else if (draft._moduleType === 'questions') {
        const labels = ['A', 'B', 'C', 'D', 'E'];
        const opts = (draft.o || []).map((o, i) => `<span style="color:${i === draft.a ? '#10b981' : 'inherit'}">${labels[i]}) ${o}</span>`).join('<br>');
        return `<b>S:</b> ${(draft.q || draft.question || '').substring(0, 120)}<br>${opts}`;
    } else if (draft._moduleType === 'matching_games') {
        const left = draft.left || draft.question || draft.q || 'Sol taraf';
        const right = draft.right || draft.answer || draft.a || 'Sağ taraf';
        return `${left.substring(0, 50)} ↔️ ${right.substring(0, 50)}`;
    } else if (draft._moduleType === 'productivity') {
        const title = draft.title || 'Başlık yok';
        const short = draft.shortDescription || '';
        const full = (draft.fullDescription || draft.content || '').substring(0, 150);
        const steps = Array.isArray(draft.steps) ? draft.steps.length : 0;
        const tips = Array.isArray(draft.tips) ? draft.tips.length : 0;
        const benefits = Array.isArray(draft.benefits) ? draft.benefits.length : 0;
        const lead = short || (full + (full.length >= 150 ? '...' : ''));
        return `<b>⚡ ${title.substring(0, 80)}</b><br>${lead}<br><span style="color:#f59e0b;font-size:0.75rem">📋 ${steps} adım · ✨ ${benefits} fayda · 💡 ${tips} ipucu</span>`;
    } else {
        return 'Önizleme yok';
    }
}

// ── Önizleme Modalı ──────────────────────────────────────────────────────────
window.previewPageDraft = function (pageIndex) {
    const draft = _allPageDrafts[pageIndex];
    if (!draft) return;

    const typeLabels = { explanations: '📚 Konu Anlatımı', stories: '📖 Hikaye', flashcards: '🃏 Flashcard', matching_games: '🔗 Eşleştirme', questions: '❓ Sorular', productivity: '⚡ Verimlilik' };
    let body = '';
    const mt = draft._moduleType;

    if (mt === 'explanations') {
        body = (draft.content || []).map(c => {
            if (c.type === 'heading') return `<h3 style="color:#a5b4fc;margin:1rem 0 0.4rem">${c.text}</h3>`;
            if (c.type === 'text') return `<p style="margin:0 0 0.6rem;line-height:1.65;color:#cbd5e1">${c.text}</p>`;
            if (c.type === 'bulletList') return `<ul style="margin:0 0 0.6rem 1.2rem;color:#cbd5e1">${(c.text || '').split(/\\n|\n/).filter(Boolean).map(l => `<li>${l.replace(/^•\s*/, '')}</li>`).join('')}</ul>`;
            if (c.type === 'warning') return `<div style="background:rgba(239,68,68,0.1);border-left:3px solid #ef4444;padding:0.6rem 0.75rem;margin:0.5rem 0;color:#fca5a5;border-radius:0 6px 6px 0">${c.text}</div>`;
            if (c.type === 'highlighted') return `<div style="background:rgba(99,102,241,0.15);border-left:3px solid #6366f1;padding:0.6rem 0.75rem;margin:0.5rem 0;color:#c7d2fe;border-radius:0 6px 6px 0">${c.text}</div>`;
            return '';
        }).join('');
    } else if (mt === 'stories') {
        body = `<p style="line-height:1.8;color:#cbd5e1;white-space:pre-wrap">${draft.content || ''}</p>`;
        if (draft.key_points?.length) body += `<ul style="margin-top:1rem;color:#a5b4fc">${draft.key_points.map(k => `<li>${k}</li>`).join('')}</ul>`;
    } else if (mt === 'flashcards') {
        const front = draft.front || draft.question || '';
        const back = draft.back || draft.answer || '';
        const info = draft.additionalInfo || '';
        body = `<div style="display:flex;gap:1rem;flex-direction:column">
            <div style="background:rgba(99,102,241,0.1);border:1px solid #6366f1;border-radius:8px;padding:1rem">
                <div style="font-size:0.72rem;color:#6366f1;font-weight:600;margin-bottom:0.4rem">SORU (ÖN YÜZ)</div>
                <div style="color:#e2e8f0;font-size:1rem">${front}</div>
            </div>
            <div style="background:rgba(16,185,129,0.1);border:1px solid #10b981;border-radius:8px;padding:1rem">
                <div style="font-size:0.72rem;color:#10b981;font-weight:600;margin-bottom:0.4rem">CEVAP (ARKA YÜZ)</div>
                <div style="color:#e2e8f0;font-size:1rem">${back}</div>
            </div>
            ${info ? `<div style="background:rgba(245,158,11,0.1);border:1px solid #f59e0b;border-radius:8px;padding:1rem">
                <div style="font-size:0.72rem;color:#f59e0b;font-weight:600;margin-bottom:0.4rem">💡 EK BİLGİ</div>
                <div style="color:#fcd34d;font-size:0.9rem">${info}</div>
            </div>` : ''}
        </div>`;
    } else if (mt === 'questions') {
        const labels = ['A', 'B', 'C', 'D', 'E'];
        const optsHtml = (draft.o || []).map((o, i) => {
            const isCorrect = i === draft.a;
            return `<div style="padding:0.5rem 0.75rem;margin:0.3rem 0;border-radius:6px;
                background:${isCorrect ? 'rgba(16,185,129,0.15)' : 'rgba(30,41,59,0.8)'};
                border:1px solid ${isCorrect ? '#10b981' : '#334155'};
                color:${isCorrect ? '#6ee7b7' : '#cbd5e1'}">
                <b>${labels[i]})</b> ${o}${isCorrect ? ' ✓' : ''}
            </div>`;
        }).join('');
        const qText = (draft.q || draft.question || '').trim();
        body = `<div style="margin-bottom:1rem;padding:1rem;background:rgba(99,102,241,0.1);border:1px solid #6366f1;border-radius:8px;color:#e2e8f0;line-height:1.6">${qText}</div>${optsHtml}${draft.e ? `<div style="margin-top:1rem;padding:0.75rem;background:rgba(245,158,11,0.1);border-left:3px solid #f59e0b;border-radius:0 6px 6px 0;color:#fcd34d;font-size:0.85rem"><b>Açıklama:</b> ${draft.e}</div>` : ''}`;
    } else if (mt === 'productivity') {
        const stepsHtml = (draft.steps || []).map((step, i) =>
            `<div style="padding:0.5rem 0.75rem;margin:0.3rem 0;border-radius:6px;background:rgba(99,102,241,0.1);border:1px solid #6366f1;color:#e2e8f0"><b>${i + 1}.</b> ${step}</div>`
        ).join('');
        const benefitsHtml = (draft.benefits || []).map(b =>
            `<li style="margin:0.4rem 0;color:#cbd5e1">✨ ${b}</li>`
        ).join('');
        const tipsHtml = (draft.tips || []).map(tip =>
            `<li style="margin:0.4rem 0;color:#cbd5e1">💡 ${tip}</li>`
        ).join('');
        const fullDesc = draft.fullDescription || draft.content || '';
        body = `<div style="background:rgba(245,158,11,0.1);border:1px solid #f59e0b;border-radius:8px;padding:1rem;margin-bottom:1rem">
            <div style="display:flex;gap:0.5rem;align-items:center;margin-bottom:0.5rem">
                <span style="font-size:0.72rem;color:#f59e0b;font-weight:600">VERİMLİLİK TEKNİĞİ</span>
                ${draft.id ? `<span style="font-family:monospace;font-size:0.7rem;background:#0f172a;color:#64748b;padding:0.1rem 0.4rem;border-radius:3px">${draft.id}</span>` : ''}
                ${draft.category ? `<span style="font-size:0.7rem;background:rgba(99,102,241,0.15);color:#a5b4fc;padding:0.1rem 0.4rem;border-radius:3px">${draft.category}</span>` : ''}
            </div>
            <h3 style="color:#f8fafc;margin:0 0 0.5rem 0">${draft.title || ''}</h3>
            ${draft.shortDescription ? `<div style="color:#fcd34d;font-size:0.88rem;margin-bottom:0.6rem;font-style:italic">${draft.shortDescription}</div>` : ''}
            <p style="color:#e2e8f0;line-height:1.7;white-space:pre-wrap;margin:0">${fullDesc}</p>
        </div>
        ${stepsHtml ? `<div style="background:rgba(30,41,59,0.8);border-radius:8px;padding:1rem;margin-bottom:1rem"><div style="font-size:0.72rem;color:#94a3b8;font-weight:600;margin-bottom:0.4rem">📋 ADIMLAR</div>${stepsHtml}</div>` : ''}
        ${benefitsHtml ? `<div style="background:rgba(30,41,59,0.8);border-radius:8px;padding:1rem;margin-bottom:1rem"><div style="font-size:0.72rem;color:#94a3b8;font-weight:600;margin-bottom:0.4rem">✨ FAYDALARI</div><ul style="margin:0;padding-left:1.2rem">${benefitsHtml}</ul></div>` : ''}
        ${tipsHtml ? `<div style="background:rgba(30,41,59,0.8);border-radius:8px;padding:1rem"><div style="font-size:0.72rem;color:#94a3b8;font-weight:600;margin-bottom:0.4rem">💡 İPUÇLARI</div><ul style="margin:0;padding-left:1.2rem">${tipsHtml}</ul></div>` : ''}`;
    } else {
        body = `<div style="display:flex;gap:1rem;align-items:center;font-size:1rem;color:#e2e8f0">
            <span style="flex:1;background:rgba(99,102,241,0.1);padding:0.75rem;border-radius:8px;text-align:center">${draft.left || ''}</span>
            <span style="color:#6366f1;font-weight:700">↔</span>
            <span style="flex:1;background:rgba(16,185,129,0.1);padding:0.75rem;border-radius:8px;text-align:center">${draft.right || ''}</span>
        </div>`;
    }

    const modal = document.createElement('div');
    modal.id = 'draftPreviewModal';
    modal.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,0.75);z-index:9999;display:flex;align-items:center;justify-content:center;padding:1rem';
    modal.innerHTML = `
        <div style="background:#1e293b;border:1px solid #334155;border-radius:12px;width:min(700px,100%);max-height:85vh;display:flex;flex-direction:column;overflow:hidden">
            <div style="display:flex;align-items:center;justify-content:space-between;padding:1rem 1.25rem;border-bottom:1px solid #334155;flex-shrink:0">
                <div>
                    <div style="font-size:0.72rem;color:#6366f1;font-weight:600;margin-bottom:0.2rem">${typeLabels[mt] || mt}</div>
                    <div style="font-weight:600;color:#e2e8f0">${getDraftTitle(draft, pageIndex)}</div>
                </div>
                <button onclick="document.getElementById('draftPreviewModal').remove()"
                    style="background:none;border:none;color:#94a3b8;cursor:pointer;font-size:1.4rem;line-height:1">✕</button>
            </div>
            <div style="padding:1.25rem;overflow-y:auto">${body}</div>
            <div style="padding:0.75rem 1.25rem;border-top:1px solid #334155;display:flex;gap:0.5rem;justify-content:flex-end;flex-shrink:0">
                <button onclick="editPageDraft(${pageIndex});document.getElementById('draftPreviewModal').remove()"
                    style="padding:0.45rem 1rem;background:transparent;border:1px solid #6366f1;color:#a5b4fc;border-radius:6px;cursor:pointer;font-size:0.85rem">
                    ✏️ Düzenle
                </button>
                <button onclick="document.getElementById('draftPreviewModal').remove()"
                    style="padding:0.45rem 1rem;background:#475569;border:none;color:white;border-radius:6px;cursor:pointer;font-size:0.85rem">
                    Kapat
                </button>
            </div>
        </div>`;
    modal.addEventListener('click', e => { if (e.target === modal) modal.remove(); });
    document.body.appendChild(modal);
};

// ── Düzenleme Modalı ─────────────────────────────────────────────────────────
window.editPageDraft = function (pageIndex) {
    const draft = _allPageDrafts[pageIndex];
    if (!draft) return;
    const mt = draft._moduleType;

    let fieldsHtml = '';
    const inp = (id, label, val, tag = 'input', rows = 3) => tag === 'input'
        ? `<div style="margin-bottom:0.75rem">
               <label style="display:block;font-size:0.75rem;color:#94a3b8;margin-bottom:0.3rem">${label}</label>
               <input id="${id}" value="${(val || '').replace(/"/g, '&quot;')}"
                   style="width:100%;padding:0.5rem 0.65rem;background:#0f172a;border:1px solid #334155;border-radius:6px;color:#e2e8f0;font-size:0.9rem;box-sizing:border-box">
           </div>`
        : `<div style="margin-bottom:0.75rem">
               <label style="display:block;font-size:0.75rem;color:#94a3b8;margin-bottom:0.3rem">${label}</label>
               <textarea id="${id}" rows="${rows}"
                   style="width:100%;padding:0.5rem 0.65rem;background:#0f172a;border:1px solid #334155;border-radius:6px;color:#e2e8f0;font-size:0.9rem;resize:vertical;box-sizing:border-box">${(val || '').replace(/</g, '&lt;')}</textarea>
           </div>`;

    if (mt === 'flashcards') {
        const frontVal = draft.front || draft.question || '';
        const backVal = draft.back || draft.answer || '';
        const infoVal = draft.additionalInfo || '';
        fieldsHtml = inp('ef_front', 'Soru (Ön Yüz)', frontVal, 'textarea', 3)
            + inp('ef_back', 'Cevap (Arka Yüz)', backVal, 'textarea', 3)
            + inp('ef_info', 'Ek Bilgi / İpucu', infoVal, 'textarea', 2);
    } else if (mt === 'questions') {
        const oVals = (draft.o || []).join('\n');
        fieldsHtml = inp('ef_q', 'Soru', draft.q || draft.question, 'textarea', 3)
            + inp('ef_o', 'Şıklar (her satır bir şık, A-E)', oVals, 'textarea', 5)
            + inp('ef_a', 'Doğru Cevap İndeksi (0=A, 1=B...)', String(draft.a ?? ''))
            + inp('ef_e', 'Açıklama', draft.e || draft.explanation, 'textarea', 3);
    } else if (mt === 'matching_games') {
        const leftVal = draft.left || draft.question || draft.q || '';
        const rightVal = draft.right || draft.answer || draft.a || '';
        fieldsHtml = inp('ef_left', 'Sol', leftVal) + inp('ef_right', 'Sağ', rightVal);
    } else if (mt === 'stories') {
        fieldsHtml = inp('ef_title', 'Başlık', draft.title) + inp('ef_content', 'İçerik', draft.content, 'textarea', 10);
    } else {
        fieldsHtml = inp('ef_title', 'Başlık', draft.title);
        (draft.content || []).forEach((b, i) => {
            const typeLabel = { heading: 'Başlık', text: 'Metin', bulletList: 'Madde Listesi', warning: 'Uyarı', highlighted: 'Vurgulanan' }[b.type] || b.type;
            fieldsHtml += inp(`ef_block_${i}`, `${i + 1}. Blok — ${typeLabel}`, b.text, 'textarea', b.type === 'bulletList' ? 5 : 3);
        });
    }

    const modal = document.createElement('div');
    modal.id = 'draftEditModal';
    modal.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,0.75);z-index:9999;display:flex;align-items:center;justify-content:center;padding:1rem';
    modal.innerHTML = `
        <div style="background:#1e293b;border:1px solid #334155;border-radius:12px;width:min(680px,100%);max-height:90vh;display:flex;flex-direction:column;overflow:hidden">
            <div style="display:flex;align-items:center;justify-content:space-between;padding:1rem 1.25rem;border-bottom:1px solid #334155;flex-shrink:0">
                <div style="font-weight:600;color:#e2e8f0">✏️ Taslak Düzenle</div>
                <button onclick="document.getElementById('draftEditModal').remove()"
                    style="background:none;border:none;color:#94a3b8;cursor:pointer;font-size:1.4rem;line-height:1">✕</button>
            </div>
            <div style="padding:1.25rem;overflow-y:auto">${fieldsHtml}</div>
            <div style="padding:0.75rem 1.25rem;border-top:1px solid #334155;display:flex;gap:0.5rem;justify-content:flex-end;flex-shrink:0">
                <button onclick="document.getElementById('draftEditModal').remove()"
                    style="padding:0.45rem 1rem;background:#475569;border:none;color:white;border-radius:6px;cursor:pointer;font-size:0.85rem">İptal</button>
                <button id="draftEditSaveBtn" onclick="savePageDraftEdit(${pageIndex})"
                    style="padding:0.45rem 1.1rem;background:#6366f1;border:none;color:white;border-radius:6px;cursor:pointer;font-size:0.85rem;font-weight:600">
                    💾 Kaydet
                </button>
            </div>
        </div>`;
    modal.addEventListener('click', e => { if (e.target === modal) modal.remove(); });
    document.body.appendChild(modal);
};

window.savePageDraftEdit = async function (pageIndex) {
    const draft = _allPageDrafts[pageIndex];
    if (!draft) return;
    const mt = draft._moduleType;
    const btn = document.getElementById('draftEditSaveBtn');
    if (btn) { btn.disabled = true; btn.textContent = 'Kaydediliyor...'; }

    let updatedDraft = {};
    try {
        if (mt === 'flashcards') {
            updatedDraft.front = document.getElementById('ef_front').value;
            updatedDraft.back = document.getElementById('ef_back').value;
            updatedDraft.additionalInfo = document.getElementById('ef_info').value;
            // Alternatif alan isimleri de destekle
            updatedDraft.question = updatedDraft.front;
            updatedDraft.answer = updatedDraft.back;
        } else if (mt === 'questions') {
            updatedDraft.q = document.getElementById('ef_q').value;
            updatedDraft.o = document.getElementById('ef_o').value.split('\n').map(s => s.trim()).filter(Boolean);
            updatedDraft.a = parseInt(document.getElementById('ef_a').value) || 0;
            updatedDraft.e = document.getElementById('ef_e').value;
        } else if (mt === 'matching_games') {
            updatedDraft.left = document.getElementById('ef_left').value;
            updatedDraft.right = document.getElementById('ef_right').value;
            updatedDraft.q = updatedDraft.left;
            updatedDraft.a = updatedDraft.right;
            // Alternatif alan isimleri de destekle
            updatedDraft.question = updatedDraft.left;
            updatedDraft.answer = updatedDraft.right;
        } else if (mt === 'stories') {
            updatedDraft.title = document.getElementById('ef_title').value;
            updatedDraft.content = document.getElementById('ef_content').value;
        } else {
            updatedDraft.title = document.getElementById('ef_title').value;
            const blocks = JSON.parse(JSON.stringify(draft.content || []));
            blocks.forEach((b, i) => {
                const el = document.getElementById(`ef_block_${i}`);
                if (el) blocks[i] = { ...b, text: el.value };
            });
            updatedDraft.content = blocks;
        }

        const res = await fetch(`${API}/api/ai-content/update-draft`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ moduleType: mt, topicId: draft._topicId, index: draft._index, updatedDraft })
        });
        const data = await res.json();
        if (!data.success) throw new Error(data.error || 'Güncelleme başarısız');

        document.getElementById('draftEditModal')?.remove();
        showToast('Taslak güncellendi ✓', 'success');
        await loadAllDrafts();
    } catch (e) {
        showToast('Kayıt hatası: ' + e.message, 'error');
        if (btn) { btn.disabled = false; btn.textContent = '💾 Kaydet'; }
    }
};

// ── İçerik İstatistikleri ─────────────────────────────────────────────────────
let _statsData = [];

window.initContentStatsPage = async function () {
    const el = document.getElementById('statsTableBody');
    if (!el) return;
    el.innerHTML = '<span style="color:#94a3b8">Yükleniyor...</span>';
    try {
        const res = await fetch(`${API}/api/content-stats`);
        const data = await res.json();
        _statsData = data.stats || [];
        renderStatsTable();
    } catch (e) {
        el.innerHTML = `<span style="color:#ef4444">Hata: ${e.message}</span>`;
    }
};

window.filterStatsTable = function () { renderStatsTable(); };

function renderStatsTable() {
    const el = document.getElementById('statsTableBody');
    if (!el) return;
    const q = (document.getElementById('statsSearch')?.value || '').toLowerCase();
    const filter = document.getElementById('statsFilter')?.value || 'all';
    const threshold = parseInt(document.getElementById('statsThreshold')?.value || '5');
    const mods = ['explanations', 'flashcards', 'stories', 'matching_games'];
    const modLabels = { explanations: 'Anlatım', flashcards: 'FC', stories: 'Hikaye', matching_games: 'Eşleş.' };

    let rows = _statsData.filter(t => {
        if (q && !t.name.toLowerCase().includes(q)) return false;
        const total = mods.reduce((s, m) => s + (t[m] || 0), 0);
        if (filter === 'empty') return total === 0;
        if (filter === 'low') return mods.some(m => (t[m] || 0) < threshold);
        return true;
    });

    if (!rows.length) { el.innerHTML = '<span style="color:#64748b">Sonuç bulunamadı</span>'; return; }

    const totalByMod = mods.reduce((acc, m) => { acc[m] = _statsData.reduce((s, t) => s + (t[m] || 0), 0); return acc; }, {});
    const lowCount = _statsData.filter(t => mods.some(m => (t[m] || 0) < threshold)).length;

    const summary = `<div style="display:flex;gap:1rem;flex-wrap:wrap;margin-bottom:1rem;padding-bottom:0.75rem;border-bottom:1px solid #334155">
        ${mods.map(m => `<div style="text-align:center">
            <div style="font-size:1.2rem;font-weight:700;color:#a5b4fc">${totalByMod[m]}</div>
            <div style="font-size:0.7rem;color:#64748b">${modLabels[m]}</div>
        </div>`).join('')}
        <div style="text-align:center">
            <div style="font-size:1.2rem;font-weight:700;color:#fca5a5">${lowCount}</div>
            <div style="font-size:0.7rem;color:#64748b">Az İçerikli</div>
        </div>
    </div>`;

    const tableRows = rows.map(t => {
        const cells = mods.map(m => {
            const v = t[m] || 0;
            const color = v === 0 ? '#ef4444' : v < threshold ? '#f59e0b' : '#10b981';
            return `<td style="text-align:center;padding:0.4rem 0.5rem;color:${color};font-weight:600">${v}</td>`;
        }).join('');
        const draftBadge = t.drafts > 0 ? `<span style="background:rgba(99,102,241,0.2);color:#a5b4fc;padding:0.1rem 0.4rem;border-radius:3px;font-size:0.7rem;margin-left:0.4rem">${t.drafts} taslak</span>` : '';
        const anyLow = mods.some(m => (t[m] || 0) < threshold);
        const genBtns = anyLow ? mods.filter(m => (t[m] || 0) < threshold)
            .map(m => `<button onclick="generateWithAI('${t.id}','${t.name.replace(/'/g, "\\'")}','${m}',${threshold - (t[m] || 0)},'stats-btn-${t.id}-${m}')" 
                id="stats-btn-${t.id}-${m}"
                style="padding:0.15rem 0.4rem;background:rgba(99,102,241,0.2);border:1px solid rgba(99,102,241,0.3);
                       color:#a5b4fc;border-radius:4px;font-size:0.68rem;cursor:pointer;margin:0.1rem">
                +${threshold - (t[m] || 0)} ${modLabels[m]}</button>`).join('') : '';
        return `<tr style="border-bottom:1px solid rgba(51,65,85,0.5)">
            <td style="padding:0.4rem 0.5rem;color:#e2e8f0">${t.name}${draftBadge}</td>
            ${cells}
            <td style="padding:0.4rem 0.5rem">${genBtns}</td>
        </tr>`;
    }).join('');

    el.innerHTML = summary + `<div style="overflow-x:auto"><table style="width:100%;border-collapse:collapse">
        <thead><tr style="border-bottom:2px solid #334155">
            <th style="text-align:left;padding:0.4rem 0.5rem;color:#94a3b8;font-size:0.75rem">Konu</th>
            ${mods.map(m => `<th style="text-align:center;padding:0.4rem 0.5rem;color:#94a3b8;font-size:0.75rem">${modLabels[m]}</th>`).join('')}
            <th style="text-align:left;padding:0.4rem 0.5rem;color:#94a3b8;font-size:0.75rem">Üret</th>
        </tr></thead>
        <tbody>${tableRows}</tbody>
    </table></div>`;
}

// ── Maliyet Takibi ──────────────────────────────────────────────────────────
window.initCostTrackerPage = async function () {
    const logEl = document.getElementById('costLogBody');
    const summEl = document.getElementById('costSummaryCards');
    if (!logEl) return;
    logEl.innerHTML = '<span style="color:#94a3b8">Yükleniyor...</span>';
    try {
        const res = await fetch(`${API}/api/cost-log`);
        const data = await res.json();
        const { log, total } = data;

        if (summEl) {
            summEl.innerHTML = [
                { label: 'Toplam Maliyet (TL)', value: `₺${total.tl.toFixed(2)}`, color: '#f59e0b' },
                { label: 'Toplam Maliyet (USD)', value: `$${total.usd.toFixed(4)}`, color: '#6ee7b7' },
                { label: 'Toplam Token', value: total.tokens.toLocaleString(), color: '#a5b4fc' },
            ].map(c => `<div style="background:#1e293b;border:1px solid #334155;border-radius:10px;padding:1rem;text-align:center">
                <div style="font-size:1.4rem;font-weight:700;color:${c.color}">${c.value}</div>
                <div style="font-size:0.75rem;color:#64748b;margin-top:0.25rem">${c.label}</div>
            </div>`).join('');
        }

        if (!log.length) { logEl.innerHTML = '<span style="color:#64748b">Henüz log yok</span>'; return; }

        logEl.innerHTML = log.map(e => {
            const d = new Date(e.timestamp);
            const time = `${d.toLocaleDateString('tr')} ${d.toLocaleTimeString('tr', { hour: '2-digit', minute: '2-digit' })}`;
            const model = e.model?.split('/').pop() || e.model;
            return `<div style="display:flex;gap:0.75rem;align-items:center;padding:0.4rem 0;border-bottom:1px solid rgba(51,65,85,0.5);flex-wrap:wrap">
                <span style="color:#64748b;font-size:0.75rem;min-width:9rem">${time}</span>
                <span style="background:rgba(99,102,241,0.15);color:#a5b4fc;padding:0.1rem 0.4rem;border-radius:4px;font-size:0.73rem">${model}</span>
                <span style="color:#94a3b8;font-size:0.78rem">↑${e.promptTokens} ↓${e.completionTokens}</span>
                <span style="color:#fcd34d;font-weight:600;font-size:0.82rem">₺${e.costTl.toFixed(4)}</span>
                <span style="color:#6ee7b7;font-size:0.78rem">$${e.costUsd.toFixed(6)}</span>
            </div>`;
        }).join('');
    } catch (e) {
        if (logEl) logEl.innerHTML = `<span style="color:#ef4444">Hata: ${e.message}</span>`;
    }
};

window.clearCostLog = async function () {
    if (!confirm('Maliyet logu temizlensin mi?')) return;
    await fetch(`${API}/api/cost-log`, { method: 'DELETE' });
    showToast('Log temizlendi', 'success');
    initCostTrackerPage();
};

// ── İçerik Arama ─────────────────────────────────────────────────────────────
window.doContentSearch = async function () {
    const q = document.getElementById('searchInput')?.value?.trim();
    const scope = document.getElementById('searchScope')?.value || 'all';
    const el = document.getElementById('searchResults');
    if (!el) return;
    if (!q || q.length < 2) { el.innerHTML = '<span style="color:#f59e0b">En az 2 karakter girin</span>'; return; }

    el.innerHTML = '<span style="color:#94a3b8">Aranıyor...</span>';
    try {
        const res = await fetch(`${API}/api/content-search?q=${encodeURIComponent(q)}&scope=${scope}`);
        const data = await res.json();
        if (!data.results?.length) { el.innerHTML = `<span style="color:#64748b">Sonuç bulunamadı: "${q}"</span>`; return; }

        const modLabels = { explanations: 'Anlatım', flashcards: 'Flashcard', stories: 'Hikaye', matching_games: 'Eşleştirme' };
        el.innerHTML = `<div style="color:#94a3b8;font-size:0.8rem;margin-bottom:0.75rem">${data.results.length} sonuç bulundu</div>` +
            data.results.map(r => {
                const badge = r.type === 'draft'
                    ? `<span style="background:rgba(99,102,241,0.2);color:#a5b4fc;padding:0.1rem 0.35rem;border-radius:3px;font-size:0.7rem">Taslak</span>`
                    : `<span style="background:rgba(16,185,129,0.15);color:#6ee7b7;padding:0.1rem 0.35rem;border-radius:3px;font-size:0.7rem">Yayınlandı</span>`;
                const modBadge = `<span style="background:rgba(148,163,184,0.1);color:#94a3b8;padding:0.1rem 0.35rem;border-radius:3px;font-size:0.7rem">${modLabels[r.moduleType] || r.moduleType}</span>`;
                return `<div style="background:#1e293b;border:1px solid #334155;border-radius:8px;padding:0.65rem 0.9rem;margin-bottom:0.5rem;display:flex;gap:0.6rem;align-items:center;flex-wrap:wrap">
                    ${badge}${modBadge}
                    <span style="color:#e2e8f0;font-size:0.85rem;flex:1">${r.title}</span>
                    <span style="color:#64748b;font-size:0.75rem">${r.topicName}</span>
                </div>`;
            }).join('');
    } catch (e) {
        el.innerHTML = `<span style="color:#ef4444">Hata: ${e.message}</span>`;
    }
};

// ── Gece Otomatik Üretim ──────────────────────────────────────────────────────
const _nightlyAllMods = ['explanations', 'flashcards', 'stories', 'matching_games'];
const _nightlyModLabels = { explanations: '📚 Anlatım', flashcards: '🃏 Flashcard', stories: '📖 Hikaye', matching_games: '🔗 Eşleştirme' };

window.initNightlyPage = async function () {
    try {
        const res = await fetch(`${API}/api/nightly-config`);
        const { config } = await res.json();
        document.getElementById('nightlyHour').value = config.hour ?? 2;
        document.getElementById('nightlyThreshold').value = config.minThreshold ?? 5;
        document.getElementById('nightlyCount').value = config.count ?? 5;
        document.getElementById('nightlyModel').value = config.model || 'anthropic/claude-3.5-haiku';
        updateNightlyToggleBtn(config.enabled);

        const modsEl = document.getElementById('nightlyModules');
        if (modsEl) {
            modsEl.innerHTML = _nightlyAllMods.map(m => {
                const active = (config.modules || []).includes(m);
                return `<button onclick="toggleNightlyMod('${m}', this)" data-active="${active}"
                    style="padding:0.3rem 0.7rem;border-radius:20px;border:1px solid ${active ? '#6366f1' : '#334155'};
                           background:${active ? 'rgba(99,102,241,0.2)' : 'transparent'};
                           color:${active ? '#a5b4fc' : '#94a3b8'};font-size:0.8rem;cursor:pointer">
                    ${_nightlyModLabels[m]}
                </button>`;
            }).join('');
        }
    } catch (e) { showToast('Config yüklenemedi: ' + e.message, 'error'); }
};

function updateNightlyToggleBtn(enabled) {
    const btn = document.getElementById('nightlyToggleBtn');
    if (!btn) return;
    btn.textContent = enabled ? '✅ Aktif' : '⏸ Pasif';
    btn.style.background = enabled ? '#10b981' : '#334155';
    btn.style.color = enabled ? 'white' : '#94a3b8';
    btn.dataset.enabled = enabled ? '1' : '0';
}

window.toggleNightlyMod = function (mod, btn) {
    const active = btn.dataset.active === 'true';
    btn.dataset.active = active ? 'false' : 'true';
    btn.style.borderColor = !active ? '#6366f1' : '#334155';
    btn.style.background = !active ? 'rgba(99,102,241,0.2)' : 'transparent';
    btn.style.color = !active ? '#a5b4fc' : '#94a3b8';
};

window.toggleNightly = async function () {
    const btn = document.getElementById('nightlyToggleBtn');
    const enabled = btn?.dataset.enabled !== '1';
    try {
        await fetch(`${API}/api/nightly-config`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ enabled }) });
        updateNightlyToggleBtn(enabled);
        showToast(`Gece üretimi ${enabled ? 'aktif' : 'pasif'}`, 'success');
    } catch (e) { showToast('Hata: ' + e.message, 'error'); }
};

window.saveNightlyConfig = async function () {
    const activeMods = Array.from(document.querySelectorAll('#nightlyModules button[data-active="true"]')).map(b => b.textContent.trim().replace(/^.*\s/, '').toLowerCase());
    const modMap = { 'Anlatım': 'explanations', 'Flashcard': 'flashcards', 'Hikaye': 'stories', 'Eşleştirme': 'matching_games' };
    const modules = activeMods.map(n => {
        const found = Object.entries(_nightlyModLabels).find(([, l]) => l.includes(n));
        return found ? found[0] : null;
    }).filter(Boolean);
    const selectedMods = Array.from(document.querySelectorAll('#nightlyModules button')).filter(b => b.dataset.active === 'true')
        .map(b => _nightlyAllMods.find(m => b.textContent.includes(_nightlyModLabels[m].split(' ')[1]))).filter(Boolean);
    const config = {
        hour: parseInt(document.getElementById('nightlyHour')?.value || '2'),
        minThreshold: parseInt(document.getElementById('nightlyThreshold')?.value || '5'),
        count: parseInt(document.getElementById('nightlyCount')?.value || '5'),
        model: document.getElementById('nightlyModel')?.value || 'anthropic/claude-3.5-haiku',
        modules: selectedMods.length ? selectedMods : ['explanations'],
    };
    try {
        await fetch(`${API}/api/nightly-config`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(config) });
        showToast('Ayarlar kaydedildi ✓', 'success');
    } catch (e) { showToast('Kayıt hatası: ' + e.message, 'error'); }
};

// ── Toplu Onayla + Push ────────────────────────────────────────────────────
window.approveAndPushSelected = async function () {
    const checked = document.querySelectorAll('.page-draft-cb:checked');
    if (checked.length === 0) { showToast('En az bir taslak seçin', 'warning'); return; }

    const indices = Array.from(checked).map(cb => parseInt(cb.dataset.index));
    if (!confirm(`✅ ${indices.length} taslak onaylanacak.\n\nDevam?`)) return;

    const groups = {};
    indices.forEach(i => {
        const d = _allPageDrafts[i];
        const key = `${d._topicId}::${d._moduleType}`;
        if (!groups[key]) groups[key] = { topicId: d._topicId, topicName: d._topicName, moduleType: d._moduleType, indices: [] };
        groups[key].indices.push(d._index);
    });

    const affectedModules = [...new Set(Object.values(groups).map(g => g.moduleType))];
    let approved = 0, errors = 0;

    for (const g of Object.values(groups)) {
        try {
            const res = await fetch(`${API}/api/ai-content/approve-draft`, {
                method: 'POST', headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ moduleType: g.moduleType, topicId: g.topicId, topicName: g.topicName, indices: g.indices })
            });
            const d = await res.json();
            if (d.success) approved += d.published || g.indices.length; else errors++;
        } catch { errors++; }
    }

    for (const mod of affectedModules) {
        try {
        } catch { }
    }

    const msg = errors > 0 ? `${approved} onaylandı, ${errors} hata, meto-data push edildi` : `✅ ${approved} yayınlandı + meto-data push edildi`;
    showToast(msg, errors > 0 ? 'warning' : 'success');
    await loadAllDrafts();
};

// Global scope'a ekle
window.refreshTopics = refreshTopics;

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


/* === modules\validation.js === */

/**
 * KPSS Dashboard - Validation Module
 * Contains logic for validating questions and checking duplicates.
 */

// Helper: Text Normalization
window.normalizeText = function (t) {
    return (t || '').toString()
        .toLocaleLowerCase('tr-TR')
        .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u')
        .replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c')
        .replace(/[^a-z0-9]/gi, '');
};

// 1. Validate Single Question
window.validateSingleQuestion = function (q) {
    const errors = [];

    // Question Text
    if (!q.q || (typeof q.q === 'string' && q.q.trim() === '')) {
        errors.push('Soru metni tamamen boş.');
    } else {
        const text = q.q.trim();
        if (text.length < 5) errors.push('Soru metni çok kısa.');
        // if (text.length > 2000) errors.push('Soru metni çok uzun (maks. 2000 karakter).');
    }

    // Options
    if (!q.o || !Array.isArray(q.o)) {
        errors.push('Şıklar (o) bir dizi olmalı.');
    } else {
        if (q.o.length !== 5) errors.push(`5 şık olmalı (Şuan: ${q.o.length}).`);
        if (q.o.some(opt => !opt || opt.toString().trim() === '')) {
            errors.push('Boş şık bulunuyor.');
        }
        // Duplicate Options Check/Warning could be here
    }

    // Answer
    if (q.a === undefined || q.a === null || isNaN(q.a)) {
        errors.push('Doğru cevap (a) belirtilmemiş.');
    } else {
        const ans = parseInt(q.a);
        if (ans < 0 || ans > 4) errors.push('Doğru cevap 0-4 arasında olmalı.');
    }

    // Difficulty
    if (q.d !== undefined) {
        const diff = parseInt(q.d);
        if (isNaN(diff) || diff < 1 || diff > 3) {
            errors.push('Zorluk (d) 1, 2 veya 3 olmalı.');
        }
    }

    return errors;
};

// 2. Find Duplicate Questions (Batch Internal Check)
window.findDuplicateQuestions = function (parsedArray) {
    if (!Array.isArray(parsedArray)) return [];

    const seenHashes = new Map(); // Hash -> [{index, options}]
    const duplicates = [];

    parsedArray.forEach((q, i) => {
        if (!q || !q.q) return;

        const cleanText = window.normalizeText(q.q);
        if (cleanText.length < 5) return;

        const currentOptions = (q.o || []).map(o => window.normalizeText(o));

        if (seenHashes.has(cleanText)) {
            const existingList = seenHashes.get(cleanText);

            // Check similarity with any of the existing questions with same text
            const isRealDup = existingList.some(existing => {
                const prevOptions = existing.options;
                // Count matching options (exact normalized match)
                const matchCount = prevOptions.filter(o => currentOptions.includes(o)).length;
                return matchCount >= 3; // 3/5 = 60% Threshold
            });

            if (isRealDup) {
                duplicates.push({
                    index: i + 1,
                    originalIndex: existingList[0].index + 1 // Point to the first occurrence
                });
            } else {
                // Same text but different options -> Add to list
                existingList.push({ index: i, options: currentOptions });
            }
        } else {
            seenHashes.set(cleanText, [{ index: i, options: currentOptions }]);
        }
    });

    return duplicates;
};


/* === modules\dashboard.js === */

/**
 * KPSS Dashboard - Dashboard Module
 * Contains logic for loading statistics, charts, and activity feeds.
 */

// Ensure API URL is available
if (typeof API === 'undefined') {
    window.API = window.API_URL || 'http://localhost:3456';
}

window.loadStats = async function () {
    try {
        const res = await fetch(API + '/stats');
        const data = await res.json();
        const el = (id, v) => { if (document.getElementById(id)) document.getElementById(id).innerText = v; };

        el('statQuestions', data.totalQuestions || 0);
        el('statFlashcards', data.totalFlashcards || 0);
        el('statStories', data.totalStories || 0);
        el('statGames', data.totalGames || 0);

        const list = document.getElementById('lessonStats');
        if (list && data.byLesson) {
            list.innerHTML = Object.keys(data.byLesson).sort().map(l => {
                const item = data.byLesson[l];
                const pct = Math.min(100, Math.round((item.count / (item.target || 1)) * 100));
                return `
                <div style="background:var(--input-bg); padding:1rem; border-radius:8px;">
                    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.5rem">
                        <span style="font-weight:600">${l}</span>
                        <span style="font-size:0.8rem; color:var(--text-muted)">${item.count} / ${item.target}</span>
                    </div>
                    <div style="height:6px; background:var(--bg); border-radius:3px; overflow:hidden">
                        <div style="height:100%; width:${pct}%; background:var(--accent); border-radius:3px; transition:width 1s ease"></div>
                    </div>
                </div>
             `;
            }).join('');
        }

        // PASTA GRAFİĞİ (PIE CHART)
        const pieCtx = document.getElementById('lessonPieChart');
        if (pieCtx && data.byLesson) {
            const lessons = Object.keys(data.byLesson);
            const counts = lessons.map(l => data.byLesson[l].count);
            const totalC = counts.reduce((a, b) => a + b, 0);

            if (totalC > 0) {
                let conic = [];
                let currentDeg = 0;
                const colors = ['#6366f1', '#22c55e', '#eab308', '#ef4444', '#8b5cf6', '#ec4899'];

                lessons.forEach((l, i) => {
                    const val = data.byLesson[l].count;
                    const deg = (val / totalC) * 360;
                    conic.push(`${colors[i % colors.length]} ${currentDeg}deg ${currentDeg + deg}deg`);
                    currentDeg += deg;
                });

                pieCtx.style.background = `conic-gradient(${conic.join(', ')})`;

                // Legend
                const legend = document.getElementById('pieLegend');
                if (legend) {
                    legend.innerHTML = lessons.map((l, i) => `
                        <div style="display:flex; align-items:center; gap:0.5rem; font-size:0.8rem">
                            <span style="width:10px; height:10px; background:${colors[i % colors.length]}; border-radius:50%"></span>
                            <span>${l}</span>
                        </div>
                     `).join('');
                }
            }
        }

        // SON AKTİVİTELER
        const acts = document.getElementById('recentActivityList');
        if (acts && data.recentActivity) {
            if (data.recentActivity.length > 0) {
                acts.innerHTML = data.recentActivity.map(f => {
                    const d = new Date(f.time);
                    const timeStr = d.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
                    return `
                     <div style="display:flex; justify-content:space-between; padding:0.5rem 0; border-bottom:1px solid var(--border)">
                        <div>
                            <div style="font-size:0.9rem; font-weight:500">${f.name}</div>
                            <div style="font-size:0.8rem; color:var(--text-muted)">${f.lesson}</div>
                        </div>
                        <div style="font-size:0.8rem; color:var(--text-muted); text-align:right">
                            <div>${d.toLocaleDateString('tr-TR')}</div>
                            <div>${timeStr}</div>
                        </div>
                     </div>
                     `;
                }).join('');
            } else {
                acts.innerHTML = '<div style="color:var(--text-muted); font-size:0.9rem; text-align:center; padding:1rem">Henüz aktivite yok.</div>';
            }
        }
    } catch (e) {
        console.error(e);
        showToast('Veri yükleme hatası: ' + e.message, 'error');
        // Also update UI to show error state instead of loading
        const acts = document.getElementById('recentActivityList');
        if (acts) acts.innerHTML = '<div style="color:#ef4444; font-size:0.9rem; text-align:center; padding:1rem">Hata oluştu.</div>';
    }
};


/* === modules\editor.js === */

/**
 * KPSS Dashboard - Editor Module
 * Contains logic for:
 * 1. Single Question Adding & Preview
 * 2. Bulk JSON Import & Validation
 * 3. Editing Questions (Modal)
 */

// Ensure API URL is available
if (typeof API === 'undefined') {
    window.API = window.API_URL || 'http://localhost:3456';
}

// Global State
window.currentQuestionImage = null;
window.previewQuestionsData = [];
window.topicsCache = [];

// ══════════════════════════════════════════════════════════════════════════
// 1. SINGLE QUESTION ADDING & PREVIEW
// ══════════════════════════════════════════════════════════════════════════

window.updatePreview = function () {
    // 1. Get Values
    const topicSel = document.getElementById('addTopicSelect');
    const topicText = topicSel.options[topicSel.selectedIndex]?.text || 'DERS ADI';
    const subtopic = document.getElementById('addSubtopic').value || 'Alt Başlık';

    // ContentEditable div uses innerHTML/innerText differently
    const questionEl = document.getElementById('addQuestionText');
    const question = questionEl?.innerText || questionEl?.textContent || 'Soru metni burada görünecek...';

    // 2. Update Header
    if (document.getElementById('prevLesson'))
        document.getElementById('prevLesson').innerText = topicText.split('(')[0].trim().toUpperCase();
    if (document.getElementById('prevSubtopic'))
        document.getElementById('prevSubtopic').innerText = subtopic;

    // 3. Update Question Body (with HTML support for rich text)
    const prevQ = document.getElementById('prevQuestion');
    if (prevQ) {
        prevQ.innerHTML = questionEl?.innerHTML || 'Soru metni burada görünecek...';
    }

    // 4. Update Image Preview in Mockup
    const mockupImg = document.getElementById('prevImage');
    if (mockupImg && window.currentQuestionImage) {
        mockupImg.style.display = 'block';
        mockupImg.src = window.currentQuestionImage;
    } else if (mockupImg) {
        mockupImg.style.display = 'none';
    }

    // 5. Update Options
    const correctIdx = parseInt(document.getElementById('addCorrectAns').value);

    ['A', 'B', 'C', 'D', 'E'].forEach((label, i) => {
        const val = document.getElementById('opt' + i).value || `Seçenek ${label}`;
        const el = document.getElementById('prevOpt' + i);
        if (!el) return;

        el.innerText = `${label}) ${val}`;

        // Reset styles
        el.style.background = 'white';
        el.style.color = '#334155';
        el.style.border = '1px solid #e2e8f0';
        el.style.padding = '1rem';
        el.style.borderRadius = '12px';
        el.style.fontWeight = 'normal';

        // Highlight correct answer mock
        if (i === correctIdx) {
            el.style.background = '#dcfce7';
            el.style.color = '#166534';
            el.style.border = '1px solid #22c55e';
            el.style.fontWeight = 'bold';
        }
    });
};

window.formatText = function (command) {
    document.execCommand(command, false, null);
    document.getElementById('addQuestionText').focus();
};

window.handleImageUpload = function (event) {
    const file = event.target.files[0];
    if (!file) return;

    if (file.size > 2 * 1024 * 1024) {
        showToast('Görsel 2MB\'dan küçük olmalı', 'error');
        return;
    }

    const reader = new FileReader();
    reader.onload = function (e) {
        window.currentQuestionImage = e.target.result;
        document.getElementById('imageThumb').src = e.target.result;
        document.getElementById('imagePreviewThumb').style.display = 'block';
        document.getElementById('removeImageBtn').style.display = 'block';
        window.updatePreview();
    };
    reader.readAsDataURL(file);
};

window.removeImage = function () {
    window.currentQuestionImage = null;
    document.getElementById('addImage').value = '';
    document.getElementById('imagePreviewThumb').style.display = 'none';
    document.getElementById('removeImageBtn').style.display = 'none';
    window.updatePreview();
};

window.addQuestion = async function () {
    const topicId = document.getElementById('addTopicSelect').value;
    if (!topicId) return showToast('Lütfen konu seçin', 'error');

    const questionEl = document.getElementById('addQuestionText');
    const questionText = questionEl?.innerHTML || questionEl?.innerText || '';

    const question = {
        topicId: topicId,
        subtopicId: document.getElementById('addSubtopicId')?.value || '',
        subtopic: document.getElementById('addSubtopic').value,
        q: questionText,
        o: [
            document.getElementById('opt0').value, document.getElementById('opt1').value,
            document.getElementById('opt2').value, document.getElementById('opt3').value,
            document.getElementById('opt4').value
        ],
        a: parseInt(document.getElementById('addCorrectAns').value),
        e: document.getElementById('addExplanation').value,
        d: parseInt(document.getElementById('addDifficulty')?.value || 2),
        tags: (document.getElementById('addTags')?.value || '').split(',').map(t => t.trim()).filter(t => t),
        img: window.currentQuestionImage || null
    };

    if (!question.q || question.q === '<br>') return showToast('Soru metni boş', 'error');

    try {
        const res = await fetch(API + '/add', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ topicId, questions: [question] })
        });
        const data = await res.json();
        if (data.success) {
            showToast('Soru kaydedildi!', 'success');
            // Reset form
            questionEl.innerHTML = '';
            document.getElementById('addSubtopicId').value = '';
            document.getElementById('addSubtopic').value = '';
            document.getElementById('addExplanation').value = '';
            document.getElementById('addTags').value = '';
            document.getElementById('addDifficulty').value = '2';
            ['opt0', 'opt1', 'opt2', 'opt3', 'opt4'].forEach(id => document.getElementById(id).value = '');
            window.removeImage();
            window.updatePreview();
            window.loadTopicCount(); // Refresh count
        }
    } catch (e) { showToast('Hata', 'error'); }
};

// ══════════════════════════════════════════════════════════════════════════
// 2. DROPDOWN & DATA LOGIC
// ══════════════════════════════════════════════════════════════════════════

window.loadAddLessons = async function () {
    const lessonSelect = document.getElementById('addLesson');
    if (!lessonSelect) return;

    lessonSelect.innerHTML = '<option value="">Ders Seçiniz...</option>';

    const lessons = [
        { id: 'tarih', name: 'Tarih' },
        { id: 'cografya', name: 'Coğrafya' },
        { id: 'vatandaslik', name: 'Vatandaşlık' },
        { id: 'turkce', name: 'Türkçe' },
        { id: 'matematik', name: 'Matematik' },
        { id: 'egitim', name: 'Eğitim Bilimleri' },
        { id: 'oabt', name: 'ÖABT' }
    ];

    lessons.forEach(l => {
        const opt = document.createElement('option');
        opt.value = l.id;
        opt.innerText = l.name;
        lessonSelect.appendChild(opt);
    });
};

window.loadAddTopics = async function () {
    const lessonId = document.getElementById('addLesson').value;
    const topicSelect = document.getElementById('addTopic');
    const searchInput = document.getElementById('addTopicSearch')?.value?.toLowerCase() || '';

    topicSelect.innerHTML = '<option value="">Konu Yükleniyor...</option>';

    if (!lessonId) {
        topicSelect.innerHTML = '<option value="">Önce Ders Seçin...</option>';
        return;
    }

    try {
        const res = await fetch(API + '/topics');
        const topics = await res.json();
        window.topicsCache = topics;

        const lessonNameMap = {
            'tarih': 'TARİH', 'cografya': 'COĞRAFYA', 'vatandaslik': 'VATANDAŞLIK',
            'turkce': 'TÜRKÇE', 'matematik': 'MATEMATİK', 'egitim': 'EĞİTİM BİLİMLERİ', 'oabt': 'ÖABT'
        };
        const lessonName = lessonNameMap[lessonId] || lessonId.toUpperCase();
        let filteredTopics = topics.filter(t => t.lesson === lessonName);

        // Apply search filter if there's a search term
        if (searchInput) {
            filteredTopics = filteredTopics.filter(t =>
                t.name.toLowerCase().includes(searchInput) ||
                t.id.toLowerCase().includes(searchInput)
            );
        }

        topicSelect.innerHTML = '<option value="">Konu Seçiniz...</option>';

        if (filteredTopics.length > 0) {
            filteredTopics.forEach(t => {
                const opt = document.createElement('option');
                opt.value = t.id;
                opt.innerText = `${t.name} (${t.count || 0})`;
                topicSelect.appendChild(opt);
            });
        } else {
            topicSelect.innerHTML = '<option value="">Bu derste konu bulunamadı</option>';
        }
    } catch (e) {
        console.error(e);
        topicSelect.innerHTML = '<option value="">Hata!</option>';
    }
};

window.loadTopicCount = function () {
    const sel = document.getElementById('addTopicSelect');
    const badge = document.getElementById('topicQuestionCount');
    if (!badge) return;

    if (!sel || !sel.value) {
        badge.style.display = 'none';
        return;
    }

    const topic = window.topicsCache?.find(t => t.id === sel.value);
    if (topic) {
        badge.innerText = `${topic.count} soru`;
        badge.style.display = 'inline-block';
    } else {
        badge.style.display = 'none';
    }
};

// Open editor for selected topic (from add page)
window.openEditorForTopic = async function () {
    const topicId = document.getElementById('addTopic')?.value;

    if (!topicId) {
        showToast('Lütfen önce bir konu seçin', 'warning');
        return;
    }

    showToast('Editör yükleniyor...', 'info');

    try {
        // Load questions for this topic
        const res = await fetch(API + `/questions/${encodeURIComponent(topicId)}`);
        const questions = await res.json();

        // Convert to JSON and populate the bulk editor
        const questionsArray = Array.isArray(questions) ? questions : (questions.questions || []);

        // Switch to browse page to edit questions
        showPage('browse');

        // Wait for browse page to load then select the topic
        setTimeout(() => {
            const browseSelect = document.getElementById('browseTopics');
            if (browseSelect) {
                browseSelect.value = topicId;
                window.loadBrowseQuestions(topicId);
                showToast(`${questionsArray.length} soru yüklendi`, 'success');
            }
        }, 100);

    } catch (e) {
        console.error(e);
        showToast('Sorular yüklenemedi: ' + e.message, 'error');
    }
};

window.fetchWithTimeout = async function (url, options = {}, timeoutMs = 15000) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
    try {
        return await fetch(url, { ...options, signal: controller.signal });
    } finally {
        clearTimeout(timeoutId);
    }
};

window.renderHtmlInBatches = async function (targetEl, htmlItems, batchSize = 20) {
    if (!targetEl) return;

    targetEl.innerHTML = '';

    for (let i = 0; i < htmlItems.length; i += batchSize) {
        const batchWrapper = document.createElement('div');
        batchWrapper.innerHTML = htmlItems.slice(i, i + batchSize).join('');

        while (batchWrapper.firstChild) {
            targetEl.appendChild(batchWrapper.firstChild);
        }

        if (i + batchSize < htmlItems.length) {
            await new Promise(resolve => requestAnimationFrame(resolve));
        }
    }
};

// Load and display questions for selected topic in Add page
window.loadAddQuestions = async function (topicIdOrEvent) {
    const topicId = typeof topicIdOrEvent === 'string'
        ? topicIdOrEvent
        : topicIdOrEvent?.target?.value || document.getElementById('addTopic')?.value;
    const questionsSection = document.getElementById('addQuestionsSection');
    const questionsList = document.getElementById('addQuestionsList');
    const questionsTitle = document.getElementById('addQuestionsTitle');
    const esc = window.escapeHtml || function (value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    };

    console.log('[loadAddQuestions] Starting with topicId:', topicId);

    if (!topicId) {
        console.log('[loadAddQuestions] No topicId, hiding section');
        if (questionsSection) questionsSection.style.display = 'none';
        return;
    }

    // Show questions section
    if (questionsSection) questionsSection.style.display = 'block';
    if (questionsList) questionsList.innerHTML = '<div class="loading"><span class="material-icons-round">sync</span> Sorular yükleniyor...</div>';

    try {
        const url = API + `/questions/${encodeURIComponent(topicId)}`;
        console.log('[loadAddQuestions] Fetching from:', url);

        const res = await window.fetchWithTimeout(url);
        console.log('[loadAddQuestions] Response status:', res.status);

        if (!res.ok) {
            throw new Error(`HTTP error! status: ${res.status}`);
        }

        const questions = await res.json();
        console.log('[loadAddQuestions] Questions data:', typeof questions, Array.isArray(questions) ? questions.length : 'not array');

        const questionsArray = Array.isArray(questions) ? questions : (questions.questions || []);

        // Give the browser a paint opportunity before the potentially large render.
        await new Promise(requestAnimationFrame);

        // Update title with count
        if (questionsTitle) questionsTitle.innerText = `Sorular (${questionsArray.length})`;

        // Render questions
        if (questionsArray.length === 0) {
            questionsList.innerHTML = `
                <div class="empty-state" style="text-align:center; padding:3rem; color:var(--text-muted);">
                    <span class="material-icons-round" style="font-size:3rem; margin-bottom:1rem;">inbox</span>
                    <p>Bu konuda henüz soru yok</p>
                    <button class="btn btn-primary" onclick="showAddQuestionModal()" style="margin-top:1rem;">
                        <span class="material-icons-round">add</span>
                        İlk Soruyu Ekle
                    </button>
                </div>
            `;
        } else {
            console.log('[loadAddQuestions] Rendering questions:', questionsArray.length);
            const questionCards = questionsArray.map((q, idx) => {
                const questionId = q.id ?? String(idx);
                try {
                    return `
                    <div style="background:var(--bg-card); border:1px solid var(--border); border-radius:16px; padding:1.25rem; margin-bottom:1rem; box-shadow:0 2px 8px rgba(0,0,0,0.04); transition:all 0.2s; position:relative;">
                        <div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:0.75rem;">
                            <div style="display:flex; gap:0.5rem; align-items:center;">
                                <span style="background:linear-gradient(135deg,var(--primary),#3b82f6); color:white; padding:4px 12px; border-radius:20px; font-size:0.75rem; font-weight:600;">${q.id || 'ID ' + (idx + 1)}</span>
                                ${q.topicId ? `<span style="background:var(--bg-hover); color:var(--text-muted); padding:4px 8px; border-radius:12px; font-size:0.7rem; font-weight:500;">Topic: ${esc(q.topicId)}</span>` : ''}
                                ${q.subtopicId ? `<span style="background:var(--bg-hover); color:var(--text-muted); padding:4px 8px; border-radius:12px; font-size:0.7rem; font-weight:500;">${esc(q.subtopicId)}</span>` : ''}
                            </div>
                            <div class="btn-group" style="display:flex; gap:0.5rem;">
                                <button class="btn btn-secondary" onclick="editAddQuestion('${questionId}')" style="padding:6px 12px; font-size:0.75rem; border-radius:8px; background:var(--bg-hover); border:1px solid var(--border); color:var(--text); cursor:pointer; transition:all 0.2s;" onmouseover="this.style.background='var(--primary)'; this.style.color='white';" onmouseout="this.style.background='var(--bg-hover)'; this.style.color='var(--text)';">
                                    <span class="material-icons-round" style="font-size:1rem; vertical-align:middle;">edit</span>
                                </button>
                                <button class="btn btn-danger" onclick="deleteAddQuestion('${questionId}')" style="padding:6px 12px; font-size:0.75rem; border-radius:8px; background:rgba(239,68,68,0.1); border:1px solid rgba(239,68,68,0.2); color:#ef4444; cursor:pointer; transition:all 0.2s;" onmouseover="this.style.background='#ef4444'; this.style.color='white';" onmouseout="this.style.background='rgba(239,68,68,0.1)'; this.style.color='#ef4444';">
                                    <span class="material-icons-round" style="font-size:1rem; vertical-align:middle;">delete</span>
                                </button>
                            </div>
                        </div>
                        ${q.subtopic ? `
                        <div style="margin-bottom:0.5rem;">
                            <span style="color:var(--text-muted); font-size:0.75rem; font-weight:500;">ALT KONU:</span>
                            <span style="color:var(--primary); font-size:0.75rem; font-weight:600; margin-left:0.5rem;">${esc(q.subtopic)}</span>
                        </div>
                        ` : ''}
                        <div style="color:var(--text); font-weight:500; line-height:1.5; margin-bottom:0.75rem;">${esc(q.q || '')}</div>
                        <div style="display:grid; grid-template-columns:1fr 1fr; gap:0.5rem; margin-bottom:0.75rem;">
                            ${(q.o || []).map((opt, i) => `
                                <div style="display:flex; align-items:center; padding:0.5rem; border-radius:8px; background:${i === q.a ? 'rgba(34,197,94,0.1)' : 'var(--bg-hover)'}; border:1px solid ${i === q.a ? 'rgba(34,197,94,0.3)' : 'var(--border)'};">
                                    <span style="display:inline-flex; align-items:center; justify-content:center; width:24px; height:24px; border-radius:50%; font-size:0.7rem; font-weight:600; margin-right:0.5rem; background:${i === q.a ? '#22c55e' : 'var(--text-muted)'}; color:white;">${String.fromCharCode(65 + i)}</span>
                                    <span style="font-size:0.85rem; color:var(--text);">${esc(opt || '')}</span>
                                </div>
                            `).join('')}
                        </div>
                        ${q.e ? `
                        <div style="margin-top:0.75rem; padding:0.75rem; background:var(--bg-hover); border-radius:8px; border-left:3px solid var(--primary);">
                            <div style="font-size:0.75rem; color:var(--text-muted); margin-bottom:0.25rem;">Açıklama</div>
                            <div style="font-size:0.85rem; color:var(--text); line-height:1.4;">${esc(q.e)}</div>
                        </div>
                        ` : ''}
                    </div>
                `;
                } catch (e) {
                    console.error('[loadAddQuestions] Error rendering question', idx, e);
                    return `<div style="color:red;">Soru render hatası: ${e.message}</div>`;
                }
            });

            await window.renderHtmlInBatches(questionsList, questionCards, 15);
            console.log('[loadAddQuestions] Render complete. HTML length:', questionsList.innerHTML.length);
        }

        // Force visibility after a short delay to ensure DOM has painted
        setTimeout(() => {
            if (questionsSection) questionsSection.style.display = 'block';
            console.log('[loadAddQuestions] Forced section visibility. Current display:', questionsSection?.style.display);
        }, 50);
    } catch (e) {
        console.error('[loadAddQuestions] Error:', e);
        if (questionsList) questionsList.innerHTML = `<p style="color:#ef4444; text-align:center; padding:2rem;">Sorular yüklenemedi: ${e.message}</p>`;
    }
};

// Edit question from Add page - fetch and open modal
window.editAddQuestion = async function (questionId) {
    const topicId = document.getElementById('addTopic')?.value;
    if (!topicId) {
        showToast('Konu seçilmedi', 'error');
        return;
    }

    showToast('Soru yükleniyor...', 'info');

    try {
        // Fetch the question
        const res = await window.fetchWithTimeout(API + `/questions/${encodeURIComponent(topicId)}/${encodeURIComponent(questionId)}`);
        if (!res.ok) throw new Error('Soru bulunamadı');

        const payload = await res.json();
        const question = payload.question || payload;

        // Open edit modal with the question data
        window.openEditModal({ ...question, id: question.id || questionId }, topicId);

    } catch (e) {
        console.error('Edit error:', e);
        showToast('Soru yüklenemedi: ' + e.message, 'error');
    }
};

// Delete question from Add page
window.deleteAddQuestion = async function (questionId) {
    const topicId = document.getElementById('addTopic')?.value;
    if (!topicId) return;

    if (!confirm('Soru silinecek. Emin misiniz?')) return;

    try {
        const res = await fetch(API + `/questions/${encodeURIComponent(topicId)}/${encodeURIComponent(questionId)}`, {
            method: 'DELETE'
        });
        const data = await res.json();

        if (data.success) {
            showToast('Soru silindi', 'success');
            window.loadAddQuestions(); // Refresh list
        } else {
            showToast('Silme hatası: ' + data.error, 'error');
        }
    } catch (e) {
        showToast('Bağlantı hatası', 'error');
    }
};

// ══════════════════════════════════════════════════════════════════════════
// 4. EDIT MODAL (Global)
// ══════════════════════════════════════════════════════════════════════════

window.openEditModal = function (question, topicId) {
    const safeSet = (id, val) => {
        const el = document.getElementById(id);
        if (el) el.value = val;
    };

    safeSet('editQuestionId', question.id);
    safeSet('editTopicId', topicId);
    safeSet('editSubtopicId', question.subtopicId || '');
    safeSet('editSubtopic', question.subtopic || '');
    safeSet('editQuestionText', question.q || '');
    safeSet('editCorrectAns', question.a || 0);
    safeSet('editExplanation', question.e || '');

    ['editOpt0', 'editOpt1', 'editOpt2', 'editOpt3', 'editOpt4'].forEach((id, i) => {
        safeSet(id, question.o?.[i] || '');
    });

    // Set correct answer in select dropdown
    const correctSelect = document.getElementById('editCorrectAns');
    if (correctSelect) {
        correctSelect.value = question.a || 0;
    }

    const radios = document.getElementsByName('correct');
    if (radios.length > 0) {
        for (let r of radios) r.checked = false;
        const correctIdx = question.a || 0;
        if (radios[correctIdx]) radios[correctIdx].checked = true;
    }

    const modal = document.getElementById('editModal');
    if (modal) {
        modal.style.display = 'flex';
    }
};

// Alias
window.editQuestion = window.openEditModal;

window.closeEditModal = function () {
    const modal = document.getElementById('editModal');
    if (modal) modal.style.display = 'none';
};

window.updateMobilePreview = function () {
    const qTextRaw = document.getElementById('editQuestionText').value || 'Soru metni bekleniyor...';
    const diff = parseInt(document.getElementById('editDifficulty').value);
    const imgUrl = document.getElementById('editImage') ? document.getElementById('editImage').value : '';

    let parsedText = qTextRaw
        .replace(/\*\*(.*?)\*\*/g, '<b>$1</b>')
        .replace(/\*(.*?)\*/g, '<i>$1</i>');

    let contentHtml = '';
    if (imgUrl && imgUrl.trim()) {
        contentHtml += `<img src="${imgUrl}" style="width:100%; border-radius:8px; margin-bottom:12px; object-fit:cover; max-height:200px">`;
    }
    contentHtml += parsedText;

    let correctIdx = 0;
    const radios = document.getElementsByName('correct');
    for (let r of radios) { if (r.checked) correctIdx = parseInt(r.value); }
    document.getElementById('editCorrectAns').value = correctIdx;

    const qTextEl = document.getElementById('mobileQuestionText');
    if (qTextEl) qTextEl.innerHTML = contentHtml;

    const diffBadge = document.getElementById('mobileDiffBadge');
    if (diffBadge) {
        if (diff === 1) { diffBadge.innerText = 'Kolay'; diffBadge.style.color = '#22c55e'; diffBadge.style.background = 'rgba(34,197,94,0.1)'; }
        else if (diff === 3) { diffBadge.innerText = 'Zor'; diffBadge.style.color = '#ef4444'; diffBadge.style.background = 'rgba(239,68,68,0.1)'; }
        else { diffBadge.innerText = 'Orta'; diffBadge.style.color = '#eab308'; diffBadge.style.background = 'rgba(234,179,8,0.1)'; }
    }

    const optsContainer = document.getElementById('mobileOptions');
    if (optsContainer) {
        optsContainer.innerHTML = '';
        ['editOpt0', 'editOpt1', 'editOpt2', 'editOpt3', 'editOpt4'].forEach((id, i) => {
            const el = document.getElementById(id);
            if (!el) return;
            const val = el.value;
            if (!val) return;
            const isCorrect = (i === correctIdx);
            const letter = ['A', 'B', 'C', 'D', 'E'][i];
            const parsedVal = val.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>');

            optsContainer.innerHTML += `
                <div style="background:${isCorrect ? '#22c55e' : '#334155'}; padding:16px; border-radius:12px; display:flex; gap:12px; align-items:center; transition:all 0.2s">
                    <div style="width:28px; height:28px; border-radius:50%; background:${isCorrect ? 'white' : 'rgba(255,255,255,0.1)'}; color:${isCorrect ? '#22c55e' : '#94a3b8'}; display:flex; align-items:center; justify-content:center; font-weight:bold; font-size:0.8rem">
                        ${letter}
                    </div>
                    <div style="color:${isCorrect ? 'white' : '#e2e8f0'}; font-size:0.9rem; flex:1">
                        ${parsedVal}
                    </div>
                    ${isCorrect ? '<span class="material-icons-round" style="color:white; font-size:1.2rem">check_circle</span>' : ''}
                </div>
            `;
        });
    }
};

window.setCorrectPreview = function () {
    window.updateMobilePreview();
};

// Save edited question and refresh Add page list
window.saveEditedQuestion = async function () {
    const topicId = document.getElementById('editTopicId').value;
    const questionId = document.getElementById('editQuestionId').value;

    const updatedQuestion = {
        id: questionId,
        topicId: topicId,
        subtopicId: document.getElementById('editSubtopicId')?.value || '',
        subtopic: document.getElementById('editSubtopic')?.value || '',
        q: document.getElementById('editQuestionText').value,
        o: [
            document.getElementById('editOpt0').value, document.getElementById('editOpt1').value,
            document.getElementById('editOpt2').value, document.getElementById('editOpt3').value,
            document.getElementById('editOpt4').value
        ],
        a: parseInt(document.getElementById('editCorrectAns').value),
        e: document.getElementById('editExplanation')?.value || ''
    };

    // If preview mode, update local state
    if (topicId === '_preview_') {
        const index = parseInt(questionId);
        if (window.previewQuestionsData && window.previewQuestionsData[index]) {
            window.previewQuestionsData[index] = { ...window.previewQuestionsData[index], ...updatedQuestion };
            document.getElementById('bulkJsonInput').value = JSON.stringify(window.previewQuestionsData, null, 2);
            window.validateJsonLive();
            window.previewQuestions();
            showToast('Soru güncellendi!', 'success');
            window.closeEditModal();
        }
        return;
    }

    // Handle database mode - save to server
    try {
        const res = await fetch(API + `/questions/${encodeURIComponent(topicId)}/${encodeURIComponent(questionId)}`, {
            method: 'PUT', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ...updatedQuestion, id: questionId })
        });

        const data = await res.json();
        if (data.success) {
            showToast('Soru güncellendi!', 'success');
            window.closeEditModal();
            // Refresh the Add page questions list if we're on that page
            if (window.loadAddQuestions) window.loadAddQuestions();
            // Also refresh browse questions if available
            if (window.loadBrowseQuestions) window.loadBrowseQuestions();
        } else {
            showToast('Güncelleme hatası: ' + (data.error || 'Bilinmeyen hata'), 'error');
        }
    } catch (e) {
        showToast('Bağlantı hatası: ' + e.message, 'error');
    }
};

// Keyboard shortcut (Ctrl+Shift+F for format)
document.addEventListener('keydown', function (e) {
    if (e.ctrlKey && e.shiftKey && e.key === 'F') {
        e.preventDefault();
        window.formatJsonEditor();
    }
});


/* === modules\browse.js === */

/**
 * KPSS Dashboard - Browse Module
 * Contains logic for:
 * 1. listing, filtering and searching questions
 * 2. deleting questions
 */

// Ensure API URL is available
if (typeof API === 'undefined') {
    window.API = window.API_URL || 'http://localhost:3456';
}

window.currentBrowseData = [];

// Initialize browse page
window.initBrowse = async function () {
    await window.loadBrowseTopics();
    // Add topic search input listener if exists
    const searchInput = document.getElementById('browseTopicSearch');
    if (searchInput) {
        searchInput.addEventListener('input', window.filterBrowseTopics);
    }
};

// Filter topics by search term
window.filterBrowseTopics = function () {
    const searchTerm = document.getElementById('browseTopicSearch')?.value?.toLowerCase() || '';
    const lessonId = document.getElementById('browseLesson')?.value;
    if (!window.topicsCache) return;

    let filtered = window.topicsCache;

    // Filter by lesson if selected
    if (lessonId) {
        const lessonNameMap = {
            'tarih': 'TARİH', 'cografya': 'COĞRAFYA', 'vatandaslik': 'VATANDAŞLIK',
            'turkce': 'TÜRKÇE', 'matematik': 'MATEMATİK', 'egitim': 'EĞİTİM BİLİMLERİ', 'oabt': 'ÖABT'
        };
        const lessonName = lessonNameMap[lessonId] || lessonId.toUpperCase();
        filtered = filtered.filter(t => t.lesson === lessonName);
    }

    // Filter by search term
    if (searchTerm) {
        filtered = filtered.filter(t =>
            t.name.toLowerCase().includes(searchTerm) ||
            t.lesson.toLowerCase().includes(searchTerm) ||
            t.id.toLowerCase().includes(searchTerm)
        );
    }

    window.renderBrowseTopics(filtered);
};

// Load topics when lesson is selected (for Browse page)
window.loadBrowseTopicsByLesson = async function () {
    const lessonId = document.getElementById('browseLesson')?.value;
    const browseTopicsEl = document.getElementById('browseTopics');

    if (!browseTopicsEl) return;

    if (!lessonId) {
        browseTopicsEl.innerHTML = '<div class="loading"><span class="material-icons-round">sync</span> Önce ders seçin...</div>';
        return;
    }

    browseTopicsEl.innerHTML = '<div class="loading"><span class="material-icons-round">sync</span> Konular yükleniyor...</div>';

    try {
        const res = await fetch(API + '/topics');
        const topics = await res.json();
        window.topicsCache = topics;

        // Filter by selected lesson
        const lessonNameMap = {
            'tarih': 'TARİH', 'cografya': 'COĞRAFYA', 'vatandaslik': 'VATANDAŞLIK',
            'turkce': 'TÜRKÇE', 'matematik': 'MATEMATİK', 'egitim': 'EĞİTİM BİLİMLERİ', 'oabt': 'ÖABT'
        };
        const lessonName = lessonNameMap[lessonId] || lessonId.toUpperCase();
        const filteredTopics = topics.filter(t => t.lesson === lessonName);

        window.renderBrowseTopics(filteredTopics);
    } catch (e) {
        console.error('Topics yüklenemedi:', e);
        browseTopicsEl.innerHTML = '<p style="color:#ef4444; text-align:center; padding:2rem">Konular yüklenemedi</p>';
    }
};

window.searchQuestions = async function () {
    const q = document.getElementById('searchInput')?.value;
    if (!q || q.length < 2) {
        showToast('En az 2 karakter girin', 'warning');
        return;
    }
    try {
        const res = await fetch(API + `/search?q=${encodeURIComponent(q)}`);
        const data = await res.json();
        window.renderBrowseList(data.results || [], null);
    } catch (e) {
        showToast('Arama hatası', 'error');
        console.error(e);
    }
};

window.loadBrowseTopics = async function () {
    try {
        const res = await fetch(API + '/topics');
        const topics = await res.json();
        window.topicsCache = topics;

        // Find the browse topics container (could be a select or div)
        const browseTopicsEl = document.getElementById('browseTopics');
        if (!browseTopicsEl) return;

        // Check if it's a select element
        if (browseTopicsEl.tagName === 'SELECT') {
            browseTopicsEl.innerHTML = '<option value="">Konu Seçin...</option>';

            const lessonNameMap = {
                'tarih': 'TARİH', 'cografya': 'COĞRAFYA', 'vatandaslik': 'VATANDAŞLIK',
                'turkce': 'TÜRKÇE', 'matematik': 'MATEMATİK', 'egitim': 'EĞİTİM BİLİMLERİ', 'oabt': 'ÖABT'
            };

            topics.forEach(t => {
                const opt = document.createElement('option');
                opt.value = t.id;
                opt.innerText = `${lessonNameMap[t.lesson] || t.lesson} - ${t.name} (${t.count || 0})`;
                browseTopicsEl.appendChild(opt);
            });

            // Add change listener
            browseTopicsEl.onchange = () => window.loadBrowseQuestions();
        } else {
            // Render as a list/grid
            window.renderBrowseTopics(topics);
        }
    } catch (e) {
        console.error('Topics yüklenemedi:', e);
        const browseTopicsEl = document.getElementById('browseTopics');
        if (browseTopicsEl) {
            browseTopicsEl.innerHTML = '<p style="color:#ef4444; text-align:center; padding:2rem">Konular yüklenemedi</p>';
        }
    }
};

// Render topics as clickable cards
window.renderBrowseTopics = function (topics) {
    const container = document.getElementById('browseTopicsList') || document.getElementById('browseTopics');
    if (!container) return;

    if (!topics || topics.length === 0) {
        container.innerHTML = '<p style="color:var(--text-muted); text-align:center; padding:2rem">Konu bulunamadı</p>';
        return;
    }

    const lessonNameMap = {
        'tarih': 'Tarih', 'cografya': 'Coğrafya', 'vatandaslik': 'Vatandaşlık',
        'turkce': 'Türkçe', 'matematik': 'Matematik', 'egitim': 'Eğitim Bilimleri', 'oabt': 'ÖABT'
    };

    container.innerHTML = topics.map(t => `
        <div onclick="selectBrowseTopic('${t.id}')" style="cursor:pointer; background:var(--bg-card); border:1px solid var(--border); border-radius:12px; padding:1rem; margin-bottom:0.75rem; transition:all 0.2s; hover:transform:translateY(-2px)"
             onmouseover="this.style.borderColor='var(--primary)'" onmouseout="this.style.borderColor='var(--border)'">
            <div style="font-weight:600; margin-bottom:0.25rem">${t.name}</div>
            <div style="font-size:0.85rem; color:var(--text-secondary); display:flex; justify-content:space-between; align-items:center">
                <span>${lessonNameMap[t.lesson] || t.lesson}</span>
                <span style="background:var(--primary); color:white; padding:2px 8px; border-radius:12px; font-size:0.75rem">${t.count || 0} soru</span>
            </div>
        </div>
    `).join('');
};

window.selectBrowseTopic = function (topicId) {
    const browseTopicsEl = document.getElementById('browseTopics');
    if (browseTopicsEl && browseTopicsEl.tagName === 'SELECT') {
        browseTopicsEl.value = topicId;
    }
    window.loadBrowseQuestions(topicId);
};

window.loadBrowseQuestions = async function (topicIdOrEvent) {
    const selectedTopic = typeof topicIdOrEvent === 'string'
        ? topicIdOrEvent
        : topicIdOrEvent?.target?.value || document.getElementById('browseTopics')?.value;
    if (!selectedTopic) {
        const listEl = document.getElementById('browseList') || document.getElementById('browseTopics');
        if (listEl) {
            listEl.innerHTML = '<p style="color:var(--text-muted); text-align:center; padding:2rem">Konu seçin veya arama yapın</p>';
        }
        return;
    }

    const listEl = document.getElementById('browseList') || document.getElementById('browseTopics');
    if (!listEl) return;

    window.currentBrowseTopicId = selectedTopic;

    try {
        listEl.innerHTML = '<div style="text-align:center; padding:2rem"><div style="width:30px; height:30px; border:3px solid var(--border); border-top-color:var(--primary); border-radius:50%; animation:spin 1s linear infinite; margin:0 auto"></div><p style="margin-top:1rem; color:var(--text-muted)">Yükleniyor...</p></div>';

        const res = await window.fetchWithTimeout(API + `/questions/${encodeURIComponent(selectedTopic)}`);
        if (!res.ok) {
            throw new Error(`HTTP error! status: ${res.status}`);
        }
        const data = await res.json();
        window.currentBrowseData = Array.isArray(data) ? data : (data.questions || []);

        await new Promise(requestAnimationFrame);

        await window.renderBrowseList(window.currentBrowseData, selectedTopic);

    } catch (e) {
        console.error(e);
        listEl.innerHTML = '<p style="color:#ef4444; text-align:center; padding:2rem">Sorular yüklenemedi</p>';
        showToast('Yükleme hatası', 'error');
    }
};

window.renderBrowseList = async function (questions, topicId) {
    const listEl = document.getElementById('browseList') || document.getElementById('browseTopics');
    if (!listEl) return;

    if (!questions || questions.length === 0) {
        listEl.innerHTML = '<p style="color:var(--text-muted); text-align:center; padding:2rem">Bu konuda soru bulunamadı</p>';
        return;
    }

    const answerLabels = ['A', 'B', 'C', 'D', 'E'];

    console.log('[renderBrowseList] Rendering questions:', questions.length, 'topic:', topicId);
    const esc = window.escapeHtml || function (value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    };
    const questionCards = questions.map((q, idx) => `
        <div style="background:var(--bg-input); border-radius:12px; padding:1.25rem; border:1px solid var(--border); margin-bottom:1rem; position:relative">
            <div style="position:absolute; top:1rem; right:1rem; display:flex; gap:0.5rem">
                <button onclick="editQuestionById('${topicId || q.topicId || window.currentBrowseTopicId || ''}', '${q.id || idx}', ${idx})" style="background:var(--primary); color:white; border:none; border-radius:6px; padding:4px 8px; cursor:pointer; font-size:0.75rem">
                    <span class="material-icons-round" style="font-size:1rem">edit</span>
                </button>
                <button onclick="deleteQuestion('${topicId || q.topicId || window.currentBrowseTopicId || ''}', '${q.id || idx}', ${idx})" style="background:#ef4444; color:white; border:none; border-radius:6px; padding:4px 8px; cursor:pointer; font-size:0.75rem">
                    <span class="material-icons-round" style="font-size:1rem">delete</span>
                </button>
            </div>
            <p style="margin-bottom:0.75rem; line-height:1.6; padding-right:5rem">${esc(q.q || q.question || '(Soru metni yok)')}</p>
            <div style="display:flex; gap:0.5rem; flex-wrap:wrap; font-size:0.85rem">
                ${(q.o || q.options || []).map((opt, i) => `
                    <span style="padding:0.35rem 0.75rem; border-radius:6px; ${i === (q.a !== undefined ? q.a : q.answer) ? 'background:#dcfce7; color:#166534; font-weight:600; border:1px solid #22c55e' : 'background:var(--bg-dark); color:var(--text-muted); border:1px solid var(--border)'}">
                        ${answerLabels[i]}) ${esc((opt || '').length > 40 ? String(opt).substring(0, 40) + '...' : opt)}
                    </span>
                `).join('')}
            </div>
            ${q.e ? `<p style="margin-top:0.75rem; font-size:0.85rem; color:var(--text-muted); font-style:italic; border-top:1px solid var(--border); padding-top:0.5rem">💡 ${q.e.substring(0, 200)}${q.e.length > 200 ? '...' : ''}</p>` : ''}
        </div>
    `);

    await window.renderHtmlInBatches(listEl, questionCards, 15);
};

window.editQuestionById = async function (topicId, questionId, index) {
    const resolvedTopicId = topicId || window.currentBrowseTopicId;
    const currentList = Array.isArray(window.currentBrowseData) ? window.currentBrowseData : [];

    const localQuestion = Number.isInteger(index) && currentList[index]
        ? currentList[index]
        : currentList.find(q => String(q.id) === String(questionId) || String(q.id) === String(parseInt(questionId)));

    if (localQuestion && window.openEditModal) {
        window.openEditModal({ ...localQuestion, id: localQuestion.id || questionId }, resolvedTopicId);
        return;
    }

    try {
        const res = await window.fetchWithTimeout(API + `/questions/${encodeURIComponent(resolvedTopicId)}`);
        if (!res.ok) {
            throw new Error(`HTTP error! status: ${res.status}`);
        }
        const questions = await res.json();
        const questionsArray = Array.isArray(questions) ? questions : (questions.questions || []);
        const question = questionsArray.find(q => String(q.id) === String(questionId) || String(q.id) === String(parseInt(questionId)))
            || (Number.isInteger(index) ? questionsArray[index] : null);

        if (question && window.openEditModal) {
            window.openEditModal(question, resolvedTopicId);
        } else {
            showToast('Soru bulunamadı', 'error');
        }
    } catch (e) {
        console.error(e);
        showToast('Soru yüklenemedi', 'error');
    }
};

window.deleteQuestion = async function (tid, qid, index) {
    const resolvedTopicId = tid || window.currentBrowseTopicId;
    if (!confirm('Bu soru kalıcı olarak silinecek. Emin misin?')) return;
    try {
        const localQuestion = Number.isInteger(index) && Array.isArray(window.currentBrowseData)
            ? window.currentBrowseData[index]
            : null;
        const resolvedQuestionId = localQuestion?.id || qid;

        const res = await fetch(API + `/questions/${encodeURIComponent(resolvedTopicId)}/${encodeURIComponent(resolvedQuestionId)}`, { method: 'DELETE' });
        const data = await res.json();
        if (data.success) {
            showToast('Soru silindi', 'success');
            window.loadBrowseQuestions(resolvedTopicId);
        } else {
            showToast('Silme hatası: ' + (data.error || 'Bilinmeyen hata'), 'error');
        }
    } catch (e) {
        console.error(e);
        showToast('Silme hatası (Bağlantı)', 'error');
    }
};


/* === modules\admin.js === */

/**
 * KPSS Dashboard - Admin Module
 * Contains User Management, Reports and Feedbacks
 */

if (typeof API === 'undefined') {
    window.API = window.API_URL || 'http://localhost:3456';
}

// ══════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT
// ══════════════════════════════════════════════════════════════════════════
window.loadUsers = async function () {
    const tbody = document.getElementById('userListBody');
    if (!tbody) return;

    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding:2rem; color:var(--text-muted)">Yükleniyor...</td></tr>';

    try {
        const response = await fetch(API + '/users');
        const data = await response.json();

        if (data.error) throw new Error(data.error);
        if (!data.users || data.users.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding:2rem; color:var(--text-muted)">Kullanıcı bulunamadı.</td></tr>';
            return;
        }

        tbody.innerHTML = data.users.map(user => {
            const isPremium = user.isPremium === true;
            const statusBadge = isPremium
                ? `<span style="background:rgba(234, 179, 8, 0.1); color:#eab308; padding:2px 8px; border-radius:12px; font-size:0.75rem; font-weight:bold">PREMIUM</span>`
                : `<span style="background:rgba(148, 163, 184, 0.1); color:#94a3b8; padding:2px 8px; border-radius:12px; font-size:0.75rem; font-weight:bold">FREE</span>`;

            const photo = `<div style="width:32px; height:32px; border-radius:50%; background:var(--accent); color:white; display:grid; place-items:center; font-weight:bold">${(user.displayName || '?').charAt(0).toUpperCase()}</div>`;

            const lastLogin = user.lastLogin
                ? new Date(user.lastLogin).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })
                : (user.createdAt ? new Date(user.createdAt).toLocaleDateString('tr-TR') : '-');

            return `
                <tr style="border-bottom:1px solid var(--border)">
                    <td style="padding:1rem">
                        <div style="display:flex; align-items:center; gap:0.75rem">
                            ${photo}
                            <div>
                                <div style="font-weight:500">${user.displayName}</div>
                                <div style="font-size:0.8rem; color:var(--text-muted)">Flutter</div>
                            </div>
                        </div>
                    </td>
                    <td style="padding:1rem; color:var(--text-muted)">${user.email}</td>
                    <td style="padding:1rem">${statusBadge}</td>
                    <td style="padding:1rem; font-size:0.9rem">${lastLogin}</td>
                    <td style="padding:1rem; font-family:monospace; font-size:0.75rem; color:var(--text-muted)">${user.uid.substring(0, 12)}...</td>
                    <td style="padding:1rem">
                        <div style="display:flex; gap:6px;">
                            <button onclick="showUserDetails('${user.uid}')" style="padding:6px 12px; font-size:0.75rem; background:var(--bg); color:var(--text); border:1px solid var(--border); border-radius:6px; cursor:pointer; font-weight:600;">
                                <span class="material-icons-round" style="font-size:14px; vertical-align:middle;">visibility</span>
                                DETAY
                            </button>
                            ${!isPremium ? `
                                <button onclick="togglePremium('${user.uid}', true)" style="padding:6px 12px; font-size:0.75rem; background:linear-gradient(135deg, #6366f1, #4f46e5); color:white; border:none; border-radius:6px; cursor:pointer; font-weight:600;">
                                    PREMIUM YAP
                                </button>
                            ` : `
                                <button onclick="togglePremium('${user.uid}', false)" style="padding:6px 12px; font-size:0.75rem; background:rgba(239, 68, 68, 0.1); color:#ef4444; border:1px solid rgba(239, 68, 68, 0.3); border-radius:6px; cursor:pointer; font-weight:600">
                                    İPTAL ET
                                </button>
                            `}
                        </div>
                    </td>
                </tr>
            `;
        }).join('');

    } catch (e) {
        console.error(e);
        tbody.innerHTML = `<tr><td colspan="6" style="text-align:center; padding:2rem; color:#ef4444">Hata: ${e.message}</td></tr>`;
    }
};

window.togglePremium = async function (uid, makePremium) {
    if (!confirm(makePremium ? 'Bu kullanıcıya Premium yetkisi verilsin mi?' : 'Premium yetkisi iptal edilsin mi?')) return;

    showToast('İşlem yapılıyor...', 'info');
    try {
        const res = await fetch(API + '/users/premium', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ uid, isPremium: makePremium })
        });
        const data = await res.json();

        if (data.success) {
            showToast('İşlem başarılı!', 'success');
            loadUsers();
        } else {
            showToast('Hata: ' + data.error, 'error');
        }
    } catch (e) {
        showToast('Bağlantı hatası', 'error');
    }
};

// ══════════════════════════════════════════════════════════════════════════
// USER DETAILS MODAL
// ══════════════════════════════════════════════════════════════════════════
window.showUserDetails = async function (uid) {
    let modal = document.getElementById('userDetailModal');
    if (!modal) {
        modal = document.createElement('div');
        modal.id = 'userDetailModal';
        modal.style.cssText = `
            position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(0,0,0,0.7); z-index: 10000; display: none;
            align-items: center; justify-content: center; padding: 20px;
        `;
        modal.innerHTML = `
            <div style="background: var(--card); border-radius: 16px; max-width: 900px; width: 100%; max-height: 90vh; overflow: hidden; display: flex; flex-direction: column; box-shadow: 0 25px 50px rgba(0,0,0,0.5);">
                <div style="padding: 24px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center;">
                    <h2 style="margin: 0; font-size: 1.25rem; display: flex; align-items: center; gap: 10px;">
                        <span class="material-icons-round" style="color: var(--primary);">person</span>
                        Kullanıcı Detayları
                    </h2>
                    <button onclick="closeUserDetailModal()" style="background: none; border: none; color: var(--text-muted); cursor: pointer; padding: 8px; border-radius: 8px;">
                        <span class="material-icons-round">close</span>
                    </button>
                </div>
                <div id="userDetailContent" style="padding: 24px; overflow-y: auto; flex: 1;">
                    <div style="text-align: center; color: var(--text-muted); padding: 40px;">
                        <span class="material-icons-round" style="font-size: 48px; opacity: 0.3; animation: spin 1s linear infinite;">sync</span>
                        <p>Yükleniyor...</p>
                    </div>
                </div>
            </div>
        `;
        document.body.appendChild(modal);
        modal.addEventListener('click', (e) => {
            if (e.target === modal) closeUserDetailModal();
        });
    }
    modal.style.display = 'flex';
    document.body.style.overflow = 'hidden';
    await loadUserDetails(uid);
};

window.closeUserDetailModal = function () {
    const modal = document.getElementById('userDetailModal');
    if (modal) {
        modal.style.display = 'none';
        document.body.style.overflow = '';
    }
};

window.loadUserDetails = async function (uid) {
    const content = document.getElementById('userDetailContent');
    content.dataset.uid = uid;
    try {
        const res = await fetch(API + '/users/' + uid + '/details');
        const data = await res.json();
        if (!data.success) {
            content.innerHTML = `<div style="color: #ef4444; text-align: center; padding: 40px;">Hata: ${data.error}</div>`;
            return;
        }
        const u = data.user;
        const formatDate = (d) => d ? new Date(d).toLocaleString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '-';
        const formatDateInput = (d) => {
            if (!d) return '';
            const date = new Date(d);
            return date.toISOString().split('T')[0];
        };
        const isPremium = u.isPremium;

        // Calculate days left properly
        let daysLeft = 0;
        if (u.premiumEndDate && isPremium) {
            const end = new Date(u.premiumEndDate);
            const now = new Date();
            const diffTime = end - now;
            daysLeft = Math.max(0, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
        }

        const statusColor = daysLeft > 7 ? '#10b981' : daysLeft > 0 ? '#f59e0b' : '#ef4444';
        const statusBg = daysLeft > 7 ? 'rgba(16, 185, 129, 0.1)' : daysLeft > 0 ? 'rgba(245, 158, 11, 0.1)' : 'rgba(239, 68, 68, 0.1)';
        const statusBorder = daysLeft > 7 ? 'rgba(16, 185, 129, 0.3)' : daysLeft > 0 ? 'rgba(245, 158, 11, 0.3)' : 'rgba(239, 68, 68, 0.3)';

        content.innerHTML = `
        <!-- Profil Kartı -->
        <div style="display: flex; align-items: center; gap: 16px; margin-bottom: 20px; padding: 16px; background: var(--bg); border-radius: 12px; border: 1px solid var(--border);">
            <div style="width: 56px; height: 56px; border-radius: 50%; background: linear-gradient(135deg, var(--primary), var(--accent)); display: grid; place-items: center; font-size: 22px; font-weight: bold; color: white;">${(u.displayName || '?').charAt(0).toUpperCase()}</div>
            <div style="flex: 1; min-width: 0;">
                <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                    <h3 style="margin: 0; font-size: 1.1rem; font-weight: 600;">${u.displayName || 'İsimsiz Kullanıcı'}</h3>
                    <span style="background: ${isPremium ? 'rgba(234, 179, 8, 0.2)' : 'rgba(148, 163, 184, 0.2)'}; color: ${isPremium ? '#eab308' : '#94a3b8'}; padding: 3px 10px; border-radius: 20px; font-size: 0.7rem; font-weight: 600; border: 1px solid ${isPremium ? 'rgba(234, 179, 8, 0.3)' : 'rgba(148, 163, 184, 0.3)'};">${isPremium ? '⭐ PREMIUM' : 'FREE'}</span>
                </div>
                <div style="color: var(--text-muted); font-size: 0.8rem; margin-top: 4px; overflow: hidden; text-overflow: ellipsis;">${u.email || 'Email yok'}</div>
                <div style="display: flex; gap: 12px; margin-top: 6px; font-size: 0.75rem; color: var(--text-muted);">
                    <span><span class="material-icons-round" style="font-size: 12px; vertical-align: middle; margin-right: 2px;">phone_android</span>${u.platform || 'Bilinmiyor'}</span>
                    <span>Kayıt: ${formatDate(u.createdAt).split(' ')[0]}</span>
                </div>
            </div>
        </div>

        <!-- Premium Yönetim Paneli -->
        <div style="background: linear-gradient(135deg, rgba(234, 179, 8, 0.05), rgba(234, 179, 8, 0.02)); border: 1px solid rgba(234, 179, 8, 0.25); border-radius: 14px; padding: 18px; margin-bottom: 16px;">
            <h4 style="margin: 0 0 14px 0; display: flex; align-items: center; gap: 8px; color: #eab308; font-size: 0.95rem;">
                <span class="material-icons-round" style="font-size: 20px;">workspace_premium</span>
                Premium Yönetimi
            </h4>
            
            <!-- Hızlı Plan Butonları -->
            <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin-bottom: 16px;">
                <button onclick="setPremiumPlan('${uid}', 1)" style="padding: 12px 8px; background: var(--bg-card); border: 2px solid var(--border); border-radius: 10px; cursor: pointer; text-align: center; transition: all 0.2s;">
                    <div style="font-size: 1.4rem; font-weight: 700; color: #eab308;">1</div>
                    <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 2px;">Aylık</div>
                </button>
                <button onclick="setPremiumPlan('${uid}', 3)" style="padding: 12px 8px; background: var(--bg-card); border: 2px solid var(--border); border-radius: 10px; cursor: pointer; text-align: center; position: relative;">
                    <div style="position: absolute; top: -6px; right: 6px; background: #10b981; color: white; font-size: 0.6rem; padding: 2px 6px; border-radius: 10px; font-weight: 600;">%10</div>
                    <div style="font-size: 1.4rem; font-weight: 700; color: #eab308;">3</div>
                    <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 2px;">3 Aylık</div>
                </button>
                <button onclick="setPremiumPlan('${uid}', 12)" style="padding: 12px 8px; background: var(--bg-card); border: 2px solid var(--border); border-radius: 10px; cursor: pointer; text-align: center; position: relative;">
                    <div style="position: absolute; top: -6px; right: 6px; background: #10b981; color: white; font-size: 0.6rem; padding: 2px 6px; border-radius: 10px; font-weight: 600;">%25</div>
                    <div style="font-size: 1.4rem; font-weight: 700; color: #eab308;">12</div>
                    <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 2px;">Yıllık</div>
                </button>
            </div>

            <!-- Manuel Tarih Ayarlama -->
            <div style="background: var(--bg-card); border-radius: 10px; padding: 14px; margin-bottom: 14px; border: 1px solid var(--border);">
                <div style="font-size: 0.8rem; color: var(--text-muted); margin-bottom: 10px; font-weight: 500;">Manuel Tarih Ayarlama</div>
                <div style="display: grid; grid-template-columns: 1fr 1fr auto; gap: 10px; align-items: end;">
                    <div>
                        <label style="display: block; font-size: 0.7rem; color: var(--text-muted); margin-bottom: 4px;">Başlangıç</label>
                        <input type="date" id="premStart_${uid}" value="${formatDateInput(u.premiumStartDate) || new Date().toISOString().split('T')[0]}" style="width: 100%; padding: 8px 10px; background: var(--bg); border: 1px solid var(--border); border-radius: 6px; color: var(--text); font-size: 0.85rem; box-sizing: border-box;">
                    </div>
                    <div>
                        <label style="display: block; font-size: 0.7rem; color: var(--text-muted); margin-bottom: 4px;">Bitiş</label>
                        <input type="date" id="premEnd_${uid}" value="${formatDateInput(u.premiumEndDate)}" style="width: 100%; padding: 8px 10px; background: var(--bg); border: 1px solid var(--border); border-radius: 6px; color: var(--text); font-size: 0.85rem; box-sizing: border-box;">
                    </div>
                    <button onclick="savePremiumDates('${uid}')" style="padding: 8px 14px; background: linear-gradient(135deg, #eab308, #ca8a04); color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 0.85rem; white-space: nowrap;">
                        Kaydet
                    </button>
                </div>
            </div>

            <!-- Mevcut Durum & Toggle -->
            <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px 14px; background: ${statusBg}; border-radius: 10px; border: 1px solid ${statusBorder}; margin-bottom: 16px;">
                <div>
                    <div style="font-size: 0.75rem; color: var(--text-muted); margin-bottom: 2px;">Mevcut Durum</div>
                    <div style="font-weight: 600; color: ${isPremium ? statusColor : '#ef4444'}; font-size: 0.95rem;">
                        ${isPremium ? (daysLeft > 0 ? `${daysLeft} gün kaldı` : 'Süre doldu') : 'Premium Pasif'}
                    </div>
                </div>
                <button onclick="togglePremiumModal('${uid}', ${!isPremium})" style="padding: 8px 14px; background: ${isPremium ? '#ef4444' : '#10b981'}; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 0.85rem;">
                    ${isPremium ? 'İptal Et' : 'Aktif Et'}
                </button>
            </div>
        </div>

        <!-- Admin Notları -->
        <div style="background: var(--bg-card); border-radius: 12px; padding: 16px; margin-bottom: 16px; border: 1px solid var(--border);">
            <h4 style="margin: 0 0 12px 0; display: flex; align-items: center; gap: 8px; font-size: 0.95rem;">
                <span class="material-icons-round" style="color: var(--primary);">sticky_note_2</span>
                Admin Notları
            </h4>
            <textarea id="adminNote_${uid}" placeholder="Kullanıcı hakkında not ekle..." style="width: 100%; padding: 10px; background: var(--bg); border: 1px solid var(--border); border-radius: 8px; color: var(--text); font-size: 0.9rem; min-height: 80px; resize: vertical; box-sizing: border-box;">${u.adminNote || ''}</textarea>
            <div style="display: flex; justify-content: flex-end; margin-top: 8px;">
                <button onclick="saveAdminNote('${uid}')" style="padding: 6px 14px; background: var(--primary); color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 0.85rem;">
                    Notu Kaydet
                </button>
            </div>
        </div>

        <!-- Premium Geçmişi -->
        ${u.premiumHistory?.length > 0 ? `
        <div style="background: var(--bg-card); border-radius: 12px; padding: 16px; border: 1px solid var(--border);">
            <h4 style="margin: 0 0 12px 0; display: flex; align-items: center; gap: 8px; font-size: 0.95rem;">
                <span class="material-icons-round" style="color: #eab308;">history</span>
                Premium Geçmişi
            </h4>
            <div style="max-height: 200px; overflow-y: auto;">
                ${u.premiumHistory.map(h => `
                    <div style="display: flex; align-items: center; gap: 12px; padding: 10px 0; border-bottom: 1px solid var(--border);">
                        <span class="material-icons-round" style="color: ${h.isPremium ? '#eab308' : '#94a3b8'}; font-size: 18px;">
                            ${h.isPremium ? 'workspace_premium' : 'remove_circle'}
                        </span>
                        <div style="flex: 1;">
                            <div style="font-weight: 500; font-size: 0.9rem;">${h.action || (h.isPremium ? 'Premium Yapıldı' : 'Premium İptal')}</div>
                            <div style="color: var(--text-muted); font-size: 0.75rem;">${formatDate(h.changedAt)} • ${h.adminName || 'Sistem'}</div>
                        </div>
                        <span style="background: ${h.isPremium ? 'rgba(234, 179, 8, 0.15)' : 'rgba(148, 163, 184, 0.15)'}; color: ${h.isPremium ? '#eab308' : '#94a3b8'}; padding: 2px 8px; border-radius: 12px; font-size: 0.7rem; font-weight: 600;">
                            ${h.isPremium ? 'AKTİF' : 'PASİF'}
                        </span>
                    </div>
                `).join('')}
            </div>
        </div>
        ` : '<p style="color: var(--text-muted); text-align: center; padding: 20px; font-size: 0.9rem;">Premium geçmişi bulunmuyor.</p>'}
        `;
    } catch (e) {
        content.innerHTML = `<div style="color: #ef4444; text-align: center; padding: 40px;">Hata: ${e.message}</div>`;
    }
};

// Premium plan seçimi
window.setPremiumPlan = async function (uid, months) {
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + months);

    document.getElementById('premStart_' + uid).value = new Date().toISOString().split('T')[0];
    document.getElementById('premEnd_' + uid).value = endDate.toISOString().split('T')[0];

    await savePremiumDates(uid, true);
};

// Premium tarihlerini kaydet
window.savePremiumDates = async function (uid, isSilent = false) {
    const startDate = document.getElementById('premStart_' + uid)?.value;
    const endDate = document.getElementById('premEnd_' + uid)?.value;

    if (!startDate || !endDate) {
        if (!isSilent) showToast('Başlangıç ve bitiş tarihleri gereklidir', 'error');
        return;
    }

    try {
        const res = await fetch(API + '/users/premium', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                uid,
                isPremium: true,
                premiumStartDate: startDate,
                premiumEndDate: endDate
            })
        });
        const data = await res.json();

        if (data.success) {
            if (!isSilent) showToast('Premium tarihleri güncellendi', 'success');
            await loadUserDetails(uid);
            loadUsers();
        } else {
            if (!isSilent) showToast('Hata: ' + data.error, 'error');
        }
    } catch (e) {
        if (!isSilent) showToast('Bağlantı hatası', 'error');
    }
};

// Modal içindeki premium toggle
window.togglePremiumModal = async function (uid, makePremium) {
    const action = makePremium ? 'Premium aktif edilsin mi?' : 'Premium iptal edilsin mi?';
    if (!confirm(action)) return;

    try {
        const res = await fetch(API + '/users/premium', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ uid, isPremium: makePremium })
        });
        const data = await res.json();

        if (data.success) {
            showToast(makePremium ? 'Premium aktif edildi' : 'Premium iptal edildi', 'success');
            await loadUserDetails(uid);
            loadUsers();
        } else {
            showToast('Hata: ' + data.error, 'error');
        }
    } catch (e) {
        showToast('Bağlantı hatası', 'error');
    }
};

// Admin notunu kaydet
window.saveAdminNote = async function (uid) {
    const note = document.getElementById('adminNote_' + uid)?.value;

    try {
        const res = await fetch(API + '/users/' + uid + '/note', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ note })
        });
        const data = await res.json();

        if (data.success) {
            showToast('Not kaydedildi', 'success');
        } else {
            showToast('Hata: ' + data.error, 'error');
        }
    } catch (e) {
        showToast('Bağlantı hatası', 'error');
    }
};

// ══════════════════════════════════════════════════════════════════════════
// REPORTS LOGIC
// ══════════════════════════════════════════════════════════════════════════
window.loadReports = async function () {
    const el = document.getElementById('reportsList');
    if (!el) return;
    el.innerHTML = '<div style="padding:1rem; color:var(--text-muted)">Yükleniyor...</div>';

    const TYPE_MAP = {
        'wrong_answer': { label: 'Yanlış Cevap', color: '#ef4444', icon: 'close', bg: 'rgba(239,68,68,0.1)' },
        'typo': { label: 'Yazım Hatası', color: '#3b82f6', icon: 'spellcheck', bg: 'rgba(59,130,246,0.1)' },
        'wrong_topic': { label: 'Yanlış Konu', color: '#f59e0b', icon: 'category', bg: 'rgba(245,158,11,0.1)' },
        'unclear': { label: 'Anlaşılmıyor', color: '#8b5cf6', icon: 'help_outline', bg: 'rgba(139,92,246,0.1)' },
        'duplicate': { label: 'Tekrar Eden Soru', color: '#ec4899', icon: 'content_copy', bg: 'rgba(236,72,153,0.1)' },
        'other': { label: 'Diğer', color: '#64748b', icon: 'more_horiz', bg: 'rgba(100,116,139,0.1)' }
    };

    try {
        const res = await fetch(API + '/reports');
        if (!res.ok) {
            if (res.status === 404) {
                el.innerHTML = '<div style="padding:1rem">Sunucu güncellenmeli.</div>';
                return;
            }
        }

        const reports = await res.json();

        if (!reports || reports.length === 0) {
            el.innerHTML = '<div style="padding:2rem; text-align:center; color:var(--text-muted)">Henüz hiç rapor yok.</div>';
            return;
        }

        el.innerHTML = reports.map(r => {
            const typeInfo = TYPE_MAP[r.reportType] || TYPE_MAP['other'];
            const dateStr = new Date(r.receivedAt).toLocaleString('tr-TR');

            return `
            <div style="background:var(--card); border:1px solid var(--border); border-radius:12px; padding:1.25rem; display:flex; gap:1rem; align-items:flex-start; margin-bottom:0.75rem">
                <div style="width:48px; height:48px; background:${typeInfo.bg}; color:${typeInfo.color}; border-radius:12px; display:grid; place-items:center; flex-shrink:0">
                    <span class="material-icons-round" style="font-size:1.5rem">${typeInfo.icon}</span>
                </div>
                <div style="flex:1">
                    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.5rem">
                        <div style="font-weight:700; font-size:1.05rem; color:var(--text); display:flex; align-items:center; gap:0.5rem">
                            ${typeInfo.label}
                            <span style="font-size:0.75rem; font-weight:normal; background:var(--bg); border:1px solid var(--border); padding:2px 8px; border-radius:12px; color:var(--text-muted)">
                                ${r.reportType}
                            </span>
                        </div>
                        <div style="font-size:0.85rem; color:var(--text-muted); display:flex; align-items:center; gap:0.25rem">
                            <span class="material-icons-round" style="font-size:14px">schedule</span>
                            ${dateStr}
                        </div>
                    </div>
                    
                    <div style="display:grid; grid-template-columns: auto 1fr; gap:0.5rem 1rem; margin-bottom:0.75rem; font-size:0.9rem">
                        <div style="color:var(--text-muted)">Soru ID:</div>
                        <div style="font-family:monospace; color:var(--accent); cursor:pointer; font-weight:600" onclick="navigator.clipboard.writeText('${r.questionId}'); showToast('ID kopyalandı', 'success')">
                            ${r.questionId} <span class="material-icons-round" style="font-size:12px; vertical-align:middle; opacity:0.5">content_copy</span>
                        </div>
                        
                         <div style="color:var(--text-muted)">Kullanıcı:</div>
                        <div style="color:var(--text-muted)">
                            ${r.userId === 'anonymous' ? 'Anonim Kullanıcı' : r.userId.substring(0, 8) + '...'}
                        </div>
                    </div>

                    ${r.description ? `
                    <div style="background:var(--bg); border-left:3px solid ${typeInfo.color}; padding:0.75rem 1rem; border-radius:0 8px 8px 0; font-size:0.95rem; color:var(--text-muted); font-style:italic">
                        "${r.description}"
                    </div>
                    ` : ''}
                    
                    <div style="margin-top:1rem; display:flex; gap:0.5rem">
                        <button class="btn-primary" style="padding:0.5rem 1rem; font-size:0.85rem; background:transparent; border:1px solid var(--border); color:var(--text)" onclick="viewReportQuestion('${r.questionId}')">
                            <span class="material-icons-round" style="font-size:1.1rem; vertical-align:bottom; margin-right:4px">edit</span>
                            Soruyu Düzenle
                        </button>
                    </div>
                </div>
            </div>
            `;
        }).join('');

    } catch (e) {
        el.innerHTML = `<div style="padding:1rem; color:#ef4444">Hata: ${e.message}</div>`;
    }
};

window.viewReportQuestion = async function (questionId) {
    showToast('Soru aranıyor...', 'info');
    try {
        const res = await fetch(API + '/find-question?id=' + questionId);
        const data = await res.json();

        if (data.success) {
            editQuestion(data.question, data.topicId);
        } else {
            showToast('Soru veritabanında bulunamadı', 'error');
        }
    } catch (e) {
        showToast('Hata: ' + e.message, 'error');
    }
};


// FEEDBACKS LOGIC
window.loadFeedbacks = async function () {
    const el = document.getElementById('feedbacksList');
    if (!el) return;
    el.innerHTML = '<div style="padding:1rem; color:var(--text-muted)">Yükleniyor...</div>';

    try {
        const res = await fetch(API + '/feedbacks');
        const feedbacks = await res.json();

        if (!feedbacks || feedbacks.length === 0) {
            el.innerHTML = '<div style="padding:2rem; text-align:center; color:var(--text-muted)">Henüz hiç geri bildirim yok.</div>';
            return;
        }

        el.innerHTML = feedbacks.map(f => {
            const dateStr = new Date(f.receivedAt).toLocaleString('tr-TR');
            return `
            <div style="background:var(--card); border:1px solid var(--border); padding:1rem; margin-bottom:0.5rem; border-radius:8px">
                <div style="font-weight:bold; color:var(--accent)">${f.typeName || f.type}</div>
                <div style="margin:0.5rem 0">"${f.message}"</div>
                <div style="font-size:0.8rem; color:var(--text-muted)">${dateStr} - ${f.platform}</div>
            </div>
            `;
        }).join('');
    } catch (e) {
        el.innerHTML = `Hata: ${e.message}`;
    }
};


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


/* === modules\ai.js === */

/**
 * KPSS Dashboard - AI Module
 * Contains logic for AI-based question analysis and generation.
 */

// Ensure API URL is available
if (typeof API === 'undefined') {
    window.API = window.API_URL || 'http://localhost:3456';
}

// 1. Analyze Bulk JSON Input with AI
window.analyzeWithAI = async function () {
    const input = document.getElementById('bulkJsonInput')?.value?.trim();

    if (!input) {
        showToast('Analiz için önce soru ekleyin', 'warning');
        return;
    }

    let questions;
    try {
        questions = JSON.parse(input);
        if (!Array.isArray(questions)) questions = [questions];
    } catch (e) {
        showToast('Geçerli JSON giriniz: ' + e.message, 'error');
        return;
    }

    if (questions.length === 0) {
        showToast('Analiz edilecek soru bulunamadı', 'warning');
        return;
    }

    // Show loading state
    const panel = document.getElementById('aiAnalysisPanel');
    const content = document.getElementById('aiAnalysisContent');
    if (panel) panel.style.display = 'block';

    if (content) {
        content.innerHTML = `
            <div style="text-align:center; padding:3rem">
                <div style="width:50px; height:50px; border:4px solid var(--border); border-top-color:var(--accent); border-radius:50%; animation:spin 1s linear infinite; margin:0 auto"></div>
                <p style="margin-top:1rem; color:var(--text-muted)">AI analiz ediyor... (${questions.length} soru)</p>
                <style>@keyframes spin { to { transform: rotate(360deg) } }</style>
            </div>
        `;
    }

    try {
        const res = await fetch(API + '/analyze-ai', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ questions })
        });

        const data = await res.json();

        if (!data.success) {
            if (content) {
                content.innerHTML = `
                    <div style="background:rgba(239,68,68,0.1); border:1px solid #ef4444; padding:1.5rem; border-radius:8px; color:#ef4444">
                        <strong>Hata:</strong> ${data.error || 'Bilinmeyen hata'}
                    </div>
                `;
            }
            return;
        }

        // Render analysis results
        const analysis = data.analysis;
        if (content) {
            content.innerHTML = analysis.map((item, i) => {
                const statusColors = {
                    'ok': { bg: 'rgba(34,197,94,0.1)', border: '#22c55e', icon: 'check_circle', label: 'Geçerli' },
                    'warning': { bg: 'rgba(234,179,8,0.1)', border: '#eab308', icon: 'warning', label: 'Uyarı' },
                    'error': { bg: 'rgba(239,68,68,0.1)', border: '#ef4444', icon: 'error', label: 'Hata' }
                };
                const status = statusColors[item.status] || statusColors['warning'];
                const q = questions[item.index] || questions[i];

                return `
                    <div style="background:${status.bg}; border:1px solid ${status.border}; border-radius:12px; padding:1.25rem; margin-bottom:1rem">
                        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1rem">
                            <div style="display:flex; align-items:center; gap:0.75rem">
                                <span class="material-icons-round" style="color:${status.border}; font-size:1.5rem">${status.icon}</span>
                                <div>
                                    <strong style="color:${status.border}">${status.label}</strong>
                                    <span style="color:var(--text-muted); margin-left:0.5rem">Soru ${(item.index || i) + 1}</span>
                                </div>
                            </div>
                            <div style="background:${status.border}; color:white; padding:0.25rem 0.75rem; border-radius:20px; font-weight:bold">
                                ${item.score || '?'}/10
                            </div>
                        </div>
                        
                        <div style="background:var(--card); padding:0.75rem; border-radius:6px; margin-bottom:1rem; font-size:0.9rem; color:var(--text)">
                            <strong>Soru:</strong> ${q?.q?.substring(0, 100) || 'N/A'}${(q?.q?.length || 0) > 100 ? '...' : ''}
                        </div>
                        
                        ${item.correctAnswerCheck ? `
                            <div style="margin-bottom:0.75rem">
                                <strong style="color:var(--text)">🎯 Doğru Cevap Kontrolü:</strong>
                                <p style="margin:0.25rem 0 0 0; color:var(--text-muted); font-size:0.9rem">${item.correctAnswerCheck}</p>
                            </div>
                        ` : ''}
                        
                        ${item.issues && item.issues.length > 0 ? `
                            <div style="margin-bottom:0.75rem">
                                <strong style="color:#ef4444">⚠️ Sorunlar:</strong>
                                <ul style="margin:0.25rem 0 0 1rem; padding:0; color:var(--text-muted); font-size:0.9rem">
                                    ${item.issues.map(issue => `<li>${issue}</li>`).join('')}
                                </ul>
                            </div>
                        ` : ''}
                        
                        ${item.suggestions && item.suggestions.length > 0 ? `
                            <div style="margin-bottom:0.75rem">
                                <strong style="color:#22c55e">💡 Öneriler:</strong>
                                <ul style="margin:0.25rem 0 0 1rem; padding:0; color:var(--text-muted); font-size:0.9rem">
                                    ${item.suggestions.map(s => `<li>${s}</li>`).join('')}
                                </ul>
                            </div>
                        ` : ''}
                        
                        ${item.summary ? `
                            <p style="margin:0; padding-top:0.75rem; border-top:1px solid var(--border); color:var(--text-muted); font-size:0.85rem; font-style:italic">
                                📝 ${item.summary}
                            </p>
                        ` : ''}
                    </div>
                `;
            }).join('');
        }

        showToast(`✅ ${analysis.length} soru analiz edildi`, 'success');

    } catch (e) {
        console.error('AI Analysis error:', e);
        if (content) {
            content.innerHTML = `
                <div style="background:rgba(239,68,68,0.1); border:1px solid #ef4444; padding:1.5rem; border-radius:8px; color:#ef4444">
                    <strong>Bağlantı Hatası:</strong> ${e.message}
                </div>
            `;
        }
    }
};

// 2. LocalStorage Helpers for AI Analysis
window.getAnalyzedQuestions = function () {
    try {
        return JSON.parse(localStorage.getItem('analyzedQuestions') || '{}');
    } catch {
        return {};
    }
};

window.markQuestionAsAnalyzed = function (questionId, analysisResult) {
    const analyzed = getAnalyzedQuestions();
    analyzed[questionId] = {
        date: new Date().toISOString(),
        status: analysisResult.status,
        score: analysisResult.score,
        summary: analysisResult.summary || '',
        issues: analysisResult.issues || [],
        suggestions: analysisResult.suggestions || [],
        correctAnswerCheck: analysisResult.correctAnswerCheck || ''
    };
    localStorage.setItem('analyzedQuestions', JSON.stringify(analyzed));
};

window.isQuestionAnalyzed = function (questionId) {
    const analyzed = getAnalyzedQuestions();
    return !!analyzed[questionId];
};

window.getQuestionAnalysis = function (questionId) {
    const analyzed = getAnalyzedQuestions();
    return analyzed[questionId] || null;
};

// 3. Analyze Questions in Browse Page with AI
window.analyzeBrowseWithAI = async function () {
    const topicId = document.getElementById('browseTopicSelect')?.value;
    const limitSelect = document.getElementById('analysisLimitSelect');
    const limit = limitSelect ? limitSelect.value : '10';

    if (!topicId) {
        showToast('Önce bir konu seçin', 'warning');
        return;
    }

    const panel = document.getElementById('browseAiAnalysisPanel');
    const content = document.getElementById('browseAiAnalysisContent');
    if (panel) panel.style.display = 'block';

    if (content) {
        content.innerHTML = `
            <div style="text-align:center; padding:3rem">
                <div style="width:50px; height:50px; border:4px solid var(--border); border-top-color:var(--accent); border-radius:50%; animation:spin 1s linear infinite; margin:0 auto"></div>
                <p style="margin-top:1rem; color:var(--text-muted)">Sorular yükleniyor...</p>
            </div>
        `;
    }

    try {
        const questionsRes = await fetch(API + `/questions/${topicId}`);
        const _allQData = await questionsRes.json();
        const allQuestions = _allQData.questions || (Array.isArray(_allQData) ? _allQData : []);

        if (!allQuestions || allQuestions.length === 0) {
            if (content) content.innerHTML = `<div style="text-align:center; padding:2rem; color:var(--text-muted)">Bu konuda henüz soru bulunmuyor.</div>`;
            return;
        }

        // Filter out already analyzed questions
        const notAnalyzed = (Array.isArray(allQuestions) ? allQuestions : []).filter(q => !window.isQuestionAnalyzed(q.id));

        if (notAnalyzed.length === 0) {
            if (content) {
                content.innerHTML = `
                    <div style="text-align:center; padding:2rem; color:#22c55e">
                        <span class="material-icons-round" style="font-size:3rem; display:block; margin-bottom:1rem">check_circle</span>
                        Bu konudaki tüm sorular zaten analiz edilmiş!
                    </div>`;
            }
            return;
        }

        // Apply limit
        const questionsToAnalyze = limit === 'all' ? notAnalyzed : notAnalyzed.slice(0, parseInt(limit));
        const skipped = allQuestions.length - notAnalyzed.length;

        if (content) {
            content.innerHTML = `
                <div style="text-align:center; padding:3rem">
                    <div style="width:50px; height:50px; border:4px solid var(--border); border-top-color:var(--accent); border-radius:50%; animation:spin 1s linear infinite; margin:0 auto"></div>
                    <p style="margin-top:1rem; color:var(--text-muted)">AI analiz ediyor... (${questionsToAnalyze.length} soru)</p>
                    ${skipped > 0 ? `<p style="font-size:0.8rem; color:#22c55e">✓ ${skipped} soru zaten analiz edilmiş</p>` : ''}
                </div>`;
        }

        const res = await fetch(API + '/ai/analyze', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ questions: questionsToAnalyze })
        });

        const data = await res.json();

        if (!data.success) {
            if (content) content.innerHTML = `<div style="background:rgba(239,68,68,0.1); border:1px solid #ef4444; padding:1.5rem; border-radius:8px; color:#ef4444"><strong>Hata:</strong> ${data.error}</div>`;
            return;
        }

        // Save results to localStorage
        const analysis = data.analysis;
        analysis.forEach((item, i) => {
            const q = questionsToAnalyze[item.index] || questionsToAnalyze[i];
            if (q && q.id) window.markQuestionAsAnalyzed(q.id, item);
        });

        // Render results
        if (content) {
            content.innerHTML = `<div style="margin-bottom:1rem; padding:0.75rem; background:rgba(34,197,94,0.1); border-radius:8px; color:#22c55e; font-size:0.9rem">✓ ${analysis.length} soru analiz edildi ve kaydedildi</div>` +
                analysis.map((item, i) => {
                    const colors = { 'ok': { bg: 'rgba(34,197,94,0.1)', border: '#22c55e', icon: 'check_circle', label: 'Geçerli' }, 'warning': { bg: 'rgba(234,179,8,0.1)', border: '#eab308', icon: 'warning', label: 'Uyarı' }, 'error': { bg: 'rgba(239,68,68,0.1)', border: '#ef4444', icon: 'error', label: 'Hata' } };
                    const s = colors[item.status] || colors['warning'];
                    const q = questionsToAnalyze[item.index] || questionsToAnalyze[i];
                    return `<div style="background:${s.bg}; border:1px solid ${s.border}; border-radius:12px; padding:1.25rem; margin-bottom:1rem">
                    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1rem">
                        <div style="display:flex; align-items:center; gap:0.75rem"><span class="material-icons-round" style="color:${s.border}; font-size:1.5rem">${s.icon}</span><div><strong style="color:${s.border}">${s.label}</strong><span style="color:var(--text-muted); margin-left:0.5rem">Soru ${(item.index || i) + 1}</span></div></div>
                        <div style="background:${s.border}; color:white; padding:0.25rem 0.75rem; border-radius:20px; font-weight:bold">${item.score || '?'}/10</div>
                    </div>
                    <div style="background:var(--card); padding:0.75rem; border-radius:6px; margin-bottom:1rem; font-size:0.9rem; color:var(--text)"><strong>Soru:</strong> ${q?.q?.substring(0, 100) || 'N/A'}${(q?.q?.length || 0) > 100 ? '...' : ''}</div>
                    ${item.correctAnswerCheck ? `<div style="margin-bottom:0.75rem"><strong style="color:var(--text)">🎯 Doğru Cevap:</strong><p style="margin:0.25rem 0 0 0; color:var(--text-muted); font-size:0.9rem">${item.correctAnswerCheck}</p></div>` : ''}
                    ${item.issues?.length ? `<div style="margin-bottom:0.75rem"><strong style="color:#ef4444">⚠️ Sorunlar:</strong><ul style="margin:0.25rem 0 0 1rem; padding:0; color:var(--text-muted); font-size:0.9rem">${item.issues.map(x => `<li>${x}</li>`).join('')}</ul></div>` : ''}
                    ${item.suggestions?.length ? `<div style="margin-bottom:0.75rem"><strong style="color:#22c55e">💡 Öneriler:</strong><ul style="margin:0.25rem 0 0 1rem; padding:0; color:var(--text-muted); font-size:0.9rem">${item.suggestions.map(x => `<li>${x}</li>`).join('')}</ul></div>` : ''}
                    ${item.summary ? `<p style="margin:0; padding-top:0.75rem; border-top:1px solid var(--border); color:var(--text-muted); font-size:0.85rem; font-style:italic">📝 ${item.summary}</p>` : ''}
                </div>`;
                }).join('');
        }

        showToast(`✅ ${analysis.length} soru analiz edildi`, 'success');
        if (window.loadBrowseQuestions) window.loadBrowseQuestions(); // Refresh to show badges if function exists

    } catch (e) {
        console.error('Browse AI Analysis error:', e);
        if (content) content.innerHTML = `<div style="background:rgba(239,68,68,0.1); border:1px solid #ef4444; padding:1.5rem; border-radius:8px; color:#ef4444"><strong>Hata:</strong> ${e.message}</div>`;
    }
};

// 4. Generate Question with AI (Soru Üretim - farklı fonksiyon adı)
window.generateQuestionWithAI = async function () {
    const topicSel = document.getElementById('addTopicSelect');
    const topicText = topicSel.options[topicSel.selectedIndex]?.text;

    if (!topicSel.value) {
        showToast('Önce konu seçin', 'error');
        return;
    }

    showToast('AI soru türetiyor...', 'info');

    try {
        const res = await fetch(API + '/generate-ai', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ topic: topicText })
        });
        const data = await res.json();

        if (data.success && data.question) {
            // Fill form with generated question
            // Note: This relies on elements in the Add Question form
            if (document.getElementById('addQuestionText')) document.getElementById('addQuestionText').innerText = data.question.q || '';
            ['opt0', 'opt1', 'opt2', 'opt3', 'opt4'].forEach((id, i) => {
                if (document.getElementById(id)) document.getElementById(id).value = data.question.o?.[i] || '';
            });
            if (document.getElementById('addCorrectAns')) document.getElementById('addCorrectAns').value = data.question.a || 0;
            if (document.getElementById('addExplanation')) document.getElementById('addExplanation').value = data.question.e || '';

            if (window.updatePreview) window.updatePreview();

            showToast('Soru türetildi! Düzenleme yapabilirsin.', 'success');
        } else {
            showToast('AI hatası: ' + (data.error || 'Bilinmeyen'), 'error');
        }
    } catch (e) {
        showToast('Bağlantı hatası: ' + e.message, 'error');
    }
};


/* === modules\notifications.js === */

/**
 * KPSS Dashboard - Notifications Module
 * Manages notification templates and sending push notifications
 */

// Global Templates Array
let myTemplates = [];

const DEFAULT_TEMPLATES = [
    {
        title: "☀️ Günaydın, Bugün Senin Günün!",
        body: "Yeni bir gün, yeni hedefler! Kahveni al ve bugün için planladığın ilk testi çözmeye başla. Başarı düzenli çalışanın yanındadır.",
        channel: "daily_reminder",
        icon: "wb_sunny"
    },
    {
        title: "📚 Yeni Soru Paketleri Eklendi",
        body: "Soru bankamız genişlemeye devam ediyor! Müfredata uygun en güncel soruları şimdi keşfet ve eksiklerini kapat.",
        channel: "general",
        icon: "library_add"
    },
    {
        title: "🔥 Çalışma Serini Koruma Vakti",
        body: "Serin bozulmasın! Sadece 10 dakika ayırarak bugünkü çalışma görevini tamamlayabilir ve hedefine bir adım daha yaklaşabilirsin.",
        channel: "streak_alert",
        icon: "local_fire_department"
    },
    {
        title: "✍️ Haftalık Deneme Saati",
        body: "Gerçek sınav provasına hazır mısın? Haftalık denemeni çözerek Türkiye geneli sıralamanı ve gelişimini hemen gör.",
        channel: "general",
        icon: "edit_note"
    },
    {
        title: "🧠 AI Koç Senin İçin Burada",
        body: "Zorlandığın konuları analiz ettim. Senin için bugün odaklanman gereken 3 kritik konuyu listeledim, hadi göz atalım.",
        channel: "motivation",
        icon: "psychology"
    },
    {
        title: "📊 Gelişim Raporun Yayında",
        body: "Geçen haftaya göre netlerin %15 arttı! Bu tempoyla devam edersen hedefine ulaşman çok yakın. Analizini incele.",
        channel: "motivation",
        icon: "bar_chart"
    },
    {
        title: "🎯 Hedef: Memurluk!",
        body: "Hayallerindeki o kadro için bugün neler yaptın? Küçük adımlar büyük sonuçlar doğurur. Şimdi başla!",
        channel: "daily_reminder",
        icon: "target"
    },
    {
        title: "💡 Günün Kritik Bilgisi",
        body: "Sınavda çıkma ihtimali yüksek 'Güncel Bilgiler' notunu hazırladım. Hemen oku, 1 neti cebine koy!",
        channel: "general",
        icon: "lightbulb"
    },
    {
        title: "🏆 Rakiplerin Şu An Çalışıyor",
        body: "Şu an binlerce kişi seninle aynı hedefe koşuyor. Onlardan bir adım önde olmak için şimdi bir test çözmeye ne dersin?",
        channel: "motivation",
        icon: "groups"
    },
    {
        title: "⛔ Hatalarından Ders Çıkar",
        body: "Denemelerde yanlış yaptığın soruları tekrar çözmek, en iyi öğrenme yöntemidir. Yanlışlarını senin için listeledim.",
        channel: "motivation",
        icon: "rule"
    },
    {
        title: "💎 Premium Ayrıcalıklarını Keşfet",
        body: "Reklamsız çalışma, sınırsız yapay zeka desteği ve özel denemeler... Başarı yolculuğunu Premium ile hızlandır.",
        channel: "general",
        icon: "stars"
    },
    {
        title: "😴 Verimli Bir Dinlenme İçin...",
        body: "Bugün harika iş çıkardın! Şimdi zihnini dinlendirme vakti. Yarın daha güçlü bir şekilde devam edeceğiz.",
        channel: "daily_reminder",
        icon: "bedtime"
    },
    {
        title: "🚀 Hız Limitini Zorla!",
        body: "Zamana karşı yarışta hızlanman gerekiyor. Bugün 'Hızlı Soru Çözme' modu ile limitlerini test etmeye ne dersin?",
        channel: "motivation",
        icon: "speed"
    },
    {
        title: "📢 Önemli Sınav Duyurusu",
        body: "Sınav takvimi ve süreçle ilgili yeni bir güncelleme var. Bilgi kirliliğinden uzak, en doğru haberi hemen oku.",
        channel: "general",
        icon: "campaign"
    },
    {
        title: "🤝 Beraber Başaracağız",
        body: "Yalnız değilsin! KPSS Asistan yanındaki en güçlü destekçin. Takıldığın her an bana sorabilirsin.",
        channel: "motivation",
        icon: "handshake"
    }
];

window.initNotificationsPage = function () {
    console.log('Notification page initialized');

    // Load from storage
    const stored = localStorage.getItem('kpss_notif_templates');
    if (stored) {
        myTemplates = JSON.parse(stored);
    } else {
        myTemplates = [...DEFAULT_TEMPLATES];
    }

    // Setup preview listeners
    const titleInput = document.getElementById('notifTitle');
    const bodyInput = document.getElementById('notifBody');
    const imgInput = document.getElementById('notifImage');
    const prevTitle = document.getElementById('prevNotifTitle');
    const prevBody = document.getElementById('prevNotifBody');
    const prevImg = document.getElementById('prevNotifImg');
    const prevImgContainer = document.getElementById('prevNotifImgContainer');

    if (titleInput && bodyInput && prevTitle && prevBody) {
        const updateNotifPreview = () => {
            prevTitle.innerText = titleInput.value || 'Başlık...';
            prevBody.innerText = bodyInput.value || 'Mesaj içeriği burada görünecek...';

            if (imgInput && imgInput.value) {
                prevImg.src = imgInput.value;
                prevImgContainer.style.display = 'block';
            } else if (prevImgContainer) {
                prevImgContainer.style.display = 'none';
            }
        };

        titleInput.oninput = updateNotifPreview;
        bodyInput.oninput = updateNotifPreview;
        if (imgInput) imgInput.oninput = updateNotifPreview;
    }

    renderTemplates();
};

function renderTemplates() {
    const grid = document.getElementById('notifTemplateGrid');
    if (!grid) return;

    grid.innerHTML = myTemplates.map((t, i) => `
        <div style="background:var(--card-bg); border:1px solid var(--border); border-radius:12px; display:flex; gap:12px; align-items:center; padding:10px 14px; position:relative; overflow:hidden">
            <div onclick="applyNotifTemplate(${i})" style="flex:1; cursor:pointer; display:flex; gap:12px; align-items:center">
                <span class="material-icons-round" style="color:var(--accent); font-size:1.4rem">${t.icon || 'star'}</span>
                <div style="font-size:0.85rem; font-weight:600; color:var(--text); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:180px">${t.title}</div>
            </div>
            <button onclick="deleteTemplate(${i})" style="background:none; border:none; color:#ef4444; padding:4px; opacity:0.5; cursor:pointer; font-size:1.1rem" onmouseover="this.style.opacity=1" onmouseout="this.style.opacity=0.5">
                <span class="material-icons-round" style="font-size:1.2rem">delete</span>
            </button>
        </div>
    `).join('');
}

window.saveAsTemplate = function () {
    const title = document.getElementById('notifTitle').value.trim();
    const body = document.getElementById('notifBody').value.trim();
    const channelId = document.getElementById('notifChannel').value;

    if (!title || !body) {
        showToast('Başlık ve mesaj olmadan şablon kaydedilemez!', 'warning');
        return;
    }

    const newTemplate = {
        title,
        body,
        channel: channelId,
        icon: 'stars'
    };

    myTemplates.unshift(newTemplate);
    localStorage.setItem('kpss_notif_templates', JSON.stringify(myTemplates));
    renderTemplates();
    showToast('Şablon kaydedildi!', 'success');
};

window.deleteTemplate = function (index) {
    if (!confirm('Bu şablonu silmek istediğine emin misin?')) return;
    myTemplates.splice(index, 1);
    localStorage.setItem('kpss_notif_templates', JSON.stringify(myTemplates));
    renderTemplates();
};

window.resetDefaultTemplates = function () {
    if (!confirm('Tüm şablonlar varsayılana dönecek. Emin misin?')) return;
    myTemplates = [...DEFAULT_TEMPLATES];
    localStorage.setItem('kpss_notif_templates', JSON.stringify(myTemplates));
    renderTemplates();
};

window.applyNotifTemplate = function (index) {
    const t = myTemplates[index];
    document.getElementById('notifTitle').value = t.title;
    document.getElementById('notifBody').value = t.body;
    document.getElementById('notifChannel').value = t.channel;

    // Explicitly update preview
    document.getElementById('notifTitle').dispatchEvent(new Event('input'));
    showToast('Şablon uygulandı!', 'success');
};

window.sendNotification = async function () {
    const title = document.getElementById('notifTitle').value.trim();
    const body = document.getElementById('notifBody').value.trim();
    const imageUrl = document.getElementById('notifImage').value.trim();
    const channelId = document.getElementById('notifChannel').value;
    const target = document.getElementById('notifTarget').value;
    const personalized = document.getElementById('notifPersonalized')?.checked || false;
    const btn = document.getElementById('btnSendNotif');
    const status = document.getElementById('notifStatus');

    if (!title || !body) {
        showToast('Lütfen başlık ve mesaj girin!', 'warning');
        return;
    }

    if (!confirm(`Bildirim gönderilecek: "${title}"\nOnaylıyor musunuz?`)) return;

    btn.disabled = true;
    btn.innerHTML = '<span class="material-icons-round">sync</span> GÖNDERİLİYOR...';
    status.style.display = 'block';
    status.innerHTML = '<span style="color:var(--text-muted)">İşlem sürüyor...</span>';

    try {
        const res = await fetch(API + '/api/notifications/send', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ title, body, imageUrl, channelId, target, personalized })
        });

        const data = await res.json();

        if (data.success) {
            const info = data.sent != null ? `${data.sent}/${data.total} kullanıcıya gönderildi` : (data.messageId || 'OK');
            showToast('✅ Bildirim başarıyla gönderildi!', 'success');
            status.innerHTML = `<span style="color:#22c55e">✓ ${info}</span>`;
            // Clear inputs
            document.getElementById('notifTitle').value = '';
            document.getElementById('notifBody').value = '';
            document.getElementById('notifImage').value = '';
            document.getElementById('prevNotifTitle').innerText = 'Başlık...';
            document.getElementById('prevNotifBody').innerText = 'Mesaj içeriği burada görünecek...';
            document.getElementById('prevNotifImgContainer').style.display = 'none';
        } else {
            showToast('❌ Hata: ' + data.error, 'error');
            status.innerHTML = `<span style="color:#ef4444">⚠ Hata: ${data.error}</span>`;
        }
    } catch (e) {
        console.error(e);
        showToast('Bağlantı hatası', 'error');
        status.innerHTML = '<span style="color:#ef4444">⚠ Bağlantı hatası</span>';
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<span class="material-icons-round">send</span> BİLDİRİMİ GÖNDER';
    }
};


/* === modules\flashcards.js === */

/**
 * Flashcards Module
 * Flashcard setleri için CRUD işlemleri
 */

// Global variables
let currentFlashcardFile = null;
let flashcardData = [];

// Initialize flashcards module
function initFlashcards() {
    loadFlashcardFiles();
}

// Load flashcard files list
async function loadFlashcardFiles() {
    try {
        const response = await fetch(API + '/flashcards');
        const data = await response.json();

        console.log('[Flashcards] Response:', data);

        if (data.success) {
            const select = document.getElementById('flashcardFile');
            select.innerHTML = '<option value="">Set seçin...</option>';

            console.log('[Flashcards] Files to add:', data.flashcards.length);
            data.flashcards.forEach(file => {
                const option = document.createElement('option');
                option.value = file.filename;
                option.textContent = `${file.title || file.id} (${file.count} kart)`;
                select.appendChild(option);
                console.log('[Flashcards] Added:', file.title || file.id);
            });
        }
    } catch (error) {
        console.error('Flashcard dosyaları yüklenemedi:', error);
    }
}

// Load specific flashcard file
async function loadFlashcardFile() {
    const select = document.getElementById('flashcardFile');
    const filename = select.value;

    if (!filename) {
        document.getElementById('flashcardEditor').value = '';
        currentFlashcardFile = null;
        flashcardData = [];
        return;
    }

    try {
        const response = await fetch(API + `/flashcards/${filename}`);
        const data = await response.json();

        if (data.success) {
            currentFlashcardFile = filename;
            flashcardData = data.cards;
            document.getElementById('flashcardEditor').value = JSON.stringify(data.cards, null, 2);
        }
    } catch (error) {
        console.error('Flashcard dosyası yüklenemedi:', error);
        showToast('Flashcard dosyası yüklenemedi', 'error');
    }
}

// Save flashcards - Save the entire array
async function saveFlashcards() {
    if (!currentFlashcardFile) {
        showToast('Önce bir flashcard seti seçin', 'warning');
        return;
    }

    const editor = document.getElementById('flashcardEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const cards = JSON.parse(jsonText);

        // Validate structure
        if (!Array.isArray(cards)) {
            showToast('Flashcard verisi bir dizi olmalı', 'error');
            return;
        }

        for (let i = 0; i < cards.length; i++) {
            const card = cards[i];
            if (!card.question || !card.answer) {
                showToast(`Kart ${i + 1}: question ve answer alanları zorunlu`, 'error');
                return;
            }
        }

        // Save entire array to server
        const response = await fetch(API + `/flashcards/${currentFlashcardFile}/save`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ cards })
        });

        const data = await response.json();

        if (data.success) {
            showToast('Flashcards kaydedildi', 'success');
            flashcardData = cards;
            // Refresh file list
            loadFlashcardFiles();
        } else {
            showToast(data.error || 'Kayıt başarısız', 'error');
        }
    } catch (error) {
        if (error instanceof SyntaxError) {
            showToast('Geçersiz JSON formatı', 'error');
        } else {
            console.error('Kayıt hatası:', error);
            showToast('Kayıt başarısız', 'error');
        }
    }
}

// Validate flashcards
function validateFlashcards() {
    const editor = document.getElementById('flashcardEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const cards = JSON.parse(jsonText);

        if (!Array.isArray(cards)) {
            showToast('Flashcard verisi bir dizi olmalı', 'error');
            return;
        }

        let errors = [];
        let warnings = [];

        cards.forEach((card, index) => {
            if (!card.question) {
                errors.push(`Kart ${index + 1}: question alanı eksik`);
            }
            if (!card.answer) {
                errors.push(`Kart ${index + 1}: answer alanı eksik`);
            }
            if (card.question && card.question.length < 3) {
                warnings.push(`Kart ${index + 1}: question çok kısa`);
            }
            if (card.answer && card.answer.length < 3) {
                warnings.push(`Kart ${index + 1}: answer çok kısa`);
            }
        });

        if (errors.length > 0) {
            showToast('Hatalar: ' + errors.join(', '), 'error');
        } else if (warnings.length > 0) {
            showToast('Uyarılar: ' + warnings.join(', '), 'warning');
        } else {
            showToast('Tüm flashcard\'lar geçerli', 'success');
        }
    } catch (error) {
        if (error instanceof SyntaxError) {
            showToast('Geçersiz JSON formatı', 'error');
        } else {
            showToast('Doğrulama hatası', 'error');
        }
    }
}

// Export functions for global use
window.initFlashcards = initFlashcards;
window.loadFlashcardFiles = loadFlashcardFiles;
window.loadFlashcardFile = loadFlashcardFile;
window.saveFlashcards = saveFlashcards;
window.validateFlashcards = validateFlashcards;


/* === modules\stories.js === */

/**
 * Stories Module
 * Hikaye dosyaları için CRUD işlemleri
 */

// Global variables
let currentStoryFile = null;
let storyData = [];

// Initialize stories module
function initStories() {
    loadStoryFiles();
}

// Load story files list
async function loadStoryFiles() {
    try {
        const response = await fetch('/stories');
        const data = await response.json();

        if (data.success) {
            const select = document.getElementById('storyFile');
            select.innerHTML = '<option value="">Dosya seçin...</option>';

            data.stories.forEach(file => {
                const option = document.createElement('option');
                option.value = file.filename;
                option.textContent = `${file.title || file.id} (${file.count} hikaye)`;
                select.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Hikaye dosyaları yüklenemedi:', error);
    }
}

// Load specific story file
async function loadStoryFile() {
    const select = document.getElementById('storyFile');
    const filename = select.value;

    if (!filename) {
        document.getElementById('storyEditor').value = '';
        currentStoryFile = null;
        storyData = [];
        return;
    }

    try {
        const response = await fetch(`/stories/${filename}`);
        const data = await response.json();

        if (data.success) {
            currentStoryFile = filename;
            storyData = data.stories;
            document.getElementById('storyEditor').value = JSON.stringify(data.stories, null, 2);
        }
    } catch (error) {
        console.error('Hikaye dosyası yüklenemedi:', error);
        showToast('Hikaye dosyası yüklenemedi', 'error');
    }
}

// Save stories - Save the entire array
async function saveStories() {
    if (!currentStoryFile) {
        showToast('Önce bir hikaye dosyası seçin', 'warning');
        return;
    }

    const editor = document.getElementById('storyEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const stories = JSON.parse(jsonText);

        // Validate structure
        if (!Array.isArray(stories)) {
            showToast('Hikaye verisi bir dizi olmalı', 'error');
            return;
        }

        for (let i = 0; i < stories.length; i++) {
            const story = stories[i];
            if (!story.title || !story.content) {
                showToast(`Hikaye ${i + 1}: title ve content alanları zorunlu`, 'error');
                return;
            }
        }

        // Save entire array to server
        const response = await fetch(`/stories/${currentStoryFile}/save`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ stories })
        });

        const data = await response.json();

        if (data.success) {
            showToast('Hikayeler kaydedildi', 'success');
            storyData = stories;
            // Refresh file list
            loadStoryFiles();
        } else {
            showToast(data.error || 'Kayıt başarısız', 'error');
        }
    } catch (error) {
        if (error instanceof SyntaxError) {
            showToast('Geçersiz JSON formatı', 'error');
        } else {
            console.error('Kayıt hatası:', error);
            showToast('Kayıt başarısız', 'error');
        }
    }
}

// Validate stories
function validateStories() {
    const editor = document.getElementById('storyEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const stories = JSON.parse(jsonText);

        if (!Array.isArray(stories)) {
            showToast('Hikaye verisi bir dizi olmalı', 'error');
            return;
        }

        let errors = [];
        let warnings = [];

        stories.forEach((story, index) => {
            if (!story.title) {
                errors.push(`Hikaye ${index + 1}: title alanı eksik`);
            }
            if (!story.content) {
                errors.push(`Hikaye ${index + 1}: content alanı eksik`);
            }
            if (story.title && story.title.length < 5) {
                warnings.push(`Hikaye ${index + 1}: title çok kısa`);
            }
            if (story.content && story.content.length < 50) {
                warnings.push(`Hikaye ${index + 1}: content çok kısa`);
            }
            if (story.keyPoints && !Array.isArray(story.keyPoints)) {
                errors.push(`Hikaye ${index + 1}: keyPoints bir dizi olmalı`);
            }
        });

        if (errors.length > 0) {
            showToast('Hatalar: ' + errors.join(', '), 'error');
        } else if (warnings.length > 0) {
            showToast('Uyarılar: ' + warnings.join(', '), 'warning');
        } else {
            showToast('Tüm hikayeler geçerli', 'success');
        }
    } catch (error) {
        if (error instanceof SyntaxError) {
            showToast('Geçersiz JSON formatı', 'error');
        } else {
            showToast('Doğrulama hatası', 'error');
        }
    }
}

// Export functions for global use
window.initStories = initStories;
window.loadStoryFiles = loadStoryFiles;
window.loadStoryFile = loadStoryFile;
window.saveStories = saveStories;
window.validateStories = validateStories;


/* === modules\explanations.js === */

/**
 * Explanations Module
 * Açıklama dosyaları için CRUD işlemleri
 */

// Global variables
let currentExplanationFile = null;
let explanationData = [];

// Initialize explanations module
function initExplanations() {
    loadExplanationFiles();
}

// Load explanation files list
async function loadExplanationFiles() {
    try {
        const response = await fetch('/explanations');
        const data = await response.json();

        if (data.success) {
            const select = document.getElementById('explanationFile');
            select.innerHTML = '<option value="">Dosya seçin...</option>';

            data.explanations.forEach(file => {
                const option = document.createElement('option');
                option.value = file.filename;
                option.textContent = `${file.title || file.id} (${file.count} açıklama)`;
                select.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Açıklama dosyaları yüklenemedi:', error);
    }
}

// Load specific explanation file
async function loadExplanationFile() {
    const select = document.getElementById('explanationFile');
    const filename = select.value;

    if (!filename) {
        document.getElementById('explanationEditor').value = '';
        currentExplanationFile = null;
        explanationData = [];
        return;
    }

    try {
        const response = await fetch(`/explanations/${filename}`);
        const data = await response.json();

        if (data.success) {
            currentExplanationFile = filename;
            explanationData = data.explanations;
            document.getElementById('explanationEditor').value = JSON.stringify(data.explanations, null, 2);
        }
    } catch (error) {
        console.error('Açıklama dosyası yüklenemedi:', error);
        showToast('Açıklama dosyası yüklenemedi', 'error');
    }
}

// Save explanations - Save the entire array instead of just the last item
async function saveExplanations() {
    if (!currentExplanationFile) {
        showToast('Önce bir açıklama dosyası seçin', 'warning');
        return;
    }

    const editor = document.getElementById('explanationEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const explanations = JSON.parse(jsonText);

        // Validate structure
        if (!Array.isArray(explanations)) {
            showToast('Açıklama verisi bir dizi olmalı', 'error');
            return;
        }

        for (let i = 0; i < explanations.length; i++) {
            const explanation = explanations[i];
            if (!explanation.topicId || !explanation.title || !explanation.content) {
                showToast(`Açıklama ${i + 1}: topicId, title ve content alanları zorunlu`, 'error');
                return;
            }
        }

        // Save entire array to server using PUT endpoint
        const response = await fetch(`/explanations/${currentExplanationFile}/save`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ explanations })
        });

        const data = await response.json();

        if (data.success) {
            showToast('Açıklamalar kaydedildi', 'success');
            explanationData = explanations;
            // Refresh file list to show updated count
            loadExplanationFiles();
        } else {
            showToast(data.error || 'Kayıt başarısız', 'error');
        }
    } catch (error) {
        if (error instanceof SyntaxError) {
            showToast('Geçersiz JSON formatı', 'error');
        } else {
            console.error('Kayıt hatası:', error);
            showToast('Kayıt başarısız', 'error');
        }
    }
}

// Validate explanations
function validateExplanations() {
    const editor = document.getElementById('explanationEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const explanations = JSON.parse(jsonText);

        if (!Array.isArray(explanations)) {
            showToast('Açıklama verisi bir dizi olmalı', 'error');
            return;
        }

        let errors = [];
        let warnings = [];

        explanations.forEach((explanation, index) => {
            if (!explanation.topicId) {
                errors.push(`Açıklama ${index + 1}: topicId alanı eksik`);
            }
            if (!explanation.title) {
                errors.push(`Açıklama ${index + 1}: title alanı eksik`);
            }
            if (!explanation.content) {
                errors.push(`Açıklama ${index + 1}: content alanı eksik`);
            }
            if (explanation.title && explanation.title.length < 5) {
                warnings.push(`Açıklama ${index + 1}: title çok kısa`);
            }
            if (explanation.content && explanation.content.length < 20) {
                warnings.push(`Açıklama ${index + 1}: content çok kısa`);
            }
            if (explanation.type && !['general', 'detailed', 'summary'].includes(explanation.type)) {
                warnings.push(`Açıklama ${index + 1}: geçersiz type`);
            }
            if (explanation.difficulty && !['easy', 'medium', 'hard'].includes(explanation.difficulty)) {
                warnings.push(`Açıklama ${index + 1}: geçersiz difficulty`);
            }
        });

        if (errors.length > 0) {
            showToast('Hatalar: ' + errors.join(', '), 'error');
        } else if (warnings.length > 0) {
            showToast('Uyarılar: ' + warnings.join(', '), 'warning');
        } else {
            showToast('Tüm açıklamalar geçerli', 'success');
        }
    } catch (error) {
        if (error instanceof SyntaxError) {
            showToast('Geçersiz JSON formatı', 'error');
        } else {
            showToast('Doğrulama hatası', 'error');
        }
    }
}

// Export functions for global use
window.initExplanations = initExplanations;
window.loadExplanationFiles = loadExplanationFiles;
window.loadExplanationFile = loadExplanationFile;
window.saveExplanations = saveExplanations;
window.validateExplanations = validateExplanations;


/* === modules\matching_games.js === */

/**
 * Matching Games Module
 * Eşleştirme oyunları için CRUD işlemleri
 */

// Global variables
let currentMatchingGameFile = null;
let matchingGameData = [];

// Initialize matching games module
function initMatchingGames() {
    loadMatchingGameFiles();
}

// Load matching game files list
async function loadMatchingGameFiles() {
    try {
        const response = await fetch('/matching-games');
        const data = await response.json();

        if (data.success) {
            const select = document.getElementById('matchingGameFile');
            select.innerHTML = '<option value="">Dosya seçin...</option>';

            data.games.forEach(file => {
                const option = document.createElement('option');
                option.value = file.filename;
                option.textContent = `${file.title || file.id} (${file.count} oyun)`;
                select.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Eşleştirme oyunu dosyaları yüklenemedi:', error);
    }
}

// Load specific matching game file
async function loadMatchingGameFile() {
    const select = document.getElementById('matchingGameFile');
    const filename = select.value;

    if (!filename) {
        document.getElementById('matchingGameEditor').value = '';
        currentMatchingGameFile = null;
        matchingGameData = [];
        return;
    }

    try {
        const response = await fetch(`/matching-games/${filename}`);
        const data = await response.json();

        if (data.success) {
            currentMatchingGameFile = filename;
            matchingGameData = data.games;
            document.getElementById('matchingGameEditor').value = JSON.stringify(data.games, null, 2);
        }
    } catch (error) {
        console.error('Eşleştirme oyunu dosyası yüklenemedi:', error);
        showToast('Eşleştirme oyunu dosyası yüklenemedi', 'error');
    }
}

// Save matching games - Save the entire array
async function saveMatchingGames() {
    if (!currentMatchingGameFile) {
        showToast('Önce bir oyun dosyası seçin', 'warning');
        return;
    }

    const editor = document.getElementById('matchingGameEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const games = JSON.parse(jsonText);

        // Validate structure
        if (!Array.isArray(games)) {
            showToast('Oyun verisi bir dizi olmalı', 'error');
            return;
        }

        for (let i = 0; i < games.length; i++) {
            const game = games[i];
            if (!game.title || !game.question || !game.pairs) {
                showToast(`Oyun ${i + 1}: title, question ve pairs alanları zorunlu`, 'error');
                return;
            }
            if (!Array.isArray(game.pairs)) {
                showToast(`Oyun ${i + 1}: pairs bir dizi olmalı`, 'error');
                return;
            }
        }

        // Save entire array to server
        const response = await fetch(`/matching-games/${currentMatchingGameFile}/save`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ games })
        });

        const data = await response.json();

        if (data.success) {
            showToast('Eşleştirme oyunları kaydedildi', 'success');
            matchingGameData = games;
            // Refresh file list
            loadMatchingGameFiles();
        } else {
            showToast(data.error || 'Kayıt başarısız', 'error');
        }
    } catch (error) {
        if (error instanceof SyntaxError) {
            showToast('Geçersiz JSON formatı', 'error');
        } else {
            console.error('Kayıt hatası:', error);
            showToast('Kayıt başarısız', 'error');
        }
    }
}

// Validate matching games
function validateMatchingGames() {
    const editor = document.getElementById('matchingGameEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const games = JSON.parse(jsonText);

        if (!Array.isArray(games)) {
            showToast('Oyun verisi bir dizi olmalı', 'error');
            return;
        }

        let errors = [];
        let warnings = [];

        games.forEach((game, index) => {
            if (!game.title) {
                errors.push(`Oyun ${index + 1}: title alanı eksik`);
            }
            if (!game.question) {
                errors.push(`Oyun ${index + 1}: question alanı eksik`);
            }
            if (!game.pairs) {
                errors.push(`Oyun ${index + 1}: pairs alanı eksik`);
            }
            if (game.pairs && !Array.isArray(game.pairs)) {
                errors.push(`Oyun ${index + 1}: pairs bir dizi olmalı`);
            }
            if (game.title && game.title.length < 5) {
                warnings.push(`Oyun ${index + 1}: title çok kısa`);
            }
            if (game.question && game.question.length < 10) {
                warnings.push(`Oyun ${index + 1}: question çok kısa`);
            }
            if (game.pairs && Array.isArray(game.pairs)) {
                if (game.pairs.length < 2) {
                    warnings.push(`Oyun ${index + 1}: en az 2 çift olmalı`);
                }
                game.pairs.forEach((pair, pairIndex) => {
                    if (!pair.left || !pair.right) {
                        errors.push(`Oyun ${index + 1}, çift ${pairIndex + 1}: left ve right alanları zorunlu`);
                    }
                });
            }
            if (game.difficulty && !['easy', 'medium', 'hard'].includes(game.difficulty)) {
                warnings.push(`Oyun ${index + 1}: geçersiz difficulty`);
            }
        });

        if (errors.length > 0) {
            showToast('Hatalar: ' + errors.join(', '), 'error');
        } else if (warnings.length > 0) {
            showToast('Uyarılar: ' + warnings.join(', '), 'warning');
        } else {
            showToast('Tüm eşleştirme oyunları geçerli', 'success');
        }
    } catch (error) {
        if (error instanceof SyntaxError) {
            showToast('Geçersiz JSON formatı', 'error');
        } else {
            showToast('Doğrulama hatası', 'error');
        }
    }
}

// Export functions for global use
window.loadMatchingGameFiles = loadMatchingGameFiles;
window.loadMatchingGameFile = loadMatchingGameFile;
window.saveMatchingGames = saveMatchingGames;
window.validateMatchingGames = validateMatchingGames;


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

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initApp);
} else {
    initApp();
}

// ═══════════════════════════════════════════════════════════════════════════
// QUALITY CHECK MODULE
// ═══════════════════════════════════════════════════════════════════════════

window.qualityCheck = (() => {
    let _lastResults = null;
    let _hasRun = false;
    let _currentSource = 'local';
    let _pendingPush = false;  // fix/remove sonrası push bekliyor mu

    // ── helpers ──────────────────────────────────────────────────────────────

    function escapeHtml(str) {
        return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    function toast(msg, type = 'success') {
        const t = document.getElementById('toast');
        const m = document.getElementById('toastMessage');
        if (!t || !m) { alert(msg); return; }
        m.textContent = msg;
        t.style.background = type === 'error' ? 'var(--danger)' : type === 'warn' ? '#d97706' : 'var(--success)';
        t.classList.add('show');
        setTimeout(() => t.classList.remove('show'), 3500);
    }

    function setLoading(on) {
        document.getElementById('qc-loading').style.display = on ? 'block' : 'none';
        if (on) document.getElementById('qc-results').innerHTML = '';
        ['qc-run-local'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.disabled = on;
        });
        if (on) document.getElementById('qc-summary').style.display = 'none';
    }

    // ── summary ───────────────────────────────────────────────────────────────

    function renderSummary(s, source) {
        document.getElementById('qc-stat-topics').textContent = s.totalTopics;
        document.getElementById('qc-stat-questions').textContent = s.totalQuestions.toLocaleString();
        document.getElementById('qc-stat-clean').textContent = s.cleanTopics;
        document.getElementById('qc-stat-errors').textContent = s.totalErrors;
        document.getElementById('qc-stat-warns').textContent = s.totalWarns;
        document.getElementById('qc-summary').style.display = 'grid';

        // Global aksiyon butonları
        const fixBtn = document.getElementById('qc-fix-btn');
        const removeBtn = document.getElementById('qc-remove-btn');
        if (source === 'local') {
            if (fixBtn) fixBtn.style.display = s.totalWarns > 0 ? 'flex' : 'none';
            if (removeBtn) removeBtn.style.display = s.totalErrors > 0 ? 'flex' : 'none';
        } else {
            if (fixBtn) fixBtn.style.display = 'none';
            if (removeBtn) removeBtn.style.display = 'none';
        }
    }

    // ── results ───────────────────────────────────────────────────────────────

    function severityBadge(severity) {
        return severity === 'error'
            ? `<span style="background:rgba(239,68,68,.15);color:#f87171;border:1px solid rgba(239,68,68,.3);padding:2px 6px;border-radius:4px;font-size:11px;font-weight:600">HATA</span>`
            : `<span style="background:rgba(245,158,11,.15);color:#fbbf24;border:1px solid rgba(245,158,11,.3);padding:2px 6px;border-radius:4px;font-size:11px;font-weight:600">UYARI</span>`;
    }

    function actionButtons(r, source) {
        if (source !== 'local') return ''; // Sadece yerel dosyalarda düzeltme yapılabilir
        const btns = [];

        const hasPrefixWarns = r.issues && r.issues.some(i => i.severity === 'warn' && i.msg.includes('prefix'));
        // "Bozuk" = encoding hatası VEYA zorunlu alan eksik (q/o/a eksik, geçersiz index)
        const hasEncodingErrors = r.issues && r.issues.some(i => i.severity === 'error');

        if (hasPrefixWarns) {
            btns.push(`<button onclick="qualityCheck.fixTopicPrefixes('${r.topicId}', this)"
                style="background:rgba(245,158,11,.15);border:1px solid rgba(245,158,11,.4);color:#fbbf24;
                       padding:4px 10px;border-radius:6px;cursor:pointer;font-size:12px;display:flex;align-items:center;gap:4px;white-space:nowrap">
                <span class="material-icons-round" style="font-size:14px">auto_fix_high</span>Prefix Temizle
            </button>`);
        }

        if (hasEncodingErrors) {
            btns.push(`<button onclick="qualityCheck.removeBrokenQuestions('${r.topicId}', this)"
                style="background:rgba(239,68,68,.15);border:1px solid rgba(239,68,68,.4);color:#f87171;
                       padding:4px 10px;border-radius:6px;cursor:pointer;font-size:12px;display:flex;align-items:center;gap:4px;white-space:nowrap">
                <span class="material-icons-round" style="font-size:14px">delete_sweep</span>Bozukları Sil (${r.issues.filter(i => i.severity === 'error' && i.msg.includes('encoding')).length})
            </button>`);
        }

        return btns.join('');
    }

    function renderResults(results, source) {
        const container = document.getElementById('qc-results');
        if (!results.length) {
            container.innerHTML = '<p style="color:var(--text-secondary);text-align:center;padding:2rem">Sonuç yok</p>';
            return;
        }

        container.innerHTML = results.map(r => {
            const isClean = !r.parseError && !r.fetchError && r.errorCount === 0 && r.warnCount === 0;
            const hasError = r.parseError || r.fetchError || r.errorCount > 0;
            const borderColor = isClean ? 'var(--success)' : (hasError ? 'var(--danger)' : 'var(--warning)');
            const icon = isClean ? '✅' : (hasError ? '❌' : '⚠️');
            const expandId = `qc-issues-${r.topicId}`;

            const issuesHtml = r.issues && r.issues.length > 0
                ? `<div id="${expandId}" style="display:none;margin-top:0.75rem;border-top:1px solid var(--border);padding-top:0.75rem;max-height:300px;overflow-y:auto;">
                    ${r.issues.map(i => `
                        <div style="display:flex;gap:0.5rem;align-items:flex-start;padding:3px 0;font-size:12px;color:var(--text-secondary);">
                            ${severityBadge(i.severity)}
                            <span style="color:var(--text-muted);min-width:36px;flex-shrink:0">[${i.idx}]</span>
                            <span style="word-break:break-word">${escapeHtml(i.msg)}</span>
                        </div>`).join('')}
                   </div>`
                : '';

            const errorMsg = r.parseError || r.fetchError
                ? `<span style="color:var(--danger);font-size:12px">${escapeHtml(r.parseError || r.fetchError)}</span>`
                : '';

            const detailBtn = r.issues && r.issues.length > 0
                ? `<button onclick="qualityCheck.toggleIssues('${expandId}', this)"
                        style="background:transparent;border:1px solid var(--border);color:var(--text-muted);
                               padding:4px 10px;border-radius:6px;cursor:pointer;font-size:12px;
                               display:flex;align-items:center;gap:4px">
                        <span class="material-icons-round" style="font-size:14px">expand_more</span>Detay
                    </button>`
                : '';

            return `<div id="qc-card-${r.topicId}" style="background:var(--bg-card);border:1px solid ${borderColor};border-radius:12px;padding:0.875rem 1rem;">
                <div style="display:flex;align-items:center;gap:0.75rem;flex-wrap:wrap;">
                    <span style="font-size:15px">${icon}</span>
                    <span style="font-family:monospace;font-size:13px;color:var(--text-primary);font-weight:600">${r.topicId}</span>
                    ${errorMsg}
                    <span style="color:var(--text-muted);font-size:12px">${r.questionCount || 0} soru</span>
                    ${r.errorCount > 0 ? `<span style="color:var(--danger);font-size:12px;font-weight:600">${r.errorCount} hata</span>` : ''}
                    ${r.warnCount > 0 ? `<span style="color:var(--warning);font-size:12px;font-weight:600">${r.warnCount} uyarı</span>` : ''}
                    <div style="margin-left:auto;display:flex;gap:0.5rem;align-items:center;flex-wrap:wrap;">
                        ${actionButtons(r, source)}
                        ${detailBtn}
                    </div>
                </div>
                ${issuesHtml}
            </div>`;
        }).join('');
    }

    // ── run ───────────────────────────────────────────────────────────────────

    async function run(source) {
        _currentSource = source || 'local';
        const topicFilter = (document.getElementById('qc-topic-filter')?.value || '').trim();
        const url = `/api/quality-check?source=${_currentSource}${topicFilter ? '&topic=' + encodeURIComponent(topicFilter) : ''}`;

        setLoading(true);

        try {
            const res = await fetch(url);
            const data = await res.json();
            _lastResults = { ...data, source: _currentSource };
            renderSummary(data.summary, _currentSource);
            renderResults(data.results, _currentSource);
        } catch (e) {
            document.getElementById('qc-results').innerHTML =
                `<div style="color:var(--danger);padding:1rem">Bağlantı hatası: ${escapeHtml(e.message)}</div>`;
        } finally {
            setLoading(false);
        }
    }

    // ── topic-level actions ───────────────────────────────────────────────────

    async function fixTopicPrefixes(topicId, btn) {
        const origHtml = btn.innerHTML;
        btn.disabled = true;
        btn.innerHTML = '<span class="material-icons-round" style="font-size:14px;animation:spin .8s linear infinite">sync</span>Temizleniyor...';

        try {
            const res = await fetch('/api/quality-check/fix', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ topicIds: [topicId] }),
            });
            const data = await res.json();
            const total = data.totalFixed || 0;
            toast(`✅ ${topicId}: ${total} prefix temizlendi`);
            // Kartı kaldır veya yenile
            setTimeout(() => refreshCard(topicId), 500);
        } catch (e) {
            toast('Hata: ' + e.message, 'error');
            btn.disabled = false;
            btn.innerHTML = origHtml;
        }
    }

    async function removeBrokenQuestions(topicId, btn) {
        const card = document.getElementById(`qc-card-${topicId}`);
        const errorCount = parseInt(btn.textContent.match(/\d+/) || [0]);
        if (!confirm(`"${topicId}" içindeki ${errorCount} encoding hatalı soru silinecek. Bu işlem geri alınamaz. Devam?`)) return;

        const origHtml = btn.innerHTML;
        btn.disabled = true;
        btn.innerHTML = '<span class="material-icons-round" style="font-size:14px;animation:spin .8s linear infinite">sync</span>Siliniyor...';

        try {
            const res = await fetch('/api/quality-check/remove-broken', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ topicIds: [topicId] }),
            });
            const data = await res.json();
            const total = data.totalRemoved || 0;
            toast(`🗑️ ${topicId}: ${total} bozuk soru silindi`, 'warn');
            setTimeout(() => refreshCard(topicId), 500);
        } catch (e) {
            toast('Hata: ' + e.message, 'error');
            btn.disabled = false;
            btn.innerHTML = origHtml;
        }
    }

    async function refreshCard(topicId) {
        try {
            const res = await fetch(`/api/quality-check?source=local&topic=${encodeURIComponent(topicId)}`);
            const data = await res.json();
            const card = document.getElementById(`qc-card-${topicId}`);
            if (!card || !data.results.length) return;

            const r = data.results[0];
            // summary güncelle
            if (_lastResults) {
                const idx = _lastResults.results.findIndex(x => x.topicId === topicId);
                if (idx !== -1) _lastResults.results[idx] = r;
            }

            // Kartı güncelle
            const isClean = r.errorCount === 0 && r.warnCount === 0;
            const hasError = r.errorCount > 0;
            const borderColor = isClean ? 'var(--success)' : (hasError ? 'var(--danger)' : 'var(--warning)');
            card.style.borderColor = borderColor;
            card.style.transition = 'border-color 0.4s';

            // Sonuçları yenile
            const tmp = document.createElement('div');
            tmp.innerHTML = renderSingleCard(r, _currentSource);
            card.replaceWith(tmp.firstElementChild);

            // Summary yenile
            if (_lastResults) {
                const s = {
                    totalTopics: _lastResults.results.length,
                    totalQuestions: _lastResults.results.reduce((s, r) => s + (r.questionCount || 0), 0),
                    cleanTopics: _lastResults.results.filter(r => r.errorCount === 0 && r.warnCount === 0).length,
                    totalErrors: _lastResults.results.reduce((s, r) => s + (r.errorCount || 0), 0),
                    totalWarns: _lastResults.results.reduce((s, r) => s + (r.warnCount || 0), 0),
                };
                renderSummary(s, _currentSource);
            }
        } catch (_) { }
    }

    function renderSingleCard(r, source) {
        const isClean = !r.parseError && !r.fetchError && r.errorCount === 0 && r.warnCount === 0;
        const hasError = r.parseError || r.fetchError || r.errorCount > 0;
        const borderColor = isClean ? 'var(--success)' : (hasError ? 'var(--danger)' : 'var(--warning)');
        const icon = isClean ? '✅' : (hasError ? '❌' : '⚠️');
        const expandId = `qc-issues-${r.topicId}`;

        const issuesHtml = r.issues && r.issues.length > 0
            ? `<div id="${expandId}" style="display:none;margin-top:0.75rem;border-top:1px solid var(--border);padding-top:0.75rem;max-height:300px;overflow-y:auto;">
                ${r.issues.map(i => `
                    <div style="display:flex;gap:0.5rem;align-items:flex-start;padding:3px 0;font-size:12px;color:var(--text-secondary);">
                        ${severityBadge(i.severity)}
                        <span style="color:var(--text-muted);min-width:36px;flex-shrink:0">[${i.idx}]</span>
                        <span style="word-break:break-word">${escapeHtml(i.msg)}</span>
                    </div>`).join('')}
               </div>`
            : '';

        const detailBtn = r.issues && r.issues.length > 0
            ? `<button onclick="qualityCheck.toggleIssues('${expandId}', this)"
                    style="background:transparent;border:1px solid var(--border);color:var(--text-muted);
                           padding:4px 10px;border-radius:6px;cursor:pointer;font-size:12px;
                           display:flex;align-items:center;gap:4px">
                    <span class="material-icons-round" style="font-size:14px">expand_more</span>Detay
                </button>`
            : '';

        return `<div id="qc-card-${r.topicId}" style="background:var(--bg-card);border:1px solid ${borderColor};border-radius:12px;padding:0.875rem 1rem;">
            <div style="display:flex;align-items:center;gap:0.75rem;flex-wrap:wrap;">
                <span style="font-size:15px">${icon}</span>
                <span style="font-family:monospace;font-size:13px;color:var(--text-primary);font-weight:600">${r.topicId}</span>
                <span style="color:var(--text-muted);font-size:12px">${r.questionCount || 0} soru</span>
                ${r.errorCount > 0 ? `<span style="color:var(--danger);font-size:12px;font-weight:600">${r.errorCount} hata</span>` : ''}
                ${r.warnCount > 0 ? `<span style="color:var(--warning);font-size:12px;font-weight:600">${r.warnCount} uyarı</span>` : ''}
                <div style="margin-left:auto;display:flex;gap:0.5rem;align-items:center;flex-wrap:wrap;">
                    ${actionButtons(r, source)}
                    ${detailBtn}
                </div>
            </div>
            ${issuesHtml}
        </div>`;
    }

    // ── progress bar ──────────────────────────────────────────────────────────

    function showProgress(label) {
        const p = document.getElementById('qc-progress');
        if (p) p.style.display = 'block';
        setProgressLabel(label);
        setProgress(0, 1);
    }

    function hideProgress() {
        const p = document.getElementById('qc-progress');
        if (p) p.style.display = 'none';
    }

    function setProgress(done, total) {
        const pct = total > 0 ? Math.round((done / total) * 100) : 0;
        const bar = document.getElementById('qc-progress-bar');
        const pctEl = document.getElementById('qc-progress-pct');
        if (bar) bar.style.width = pct + '%';
        if (pctEl) pctEl.textContent = pct + '%';
    }

    function setProgressLabel(label) {
        const el = document.getElementById('qc-progress-label');
        if (el) el.textContent = label;
    }

    // ── SSE bulk helper ───────────────────────────────────────────────────────

    function bulkSSE(url, body, { label, onEvent, onFinish, onError }) {
        showProgress(label);

        fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ...body, bulk: true }),
        }).then(res => {
            const reader = res.body.getReader();
            const decoder = new TextDecoder();
            let buf = '';

            function read() {
                reader.read().then(({ done, value }) => {
                    if (done) { hideProgress(); return; }
                    buf += decoder.decode(value, { stream: true });
                    const lines = buf.split('\n');
                    buf = lines.pop();
                    for (const line of lines) {
                        if (!line.startsWith('data: ')) continue;
                        try {
                            const evt = JSON.parse(line.slice(6));
                            if (evt.finished) {
                                setProgress(evt.total || 1, evt.total || 1);
                                hideProgress();
                                if (onFinish) onFinish(evt);
                            } else {
                                setProgress(evt.done, evt.total);
                                setProgressLabel(`${label} — ${evt.topicId} (${evt.done}/${evt.total})`);
                                if (onEvent) onEvent(evt);
                            }
                        } catch (_) { }
                    }
                    read();
                });
            }
            read();
        }).catch(e => {
            hideProgress();
            if (onError) onError(e);
        });
    }

    // ── global fix (tüm prefix'ler) ───────────────────────────────────────────

    function fixAll() {
        const topicIds = _lastResults?.results?.filter(r => r.warnCount > 0).map(r => r.topicId) || [];
        if (!topicIds.length) { toast('Temizlenecek prefix bulunamadı', 'warn'); return; }
        if (!confirm(`${topicIds.length} topic'teki şık prefix'leri (A) B) C)...) temizlenecek. Devam?`)) return;

        const btn = document.getElementById('qc-fix-btn');
        btn.disabled = true;

        bulkSSE('/api/quality-check/fix', { topicIds }, {
            label: 'Prefix temizleniyor',
            onFinish(evt) {
                toast(`✅ ${evt.totalFixed} şık prefix'i temizlendi`);
                btn.disabled = false;
                run('local');
            },
            onError(e) {
                toast('Hata: ' + e.message, 'error');
                btn.disabled = false;
            },
        });
    }

    // ── global remove broken (tüm encoding hataları) ──────────────────────────

    function removeAllBroken() {
        const topicIds = _lastResults?.results?.filter(r => r.errorCount > 0).map(r => r.topicId) || [];
        if (!topicIds.length) { toast('Silinecek encoding hatası bulunamadı', 'warn'); return; }

        const totalErrors = _lastResults?.results?.reduce((s, r) => s + (r.errorCount || 0), 0) || 0;
        if (!confirm(`${topicIds.length} topic'teki ${totalErrors} encoding hatalı soru silinecek.\n\nBu işlem GERİ ALINAMAZ. Devam?`)) return;

        const btn = document.getElementById('qc-remove-btn');
        btn.disabled = true;

        bulkSSE('/api/quality-check/remove-broken', { topicIds }, {
            label: 'Bozuk sorular siliniyor',
            onFinish(evt) {
                toast(`🗑️ ${evt.totalRemoved} bozuk soru silindi`, 'warn');
                btn.disabled = false;
                run('local');
            },
            onError(e) {
                toast('Hata: ' + e.message, 'error');
                btn.disabled = false;
            },
        });
    }



    // ── eski fix (geriye uyumluluk) ───────────────────────────────────────────
    function fix() { fixAll(); }

    // ── misc ──────────────────────────────────────────────────────────────────

    function filterTopic() { run(_currentSource); }

    function toggleIssues(id, btn) {
        const el = document.getElementById(id);
        if (!el) return;
        const open = el.style.display !== 'none';
        el.style.display = open ? 'none' : 'block';
        if (btn) {
            const icon = btn.querySelector('.material-icons-round');
            if (icon) icon.textContent = open ? 'expand_more' : 'expand_less';
        }
    }

    return {
        run, fix, fixAll, removeAllBroken,
        filterTopic, toggleIssues,
        fixTopicPrefixes, removeBrokenQuestions,
        get _hasRun() { return _hasRun; },
        set _hasRun(v) { _hasRun = v; },
    };
})();

// ═════════════════════════════════════════════════════════════════════════
// AI ANALİZ PANELİ
// ═════════════════════════════════════════════════════════════════════════
window.aiAnalysis = (() => {
    const API = () => window.CONFIG?.API_URL || 'http://localhost:8002';

    let _topicId = null;
    let _topicName = null;
    let _topicLesson = null;
    let _questions = [];
    let _filteredQuestions = [];
    let _currentQuestion = null;
    let _currentResult = null;
    let _initialized = false;

    async function init() {
        if (_initialized) return;
        _initialized = true;
        await loadTopics();
    }

    async function loadTopics() {
        const sel = document.getElementById('aa-topic-select');
        if (!sel) return;
        sel.innerHTML = '<option value="">-- Konu seçin --</option>';
        try {
            const res = await fetch(`${API()}/topics`);
            const topics = await res.json();
            topics.sort((a, b) => (a.lesson || '').localeCompare(b.lesson || '') || (a.name || '').localeCompare(b.name || ''));
            let currentLesson = '';
            topics.forEach(t => {
                if (t.lesson !== currentLesson) {
                    const og = document.createElement('optgroup');
                    og.label = t.lesson || 'Diğer';
                    sel.appendChild(og);
                    currentLesson = t.lesson;
                }
                const opt = document.createElement('option');
                opt.value = t.id;
                opt.textContent = `${t.name} (${t.count})`;
                opt.dataset.lesson = t.lesson || '';
                opt.dataset.name = t.name || '';
                sel.appendChild(opt);
            });
        } catch (e) {
            console.error('aiAnalysis.loadTopics hatası:', e);
        }
    }

    async function onTopicChange() {
        const sel = document.getElementById('aa-topic-select');
        _topicId = sel.value;
        const selectedOpt = sel.options[sel.selectedIndex];
        _topicName = selectedOpt?.dataset?.name || _topicId;
        _topicLesson = selectedOpt?.dataset?.lesson || '';
        _questions = [];
        _filteredQuestions = [];
        _currentQuestion = null;
        _currentResult = null;
        resetContent();
        if (!_topicId) { updateQuestionSelect([]); document.getElementById('aa-bulk-btn').disabled = true; return; }
        try {
            const res = await fetch(`${API()}/questions/${encodeURIComponent(_topicId)}`);
            const data = await res.json();
            _questions = Array.isArray(data) ? data : (data.questions || []);
        } catch (e) {
            _questions = [];
        }
        document.getElementById('aa-bulk-btn').disabled = _questions.length === 0;
        applyFilter();
    }

    function onFilterChange() {
        applyFilter();
    }

    function applyFilter() {
        const filter = document.getElementById('aa-filter-select')?.value || 'unanalyzed';
        const search = (document.getElementById('aa-search-input')?.value || '').toLowerCase().trim();
        let filtered = _questions;
        if (filter === 'unanalyzed') filtered = filtered.filter(q => !q._analyzed);
        else if (filter === 'analyzed') filtered = filtered.filter(q => !!q._analyzed);
        if (search) filtered = filtered.filter(q => (q.q || '').toLowerCase().includes(search) || (q.id || '').toLowerCase().includes(search));
        _filteredQuestions = filtered;
        // show aa-main if topic is selected
        const mainEl = document.getElementById('aa-main');
        const emptyEl = document.getElementById('aa-empty');
        if (_topicId) {
            if (mainEl) mainEl.style.display = 'grid';
            if (emptyEl) emptyEl.style.display = 'none';
        } else {
            if (mainEl) mainEl.style.display = 'none';
            if (emptyEl) emptyEl.style.display = 'block';
        }
        renderQuestionList(_filteredQuestions);
    }

    let _expandedIdx = null; // hangi kart açık

    function renderQuestionList(questions) {
        const listEl = document.getElementById('aa-question-list');
        const statsEl = document.getElementById('aa-q-stats');
        if (!listEl) return;
        const analyzedCount = _questions.filter(q => q._analyzed).length;
        if (statsEl) statsEl.textContent = _questions.length > 0 ? `${analyzedCount}/${_questions.length} analiz edildi` : 'Sorular';

        if (!questions.length) {
            const filter = document.getElementById('aa-filter-select')?.value || 'unanalyzed';
            listEl.innerHTML = `<div style="padding:1.5rem;text-align:center;color:var(--text-muted);font-size:0.82rem">
                ${filter === 'unanalyzed' && _questions.length > 0 ? '✅ Tüm sorular analiz edildi' : 'Soru bulunamadı'}
            </div>`;
            document.getElementById('aa-analyze-btn').disabled = true;
            return;
        }

        listEl.innerHTML = questions.map((q, listIdx) => {
            const realIdx = _questions.indexOf(q);
            const isSelected = _currentQuestion === q;
            const isExpanded = _expandedIdx === realIdx;
            const answerLabel = ['A','B','C','D','E'][q.a ?? 0];
            const analyzedBadge = q._analyzed
                ? `<span style="background:rgba(16,185,129,.15);border:1px solid rgba(16,185,129,.4);color:#34d399;font-size:0.65rem;padding:1px 6px;border-radius:8px;flex-shrink:0">✓</span>`
                : '';
            const selectedStyle = isSelected
                ? 'border-left:3px solid var(--primary);background:rgba(99,102,241,0.08);'
                : 'border-left:3px solid transparent;';

            const optionsHtml = isExpanded && Array.isArray(q.o) ? `
                <div style="margin-top:0.5rem;display:flex;flex-direction:column;gap:0.2rem">
                    ${q.o.map((o, i) => `
                        <div style="font-size:0.75rem;padding:0.25rem 0.4rem;border-radius:4px;${i === q.a ? 'background:rgba(16,185,129,.15);color:#34d399;font-weight:600;' : 'color:var(--text-muted);'}">
                            ${['A','B','C','D','E'][i]}) ${o}
                        </div>`).join('')}
                    ${q.e ? `<div style="margin-top:0.3rem;font-size:0.72rem;color:var(--text-muted);border-top:1px solid var(--border);padding-top:0.3rem">💡 ${q.e}</div>` : ''}
                </div>` : '';

            return `<div style="border-bottom:1px solid var(--border);${selectedStyle}transition:background .15s">
                <div style="display:flex;align-items:flex-start;gap:0;padding:0.55rem 0.5rem 0.55rem 0.65rem;cursor:pointer"
                    onclick="aiAnalysis.selectQuestion(${realIdx})">
                    <span class="material-icons-round" style="font-size:0.9rem;color:var(--text-muted);margin-top:2px;flex-shrink:0;margin-right:4px;transition:transform .2s;${isExpanded ? 'transform:rotate(90deg)' : ''}">chevron_right</span>
                    <div style="flex:1;min-width:0">
                        <div style="display:flex;align-items:center;gap:4px;margin-bottom:2px">
                            ${analyzedBadge}
                            <span style="font-size:0.65rem;color:var(--text-muted)">${q.id || realIdx}</span>
                        </div>
                        <div style="font-size:0.78rem;color:var(--text-primary);line-height:1.4;${isExpanded ? '' : 'overflow:hidden;white-space:nowrap;text-overflow:ellipsis;max-width:200px'}">
                            ${(q.q || '').substring(0, isExpanded ? 9999 : 80).replace(/</g,'&lt;')}
                        </div>
                        ${optionsHtml}
                    </div>
                    <div style="display:flex;gap:3px;flex-shrink:0;margin-left:4px" onclick="event.stopPropagation()">
                        <button title="Sil" onclick="aiAnalysis.deleteQuestion(${realIdx})"
                            style="background:rgba(239,68,68,.15);border:1px solid rgba(239,68,68,.3);color:#f87171;border-radius:5px;padding:3px 5px;cursor:pointer;display:flex;align-items:center">
                            <span class="material-icons-round" style="font-size:0.85rem">delete</span>
                        </button>
                    </div>
                </div>
            </div>`;
        }).join('');
    }

    function onSearchInput() {
        applyFilter();
    }

    function onQuestionChange() { /* no-op, replaced by selectQuestion */ }

    function selectQuestion(realIdx) {
        const q = _questions[realIdx];
        if (!q) return;
        // toggle expand
        if (_expandedIdx === realIdx) {
            _expandedIdx = null;
        } else {
            _expandedIdx = realIdx;
        }
        _currentQuestion = q;
        document.getElementById('aa-analyze-btn').disabled = false;
        fillEditor(q);
        renderQuestionList(_filteredQuestions); // re-render to update expansion/selection
        // Kayıtlı analiz sonucu varsa göster, yoksa temizle
        if (q._analysisResult) {
            renderResults(q._analysisResult);
        } else {
            resetContent();
        }
    }

    async function deleteQuestion(realIdx) {
        const q = _questions[realIdx];
        if (!q || !_topicId) return;
        if (!confirm(`Bu soru silinecek:\n\n"${(q.q || '').substring(0, 80)}..."\n\nEmin misiniz?`)) return;
        try {
            const res = await fetch(`${API()}/questions/${encodeURIComponent(_topicId)}/${encodeURIComponent(q.id)}`, {
                method: 'DELETE'
            });
            const data = await res.json();
            if (!data.success) throw new Error(data.error || 'Silme başarısız');
            _questions.splice(realIdx, 1);
            if (_currentQuestion === q) {
                _currentQuestion = null;
                document.getElementById('aa-analyze-btn').disabled = true;
                resetContent();
            }
            if (_expandedIdx === realIdx) _expandedIdx = null;
            applyFilter();
            document.getElementById('aa-bulk-btn').disabled = _questions.length === 0;
            if (typeof toast === 'function') toast('✅ Soru silindi');
        } catch (e) {
            if (typeof toast === 'function') toast('❌ ' + e.message, 'error');
        }
    }

    function fillEditor(q) {
        if (!q) return;
        const el = id => document.getElementById(id);
        if (el('aa-edit-q')) el('aa-edit-q').value = q.q || '';
        for (let i = 0; i < 5; i++) {
            if (el(`aa-edit-o${i}`)) el(`aa-edit-o${i}`).value = (q.o && q.o[i]) ? q.o[i] : '';
        }
        if (el('aa-edit-a')) el('aa-edit-a').value = String(q.a ?? 0);
        if (el('aa-edit-d')) el('aa-edit-d').value = String(q.d ?? 3);
        if (el('aa-edit-e')) el('aa-edit-e').value = q.e || '';
    }

    function resetContent() {
        // sadece orta kolon sıfırla; aa-main görünür kalır
        const verdictBanner = document.getElementById('aa-verdict-banner');
        const criteriaList  = document.getElementById('aa-criteria-list');
        const loadingEl     = document.getElementById('aa-loading');
        if (verdictBanner) verdictBanner.style.display = 'none';
        if (criteriaList)  criteriaList.innerHTML = '';
        if (loadingEl)     loadingEl.style.display = 'none';
    }

    async function analyze() {
        if (!_currentQuestion) return;
        const btn = document.getElementById('aa-analyze-btn');
        btn.disabled = true;
        btn.innerHTML = '<span class="material-icons-round" style="font-size:18px;animation:spin 1s linear infinite">sync</span> Analiz Ediliyor...';
        document.getElementById('aa-loading').style.display = 'block';
        const verdictBanner = document.getElementById('aa-verdict-banner');
        const criteriaList  = document.getElementById('aa-criteria-list');
        if (verdictBanner) verdictBanner.style.display = 'none';
        if (criteriaList)  criteriaList.innerHTML = '';
        const model = document.getElementById('aa-model-select')?.value || 'google/gemini-3.1-flash-lite-preview';
        try {
            const res = await fetch(`${API()}/api/ai/deep-analyze`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    question: _currentQuestion,
                    topicInfo: { name: _topicName, lesson: _topicLesson },
                    model
                })
            });
            const data = await res.json();
            if (!data.success) throw new Error(data.error || 'Analiz başarısız');
            _currentResult = data;
            renderResults(data);
        } catch (e) {
            document.getElementById('aa-loading').style.display = 'none';
            const criteriaList = document.getElementById('aa-criteria-list');
            if (criteriaList) criteriaList.innerHTML = `<div style="padding:1rem;color:var(--danger);text-align:center">
                <span class="material-icons-round" style="display:block;font-size:2rem;margin-bottom:0.5rem">error</span>${e.message}</div>`;
        } finally {
            btn.disabled = false;
            btn.innerHTML = '<span class="material-icons-round" style="font-size:18px">psychology</span> Analiz Et';
        }
    }

    function renderResults(data) {
        document.getElementById('aa-loading').style.display = 'none';
        const verdictStyles = {
            'Geçerli':                   { bg: 'rgba(16,185,129,0.15)',  border: 'rgba(16,185,129,0.4)',  color: '#34d399', icon: 'check_circle' },
            'Küçük düzeltme gerekli':   { bg: 'rgba(245,158,11,0.15)',  border: 'rgba(245,158,11,0.4)',  color: '#fbbf24', icon: 'warning' },
            'Revizyon gerekli':            { bg: 'rgba(249,115,22,0.15)',  border: 'rgba(249,115,22,0.4)',  color: '#fb923c', icon: 'edit_note' },
            'Hatalı':                    { bg: 'rgba(239,68,68,0.15)',   border: 'rgba(239,68,68,0.4)',   color: '#f87171', icon: 'cancel' },
        };
        const vs = verdictStyles[data.verdict] || verdictStyles['Geçerli'];
        const banner = document.getElementById('aa-verdict-banner');
        banner.style.background = vs.bg;
        banner.style.border = `1px solid ${vs.border}`;
        banner.style.color = vs.color;
        document.getElementById('aa-verdict-icon').textContent = vs.icon;
        document.getElementById('aa-verdict-text').textContent = data.verdict;
        document.getElementById('aa-verdict-summary').textContent = data.summary || '';
        document.getElementById('aa-score').textContent = data.score || '-';
        const list = document.getElementById('aa-criteria-list');
        list.innerHTML = (data.criteria || []).map(c => {
            const borderColor = c.hasError ? 'rgba(239,68,68,0.4)' : 'rgba(16,185,129,0.3)';
            const iconColor   = c.hasError ? '#f87171' : '#34d399';
            const icon        = c.hasError ? 'cancel' : 'check_circle';
            const bgColor     = c.hasError ? 'rgba(239,68,68,0.05)' : 'rgba(16,185,129,0.05)';
            return `<div style="background:${bgColor};border:1px solid ${borderColor};border-radius:8px;padding:0.7rem 0.9rem">
                <div style="display:flex;align-items:flex-start;gap:0.6rem">
                    <span class="material-icons-round" style="font-size:1.1rem;color:${iconColor};flex-shrink:0;margin-top:1px">${icon}</span>
                    <div style="flex:1;min-width:0">
                        <div style="font-size:0.78rem;font-weight:600;color:var(--text-primary);margin-bottom:0.2rem">
                            <span style="color:var(--text-muted);font-size:0.7rem">${c.id}.</span> ${c.name}
                        </div>
                        <div style="font-size:0.78rem;color:var(--text-secondary);line-height:1.45">${c.explanation || ''}</div>
                        ${c.suggestion ? `<div style="margin-top:0.35rem;padding:0.3rem 0.5rem;background:rgba(99,102,241,0.1);border-left:2px solid #6366f1;border-radius:0 4px 4px 0;font-size:0.75rem;color:#a5b4fc">💡 ${c.suggestion}</div>` : ''}
                    </div>
                </div>
            </div>`;
        }).join('');
        const contentEl = document.getElementById('aa-content');
        if (contentEl) contentEl.style.display = 'block';
        banner.style.display = 'flex';
    }

    async function save() {
        if (!_currentQuestion || !_topicId) return;
        const btn = document.getElementById('aa-save-btn');
        btn.disabled = true;
        btn.innerHTML = '<span class="material-icons-round" style="font-size:16px;animation:spin 1s linear infinite">sync</span> Kaydediliyor...';
        const updatedQ = {
            ..._currentQuestion,
            q: document.getElementById('aa-edit-q')?.value || _currentQuestion.q,
            o: [0,1,2,3,4].map(i => document.getElementById(`aa-edit-o${i}`)?.value || (_currentQuestion.o?.[i] || '')),
            a: parseInt(document.getElementById('aa-edit-a')?.value ?? _currentQuestion.a ?? 0),
            d: parseInt(document.getElementById('aa-edit-d')?.value ?? _currentQuestion.d ?? 3),
            e: document.getElementById('aa-edit-e')?.value || _currentQuestion.e || '',
            _analyzed: true,
            _analyzedAt: new Date().toISOString(),
            _analysisResult: _currentResult || undefined,
        };
        try {
            const qId = encodeURIComponent(_currentQuestion.id);
            const res = await fetch(`${API()}/questions/${encodeURIComponent(_topicId)}/${qId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(updatedQ)
            });
            const data = await res.json();
            if (!data.success) throw new Error(data.error || 'Kayıt başarısız');
            const idx = _questions.indexOf(_currentQuestion);
            if (idx !== -1) { _questions[idx] = updatedQ; _currentQuestion = updatedQ; }
            applyFilter();
            if (typeof toast === 'function') toast('✅ Soru kaydedildi ve analiz edildi olarak işaretlendi');
        } catch (e) {
            if (typeof toast === 'function') toast('❌ ' + e.message, 'error');
        } finally {
            btn.disabled = false;
            btn.innerHTML = '<span class="material-icons-round" style="font-size:16px">save</span> Kaydet &amp; İşaretle';
        }
    }

    function nextQuestion() {
        if (!_currentQuestion || !_filteredQuestions.length) return;
        const curIdx = _filteredQuestions.indexOf(_currentQuestion);
        const next = _filteredQuestions[curIdx + 1];
        if (next) {
            const realIdx = _questions.indexOf(next);
            selectQuestion(realIdx);
        } else {
            if (typeof toast === 'function') toast('Son sorudayınız', 'warn');
        }
    }

    // ─── Toplu Analiz ───────────────────────────────────────────
    let _bulkRunning = false;
    let _bulkStop = false;

    async function bulkAnalyze() {
        if (!_topicId || !_questions.length) return;
        if (_bulkRunning) return;

        // Analiz edilmemiş soruları bul
        const toAnalyze = _questions.filter(q => !q._analyzed);
        if (!toAnalyze.length) {
            if (typeof toast === 'function') toast('Bu konudaki tüm sorular zaten analiz edilmiş', 'warn');
            return;
        }

        const ok = confirm(`${toAnalyze.length} soru sırayla analiz edilip kaydedilecek. Devam edilsin mi?`);
        if (!ok) return;

        _bulkRunning = true;
        _bulkStop = false;
        const model = document.getElementById('aa-model-select')?.value || 'google/gemini-3.1-flash-lite-preview';
        const total = toAnalyze.length;
        let done = 0;
        let errCount = 0;

        // UI güncellemeleri
        document.getElementById('aa-bulk-progress').style.display = 'block';
        document.getElementById('aa-bulk-btn').disabled = true;
        document.getElementById('aa-stop-btn').style.display = '';
        document.getElementById('aa-analyze-btn').disabled = true;
        // orta kolonu temizle
        const verdictBanner = document.getElementById('aa-verdict-banner');
        const criteriaList  = document.getElementById('aa-criteria-list');
        if (verdictBanner) verdictBanner.style.display = 'none';
        if (criteriaList)  criteriaList.innerHTML = '';
        document.getElementById('aa-loading').style.display = 'none';

        const updateProgress = () => {
            const pct = Math.round((done / total) * 100);
            document.getElementById('aa-bulk-bar').style.width = pct + '%';
            document.getElementById('aa-bulk-pct').textContent = pct + '%';
            document.getElementById('aa-bulk-ok').textContent = done - errCount;
            document.getElementById('aa-bulk-err').textContent = errCount;
            document.getElementById('aa-bulk-remain').textContent = total - done;
            document.getElementById('aa-bulk-label').textContent = `Analiz ediliyor: ${done}/${total}`;
        };

        updateProgress();

        for (const q of toAnalyze) {
            if (_bulkStop) break;

            document.getElementById('aa-bulk-label').textContent = `İşleniyor: ${(q.q || '').substring(0, 60)}...`;

            try {
                const res = await fetch(`${API()}/api/ai/deep-analyze`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        question: q,
                        topicInfo: { name: _topicName, lesson: _topicLesson },
                        model
                    })
                });
                const data = await res.json();
                if (!data.success) throw new Error(data.error || 'Analiz başarısız');

                // Soruyu kaydet
                const updatedQ = { ...q, _analyzed: true, _analyzedAt: new Date().toISOString(), _analysisResult: { criteria: data.criteria, verdict: data.verdict, score: data.score, summary: data.summary } };
                const qId = encodeURIComponent(q.id);
                const saveRes = await fetch(`${API()}/questions/${encodeURIComponent(_topicId)}/${qId}`, {
                    method: 'PUT',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(updatedQ)
                });
                const saveData = await saveRes.json();
                if (!saveData.success) throw new Error(saveData.error || 'Kayıt başarısız');

                const idx = _questions.indexOf(q);
                if (idx !== -1) _questions[idx] = updatedQ;

                done++;
            } catch (e) {
                errCount++;
                done++;
                console.error('Bulk analiz hatası (soru:', q.id, '):', e);
            }

            updateProgress();

            // API rate limit için kısa bekleme
            if (!_bulkStop) await new Promise(r => setTimeout(r, 300));
        }

        // Bitince
        _bulkRunning = false;
        // Analiz edilmişleri göster
        const filterSel = document.getElementById('aa-filter-select');
        if (filterSel) filterSel.value = 'analyzed';
        applyFilter();
        document.getElementById('aa-stop-btn').style.display = 'none';
        document.getElementById('aa-bulk-btn').disabled = false;
        document.getElementById('aa-bulk-label').textContent = _bulkStop
            ? `⏹ Durduruldu: ${done} / ${total} tamamlandı`
            : `✅ Tamamlandı: ${done - errCount} başarılı, ${errCount} hatalı`;
        if (typeof toast === 'function') {
            toast(_bulkStop
                ? `⏹ Analiz durduruldu: ${done}/${total} soru işlendi`
                : `✅ Toplu analiz tamamlandı: ${done - errCount}/${total} başarılı`, _bulkStop ? 'warn' : 'success');
        }
        _bulkStop = false;
    }

    function stopBulk() {
        _bulkStop = true;
        document.getElementById('aa-stop-btn').disabled = true;
        document.getElementById('aa-stop-btn').innerHTML = '<span class="material-icons-round" style="font-size:18px">hourglass_empty</span> Durduruluyor...';
    }

    return { init, loadTopics, onTopicChange, onFilterChange, onQuestionChange, onSearchInput, selectQuestion, deleteQuestion, analyze, save, nextQuestion, fillEditor, bulkAnalyze, stopBulk };
})();
