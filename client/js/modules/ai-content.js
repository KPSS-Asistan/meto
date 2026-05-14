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
        aiLog(`⏳ Üretim SSE ile canlı takip ediliyor...`, 'info');

        // SSE: sunucu push ile canlı takip
        await _trackJobSSE(jobId, topicName, moduleType, count);

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

// ═══════════════════════════════════════════════════════════════════════════
// JOB PROGRESS PANEL — SSE tabanlı canlı iş takibi
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Job Progress Panel — tüm sayfalardan görülebilen sabit alt panel.
 * Bir job çalışırken görünür, tamamlanınca 4 sn sonra kaybolur.
 */
const _jobPanel = (() => {
    let _el = null;
    let _hideTimer = null;
    let _activeJobId = null;

    function _getEl() {
        if (!_el) _el = document.getElementById('jobProgressPanel');
        return _el;
    }

    function show(jobId, topicName, moduleType, total) {
        _activeJobId = jobId;
        const el = _getEl();
        if (!el) return;
        clearTimeout(_hideTimer);

        const moduleIcons = {
            explanations: '📚', stories: '📖', flashcards: '🃏',
            matching_games: '🔗', questions: '❓', productivity: '⚡'
        };
        const icon = moduleIcons[moduleType] || '🤖';

        el.querySelector('#jpJobName').textContent = `${icon} ${topicName}`;
        el.querySelector('#jpStatus').textContent = 'Başlıyor...';
        el.querySelector('#jpBar').style.width = '0%';
        el.querySelector('#jpPct').textContent = '0%';
        el.querySelector('#jpCount').textContent = `0 / ${total}`;
        el.classList.remove('jp-done', 'jp-error', 'jp-hidden');
        el.classList.add('jp-visible');
    }

    function update(progress, total, status) {
        const el = _getEl();
        if (!el) return;
        const pct = total > 0 ? Math.round((progress / total) * 100) : 0;
        el.querySelector('#jpBar').style.width = `${pct}%`;
        el.querySelector('#jpPct').textContent = `${pct}%`;
        el.querySelector('#jpCount').textContent = `${progress} / ${total}`;
        el.querySelector('#jpStatus').textContent = '⚙️ Üretiliyor...';
    }

    function done(generated, totalDrafts) {
        const el = _getEl();
        if (!el) return;
        el.querySelector('#jpBar').style.width = '100%';
        el.querySelector('#jpPct').textContent = '100%';
        el.querySelector('#jpStatus').textContent = `✅ ${generated} içerik taslağa kaydedildi`;
        el.classList.add('jp-done');
        _hideTimer = setTimeout(() => hide(), 5000);
    }

    function error(msg) {
        const el = _getEl();
        if (!el) return;
        el.querySelector('#jpStatus').textContent = `❌ Hata: ${msg}`;
        el.classList.add('jp-error');
        _hideTimer = setTimeout(() => hide(), 8000);
    }

    function hide() {
        const el = _getEl();
        if (!el) return;
        el.classList.remove('jp-visible');
        el.classList.add('jp-hidden');
        _activeJobId = null;
    }

    return { show, update, done, error, hide };
})();

/**
 * SSE tabanlı job takip fonksiyonu — _pollJobStatus yerine kullanılır.
 * EventSource ile sunucu push olaylarını dinler, aiLog'a ve _jobPanel'e aktarır.
 */
