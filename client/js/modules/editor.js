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

// ══════════════════════════════════════════════════════════════════════════
// JSON YAPISTIR & İÇE AKTAR
// ══════════════════════════════════════════════════════════════════════════

window.loadPasteTopics = async function () {
    const lessonId = document.getElementById('pasteLesson').value;
    const topicSelect = document.getElementById('pasteTopic');
    topicSelect.innerHTML = '<option value="">Yükleniyor...</option>';
    if (!lessonId) { topicSelect.innerHTML = '<option value="">Önce Ders Seçin...</option>'; return; }

    const lessonNameMap = {
        'tarih': 'TARİH', 'cografya': 'COĞRAFYA', 'vatandaslik': 'VATANDAŞLIK',
        'turkce': 'TÜRKÇE', 'matematik': 'MATEMATİK'
    };
    const lessonName = lessonNameMap[lessonId] || lessonId.toUpperCase();
    try {
        const res = await fetch(API + '/topics');
        const topics = await res.json();
        const filtered = topics.filter(t => t.lesson === lessonName);
        topicSelect.innerHTML = '<option value="">Konu Seçin...</option>' +
            filtered.map(t => `<option value="${t.id}">${t.name}</option>`).join('');
    } catch (e) {
        topicSelect.innerHTML = '<option value="">Hata: ' + e.message + '</option>';
    }
};

// Çeşitli AI çıktı formatlarını normalize et
function normalizeAIQuestion(raw, index) {
    const q = {};
    q.q = raw.q || raw.question || raw.soru || raw.text || raw.stem || '';
    let opts = raw.o || raw.options || raw.choices || raw.secenekler || raw.şıklar || raw.siklar || [];
    if (!Array.isArray(opts)) opts = Object.values(opts);
    q.o = opts.map(String);
    let ans = raw.a ?? raw.answer ?? raw.correct ?? raw.dogru_cevap ?? raw.doğru ?? 0;
    if (typeof ans === 'string') {
        const letter = ans.trim().toUpperCase().replace(/[^A-E]/, '');
        ans = letter ? letter.charCodeAt(0) - 65 : 0;
    }
    q.a = parseInt(ans) || 0;
    q.e = raw.e || raw.explanation || raw.aciklama || raw.açıklama || raw.explain || '';
    q.d = parseInt(raw.d || raw.difficulty || raw.zorluk || 2) || 2;
    q.subtopic = raw.subtopic || raw.sub_topic || raw.alt_konu || '';

    const errors = [];
    if (!q.q) errors.push('Soru metni yok');
    if (q.o.length < 2) errors.push('En az 2 şık gerekli');
    if (q.a < 0 || q.a >= q.o.length) errors.push(`Cevap indeksi (${q.a}) geçersiz`);

    return { question: q, errors, index };
}