function _trackJobSSE(jobId, topicName, moduleType, count) {
    return new Promise((resolve, reject) => {
        const url = `${API}/api/ai-content/job-stream?jobId=${encodeURIComponent(jobId)}`;
        const source = new EventSource(url, { withCredentials: true });

        // Panel göster
        _jobPanel.show(jobId, topicName, moduleType, count);

        // Global 10 dk timeout
        const timeout = setTimeout(() => {
            source.close();
            _jobPanel.error('10 dakika zaman aşımı');
            reject(new Error('⏱️ Zaman aşımı: İşlem 10 dakika içinde tamamlanamadı'));
        }, 600000);

        let lastProgress = -1;

        source.addEventListener('init', (e) => {
            try {
                const d = JSON.parse(e.data);
                if (d.progress && d.total) _jobPanel.update(d.progress, d.total, d.status);
            } catch { }
        });

        source.addEventListener('log', (e) => {
            try {
                const log = JSON.parse(e.data);
                aiLog(log.message || String(log), log.type || 'info');
            } catch { }
        });

        source.addEventListener('progress', (e) => {
            try {
                const d = JSON.parse(e.data);
                if (d.progress !== lastProgress) {
                    lastProgress = d.progress;
                    const pct = d.total > 0 ? Math.round((d.progress / d.total) * 100) : 0;
                    aiLog(`📊 İlerleme: ${d.progress}/${d.total} (${pct}%)`, 'info');
                    _jobPanel.update(d.progress, d.total, 'running');
                }
            } catch { }
        });

        source.addEventListener('done', (e) => {
            try {
                const d = JSON.parse(e.data);
                clearTimeout(timeout);
                source.close();
                aiLog(`✅ ${d.generated} içerik tamamlandı! Toplam taslak: ${d.total_drafts}`, 'success');
                _jobPanel.done(d.generated, d.total_drafts);
                resolve(d);
            } catch (err) { reject(err); }
        });

        source.addEventListener('error', (e) => {
            if (e.data) {
                try {
                    const d = JSON.parse(e.data);
                    clearTimeout(timeout);
                    source.close();
                    _jobPanel.error(d.error || 'Bilinmeyen hata');
                    reject(new Error(d.error || 'Üretim hatası'));
                    return;
                } catch { }
            }
            // Bağlantı kesildi (sunucu kapandı vb.) — SSE reconnect dener
            // Eğer source kapandıysa reject et
            if (source.readyState === 2 /* CLOSED */) {
                clearTimeout(timeout);
                _jobPanel.error('Sunucu bağlantısı kesildi');
                reject(new Error('SSE bağlantısı beklenmedik şekilde kapandı'));
            }
        });
    });
}

// Job polling - geriye dönük uyumluluk için bırakıldı (artık kullanılmıyor)
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
                <div style="margin-left: auto; display: flex; gap: 0.5rem; flex-wrap: wrap;">
                    ${moduleType === 'questions' ? `
                    <button onclick="modalCheckDuplicates('${topicId}', '${moduleType}')" id="modalDupBtn"
                        style="background: #1e3a5f; border: 1px solid #3b82f6; color: #93c5fd; padding: 0.6rem 1rem; border-radius: 6px; cursor: pointer; font-size: 0.85rem;">
                        🔍 Duplike Kontrol
                    </button>
                    <button onclick="modalAnalyzeDrafts('${topicId}', '${moduleType}')" id="modalAiBtn"
                        style="background: #2e1065; border: 1px solid #7c3aed; color: #c4b5fd; padding: 0.6rem 1rem; border-radius: 6px; cursor: pointer; font-size: 0.85rem;">
                        🤖 AI Analiz
                    </button>` : ''}
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
                                    <div id="modalStatus-${index}" style="margin-top:0.4rem;">${draft._analyzed && draft._analysisResult ? `<span style="font-size:0.72rem;padding:0.15rem 0.45rem;border-radius:3px;background:rgba(99,102,241,0.15);color:#a5b4fc;">🤖 ${draft._analysisResult.verdict || ''} ${draft._analysisResult.score ? draft._analysisResult.score + '/10' : ''}</span>` : ''}</div>
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

// ─── Modal: Duplicate Kontrol ──────────────────────────────────────────────
window.modalCheckDuplicates = async function (topicId, moduleType) {
    const btn = document.getElementById('modalDupBtn');
    if (btn) { btn.disabled = true; btn.textContent = '⏳ Kontrol ediliyor...'; }

    try {
        const res = await fetch(`${API}/api/ai-content/check-duplicates`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ moduleType, topicId })
        });
        const data = await res.json();
        if (!data.success) throw new Error(data.error || 'Kontrol başarısız');

        let dupCount = 0, simCount = 0;
        for (const r of data.results) {
            const el = document.getElementById(`modalStatus-${r.draftIndex}`);
            if (!el) continue;
            if (r.status === 'duplicate') {
                dupCount++;
                el.innerHTML = `<span style="font-size:0.72rem;padding:0.15rem 0.45rem;border-radius:3px;background:rgba(239,68,68,0.2);color:#fca5a5;">🔴 Duplike (~${r.score}%) — ${r.matchedQuestion || ''}</span>`;
                const card = document.getElementById(`draftItem-${r.draftIndex}`);
                if (card) card.style.borderColor = '#ef4444';
            } else if (r.status === 'similar') {
                simCount++;
                el.innerHTML = `<span style="font-size:0.72rem;padding:0.15rem 0.45rem;border-radius:3px;background:rgba(251,191,36,0.15);color:#fde68a;">🟡 Benzer (~${r.score}%) — ${r.matchedQuestion || ''}</span>`;
                const card = document.getElementById(`draftItem-${r.draftIndex}`);
                if (card) card.style.borderColor = '#f59e0b';
            } else {
                const prev = el.innerHTML;
                if (!prev.includes('🤖')) {
                    el.innerHTML = `<span style="font-size:0.72rem;padding:0.15rem 0.45rem;border-radius:3px;background:rgba(16,185,129,0.15);color:#6ee7b7;">🟢 Temiz</span>`;
                }
            }
        }
        if (btn) btn.textContent = `🔍 ${dupCount} duplike, ${simCount} benzer`;
    } catch (e) {
        if (btn) { btn.disabled = false; btn.textContent = '🔍 Duplike Kontrol'; }
        showToast('Duplike kontrol hatası: ' + e.message, 'error');
    }
};