window.previewPasteQuestions = function () {
    const topicId = document.getElementById('pasteTopic').value;
    const raw = document.getElementById('pasteJsonInput').value.trim();
    const preview = document.getElementById('pastePreviewArea');

    if (!topicId) { showToast('Lütfen konu seçin', 'error'); return; }
    if (!raw) { showToast('JSON alanı boş', 'error'); return; }

    let parsed;
    try {
        const cleaned = raw.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '').trim();
        parsed = JSON.parse(cleaned);
        if (!Array.isArray(parsed)) parsed = [parsed];
    } catch (e) {
        preview.innerHTML = `<div style="background:rgba(239,68,68,0.1);border:1px solid #ef4444;border-radius:10px;padding:1rem;color:#f87171;">
            <b>JSON Parse Hatası:</b> ${e.message}<br>
            <span style="font-size:0.8rem;color:#94a3b8;">JSON formatını kontrol edin.</span>
        </div>`;
        return;
    }

    const results = parsed.map((r, i) => normalizeAIQuestion(r, i));
    const valid = results.filter(r => r.errors.length === 0);
    const invalid = results.filter(r => r.errors.length > 0);
    const labels = ['A', 'B', 'C', 'D', 'E'];

    const cardsHtml = results.map(({ question: q, errors, index }) => {
        const hasError = errors.length > 0;
        const opts = (q.o || []).map((opt, i) =>
            `<span style="display:block;padding:3px 8px;border-radius:5px;font-size:0.8rem;
                background:${i === q.a ? 'rgba(16,185,129,0.15)' : 'transparent'};
                color:${i === q.a ? '#6ee7b7' : '#94a3b8'};">
                ${labels[i] || i}) ${opt}${i === q.a ? ' ✓' : ''}
            </span>`
        ).join('');
        return `<div style="background:${hasError ? 'rgba(239,68,68,0.06)' : 'rgba(15,23,42,0.6)'};
            border:1px solid ${hasError ? 'rgba(239,68,68,0.4)' : '#334155'};
            border-radius:10px;padding:0.85rem;margin-bottom:0.5rem;">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:0.5rem;">
                <span style="font-size:0.72rem;color:#6366f1;font-weight:600;">#${index + 1}</span>
                ${hasError
                    ? `<span style="font-size:0.72rem;color:#f87171;">⚠️ ${errors.join(', ')}</span>`
                    : `<span style="font-size:0.72rem;color:#10b981;">✓ Geçerli</span>`}
            </div>
            <div style="font-size:0.87rem;color:#e2e8f0;margin-bottom:0.5rem;">${q.q || '(Soru yok)'}</div>
            <div style="margin-bottom:0.35rem;">${opts}</div>
            ${q.e ? `<div style="font-size:0.78rem;color:#fcd34d;border-top:1px solid #1e293b;padding-top:0.35rem;margin-top:0.35rem;"><b>Açıklama:</b> ${q.e}</div>` : ''}
        </div>`;
    }).join('');

    const topicName = document.getElementById('pasteTopic').selectedOptions[0]?.text || topicId;

    preview.innerHTML = `
        <div style="display:flex;align-items:center;gap:1rem;margin-bottom:1rem;flex-wrap:wrap;">
            <span style="font-size:0.85rem;color:#e2e8f0;">
                <b>${results.length}</b> soru okundu &nbsp;·&nbsp;
                <span style="color:#10b981;">${valid.length} geçerli</span>
                ${invalid.length > 0 ? `&nbsp;·&nbsp;<span style="color:#f87171;">${invalid.length} hatalı</span>` : ''}
            </span>
            ${valid.length > 0 ? `
            <button onclick="window.importPasteQuestions('${topicId}')"
                style="padding:0.5rem 1.2rem;background:linear-gradient(135deg,#6366f1,#8b5cf6);border:none;color:white;border-radius:8px;cursor:pointer;font-size:0.85rem;font-weight:600;display:flex;align-items:center;gap:0.4rem;">
                <span class="material-icons-round" style="font-size:1rem;">upload</span>
                ${valid.length} Soruyu "${topicName}" Konusuna Ekle
            </button>` : ''}
        </div>
        ${cardsHtml}`;

    window._pasteValidQuestions = valid.map(r => r.question);
};

window.importPasteQuestions = async function (topicId) {
    const questions = window._pasteValidQuestions;
    if (!questions || questions.length === 0) { showToast('Eklenecek soru yok', 'error'); return; }
    if (!topicId) { showToast('Konu seçilmedi', 'error'); return; }

    try {
        const res = await fetch(API + '/add', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ topicId, questions })
        });
        const data = await res.json();
        if (!data.success) throw new Error(data.error || 'Ekleme başarısız');

        showToast(`✅ ${questions.length} soru başarıyla eklendi!`, 'success');
        document.getElementById('pasteJsonInput').value = '';
        document.getElementById('pastePreviewArea').innerHTML = '';
        window._pasteValidQuestions = [];
    } catch (e) {
        showToast('Hata: ' + e.message, 'error');
    }
};

// ══════════════════════════════════════════════════════════════════════════

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