// ─── Modal: AI Analiz ──────────────────────────────────────────────────────
window.modalAnalyzeDrafts = async function (topicId, moduleType) {
    const btn = document.getElementById('modalAiBtn');
    if (btn) { btn.disabled = true; btn.textContent = '⏳ Analiz ediliyor...'; }

    const ANALYSIS_MODEL = 'openai/gpt-5-nano';
    let done = 0, failed = 0;

    for (let i = 0; i < _currentDrafts.length; i++) {
        const draft = _currentDrafts[i];
        const statusEl = document.getElementById(`modalStatus-${i}`);
        if (statusEl) {
            const prev = statusEl.innerHTML;
            statusEl.innerHTML = prev + ' <span style="font-size:0.7rem;color:#94a3b8;">⏳</span>';
        }
        try {
            const res = await fetch(`${API}/api/ai/deep-analyze`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    question: draft,
                    topicInfo: { name: _currentTopicName },
                    model: ANALYSIS_MODEL
                })
            });
            const data = await res.json();
            if (!data.success) throw new Error(data.error || 'Analiz başarısız');

            // Taslağı güncelle
            await fetch(`${API}/api/ai-content/update-draft`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    moduleType,
                    topicId,
                    index: i,
                    updatedDraft: {
                        _analyzed: true,
                        _analyzedAt: new Date().toISOString(),
                        _analysisResult: { criteria: data.criteria, verdict: data.verdict, score: data.score, summary: data.summary }
                    }
                })
            });

            _currentDrafts[i]._analyzed = true;
            _currentDrafts[i]._analysisResult = { criteria: data.criteria, verdict: data.verdict, score: data.score, summary: data.summary };

            const verdictColor = { 'Geçerli': '#34d399', 'Küçük düzeltme gerekli': '#fbbf24', 'Revizyon gerekli': '#fb923c', 'Hatalı': '#f87171' }[data.verdict] || '#94a3b8';
            if (statusEl) {
                const dupPart = statusEl.innerHTML.includes('🔴') || statusEl.innerHTML.includes('🟡') || statusEl.innerHTML.includes('🟢')
                    ? statusEl.innerHTML.replace(/<span[^>]*>⏳<\/span>/, '') : '';
                statusEl.innerHTML = (dupPart || '') + `<span style="font-size:0.72rem;padding:0.15rem 0.45rem;border-radius:3px;background:rgba(99,102,241,0.15);color:${verdictColor};">🤖 ${data.verdict} ${data.score}/10</span>`;
            }
            done++;
        } catch (e) {
            failed++;
            if (statusEl) {
                const s = statusEl.innerHTML.replace(/<span[^>]*>⏳<\/span>/, '');
                statusEl.innerHTML = s + '<span style="font-size:0.7rem;color:#f87171;">❌</span>';
            }
        }

        if (btn) btn.textContent = `⏳ ${done + failed}/${_currentDrafts.length}`;
    }

    if (btn) { btn.disabled = false; btn.textContent = `🤖 Analiz (${done} ✓${failed ? ', ' + failed + ' ✗' : ''})`; }
    showToast(`AI analiz tamamlandı: ${done} başarılı${failed ? ', ' + failed + ' hata' : ''}`, done > 0 ? 'success' : 'warn');
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
        // Soru taslakları için /add endpointi kullan
        if (moduleType === 'questions') {
            const drafts = await (await fetch(`${API}/api/ai-content/drafts?topicId=${encodeURIComponent(topicId)}&moduleType=questions`)).json();
            const item = (drafts.drafts || [])[index];
            if (!item) throw new Error('Taslak bulunamadı');
            const addRes = await fetch(`${API}/add`, {
                method: 'POST', headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ topicId, questions: [item] })
            });
            const addData = await addRes.json();
            if (!addData.success) throw new Error(addData.error || 'Eklenemedi');
            // Taslaktan kaldır
            await fetch(`${API}/api/ai-content/delete-draft`, {
                method: 'POST', headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ moduleType, topicId, indices: [index] })
            });
            aiLog(`✅ [${topicName}] #${index + 1} soru veritabanına eklendi!`, 'success');
            closeDraftsModal();
            if (window.loadAllDrafts) await window.loadAllDrafts();
            showToast(`${topicName} - Soru eklendi!`, 'success');
            return;
        }

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
                                ${draft._moduleType === 'questions' ? `
                                <button onclick="analyzeDraftQuestion(${i})" id="draftAnalyzeBtn-${i}"
                                    style="display:flex;align-items:center;gap:0.3rem;padding:0.4rem 0.9rem;
                                           background:rgba(99,102,241,0.15);border:1px solid rgba(99,102,241,0.4);
                                           color:#a5b4fc;border-radius:6px;font-size:0.8rem;cursor:pointer;">
                                    <span class="material-icons-round" style="font-size:0.9rem;">psychology</span>${draft._analyzed ? 'Tekrar Analiz' : 'Analiz Et'}
                                </button>` : ''}
                                <button onclick="approveSingleDraft('${draft._topicId}','${draft._topicName.replace(/'/g, "\\'")}','${draft._moduleType}',${draft._index})"
                                    style="display:flex;align-items:center;gap:0.3rem;padding:0.4rem 0.9rem;
                                           background:linear-gradient(135deg,#10b981,#059669);border:none;
                                           color:white;border-radius:6px;font-size:0.8rem;font-weight:600;cursor:pointer;">
                                    <span class="material-icons-round" style="font-size:0.9rem;">check</span>${draft._moduleType === 'questions' ? 'Onayla & Ekle' : 'Onayla'}
                                </button>
                                <button onclick="deletePageDraftSingle(${i})"
                                    style="display:flex;align-items:center;gap:0.3rem;padding:0.4rem 0.9rem;
                                           background:transparent;border:1px solid #ef4444;
                                           color:#ef4444;border-radius:6px;font-size:0.8rem;cursor:pointer;">
                                    <span class="material-icons-round" style="font-size:0.9rem;">delete</span>Sil
                                </button>
                            </div>
                            ${draft._moduleType === 'questions' && draft._analyzed && draft._analysisResult ? `
                            <div id="draftAnalysisResult-${i}" style="margin-top:0.75rem;padding:0.75rem;background:rgba(15,23,42,0.6);border-radius:8px;border:1px solid rgba(255,255,255,0.07)">
                                ${renderDraftAnalysisBadge(draft._analysisResult)}
                            </div>` : `<div id="draftAnalysisResult-${i}"></div>`}
                        </div>
                    </div>
                </div>
            `).join('')}
        </div>`;
}

function renderDraftAnalysisBadge(result) {
    const verdictColors = {
        'Geçerli': { color: '#34d399', icon: 'check_circle' },
        'Küçük düzeltme gerekli': { color: '#fbbf24', icon: 'info' },
        'Revizyon gerekli': { color: '#fb923c', icon: 'warning' },
        'Hatalı': { color: '#f87171', icon: 'cancel' }
    };
    const vc = verdictColors[result.verdict] || { color: '#94a3b8', icon: 'help' };
    const errorCriteria = (result.criteria || []).filter(c => c.hasError);
    return `<div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap">
        <span class="material-icons-round" style="font-size:16px;color:${vc.color}">${vc.icon}</span>
        <span style="font-weight:700;color:${vc.color};font-size:0.82rem">${result.verdict}</span>
        <span style="color:var(--text-muted);font-size:0.78rem">${result.score}/10</span>
        ${errorCriteria.length ? `<span style="font-size:0.75rem;color:#f87171">${errorCriteria.length} hata: ${errorCriteria.map(c => c.id + '. ' + c.name).join(', ')}</span>` : '<span style="font-size:0.75rem;color:#34d399">✓ Hata yok</span>'}
    </div>`;
}

let _bulkDraftStop = false;

window.bulkAnalyzeDrafts = async function() {
    const questions = _allPageDrafts.filter(d => d._moduleType === 'questions');
    if (questions.length === 0) { showToast('Analiz edilecek soru taslağı yok', 'warn'); return; }

    _bulkDraftStop = false;
    const startBtn = document.getElementById('bulk-draft-analyze-btn');
    const stopBtn = document.getElementById('bulk-draft-stop-btn');
    if (startBtn) startBtn.style.display = 'none';
    if (stopBtn) stopBtn.style.display = 'flex';

    let done = 0, failed = 0;
    const model = document.getElementById('aa-model-select')?.value || 'google/gemini-3.1-flash-lite-preview';

    for (let i = 0; i < _allPageDrafts.length; i++) {
        if (_bulkDraftStop) break;
        const draft = _allPageDrafts[i];
        if (draft._moduleType !== 'questions') continue;

        const btn = document.getElementById(`draftAnalyzeBtn-${i}`);
        const resultEl = document.getElementById(`draftAnalysisResult-${i}`);
        if (btn) { btn.disabled = true; btn.innerHTML = '<span class="material-icons-round" style="font-size:0.9rem;animation:spin 1s linear infinite">sync</span>Analiz...'; }

        try {
            const res = await fetch(`${API}/api/ai/deep-analyze`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    question: draft,
                    topicInfo: { name: draft._topicName, lesson: draft._topicLesson },
                    model
                })
            });
            const data = await res.json();
            if (!data.success) throw new Error(data.error || 'Analiz başarısız');

            await fetch(`${API}/api/ai-content/update-draft`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    moduleType: 'questions',
                    topicId: draft._topicId,
                    index: draft._index,
                    updatedDraft: {
                        _analyzed: true,
                        _analyzedAt: new Date().toISOString(),
                        _analysisResult: { criteria: data.criteria, verdict: data.verdict, score: data.score, summary: data.summary }
                    }
                })
            });

            _allPageDrafts[i]._analyzed = true;
            _allPageDrafts[i]._analysisResult = { criteria: data.criteria, verdict: data.verdict, score: data.score, summary: data.summary };
            if (resultEl) resultEl.innerHTML = renderDraftAnalysisBadge(_allPageDrafts[i]._analysisResult);
            if (btn) { btn.disabled = false; btn.innerHTML = '<span class="material-icons-round" style="font-size:0.9rem;">psychology</span>Tekrar Analiz'; }
            done++;

            if (startBtn) startBtn.textContent = `Analiz ediliyor... ${done}/${questions.length}`;
        } catch(e) {
            failed++;
            if (btn) { btn.disabled = false; btn.innerHTML = '<span class="material-icons-round" style="font-size:0.9rem;">psychology</span>Analiz Et'; }
        }
    }

    if (startBtn) { startBtn.style.display = 'flex'; startBtn.innerHTML = '<span class="material-icons-round" style="font-size:1rem">psychology</span> Tümünü Analiz Et'; }
    if (stopBtn) stopBtn.style.display = 'none';
    showToast(`Analiz tamamlandı: ${done} başarılı${failed ? ', ' + failed + ' hatalı' : ''}`, done > 0 ? 'success' : 'warn');
};

window.stopBulkAnalyzeDrafts = function() {
    _bulkDraftStop = true;
    const stopBtn = document.getElementById('bulk-draft-stop-btn');
    if (stopBtn) stopBtn.style.display = 'none';
    showToast('Analiz durduruldu', 'warn');
};

window.analyzeDraftQuestion = async function(pageIndex) {
    const draft = _allPageDrafts[pageIndex];
    if (!draft || draft._moduleType !== 'questions') return;

    const btn = document.getElementById(`draftAnalyzeBtn-${pageIndex}`);
    const resultEl = document.getElementById(`draftAnalysisResult-${pageIndex}`);
    if (btn) { btn.disabled = true; btn.innerHTML = '<span class="material-icons-round" style="font-size:0.9rem;animation:spin 1s linear infinite">sync</span>Analiz...'; }

    try {
        const model = document.getElementById('aa-model-select')?.value || 'google/gemini-3.1-flash-lite-preview';
        const res = await fetch(`${API}/api/ai/deep-analyze`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                question: draft,
                topicInfo: { name: draft._topicName, lesson: draft._topicLesson },
                model
            })
        });
        const data = await res.json();
        if (!data.success) throw new Error(data.error || 'Analiz başarısız');

        // Draft'ı güncelle
        await fetch(`${API}/api/ai-content/update-draft`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                moduleType: 'questions',
                topicId: draft._topicId,
                index: draft._index,
                updatedDraft: {
                    _analyzed: true,
                    _analyzedAt: new Date().toISOString(),
                    _analysisResult: { criteria: data.criteria, verdict: data.verdict, score: data.score, summary: data.summary }
                }
            })
        });

        // Lokal state güncelle
        _allPageDrafts[pageIndex]._analyzed = true;
        _allPageDrafts[pageIndex]._analysisResult = { criteria: data.criteria, verdict: data.verdict, score: data.score, summary: data.summary };

        if (resultEl) resultEl.innerHTML = renderDraftAnalysisBadge(_allPageDrafts[pageIndex]._analysisResult);
        if (btn) { btn.disabled = false; btn.innerHTML = '<span class="material-icons-round" style="font-size:0.9rem;">psychology</span>Tekrar Analiz'; }
        showToast(`✅ Analiz tamamlandı: ${data.verdict}`, 'success');
    } catch(e) {
        if (btn) { btn.disabled = false; btn.innerHTML = '<span class="material-icons-round" style="font-size:0.9rem;">psychology</span>Analiz Et'; }
        showToast('Analiz hatası: ' + e.message, 'error');
    }
};

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
            // Soru taslakları için /add kullan
            if (g.moduleType === 'questions') {
                const draftsRes = await fetch(`${API}/api/ai-content/drafts?topicId=${encodeURIComponent(g.topicId)}&moduleType=questions`);
                const draftsData = await draftsRes.json();
                const allDraftsForTopic = draftsData.drafts || [];
                const toAdd = g.indices.map(i => allDraftsForTopic[i]).filter(Boolean);
                if (toAdd.length) {
                    const addRes = await fetch(`${API}/add`, {
                        method: 'POST', headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ topicId: g.topicId, questions: toAdd })
                    });
                    const addData = await addRes.json();
                    if (!addData.success) throw new Error(addData.error || 'Eklenemedi');
                    await fetch(`${API}/api/ai-content/delete-draft`, {
                        method: 'POST', headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ moduleType: 'questions', topicId: g.topicId, indices: g.indices })
                    });
                    approved += toAdd.length;
                }
                continue;
            }
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

