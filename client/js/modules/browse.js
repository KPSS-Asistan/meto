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
    const reviewedCount = questions.filter(q => q._reviewed === true).length;

    console.log('[renderBrowseList] Rendering questions:', questions.length, 'topic:', topicId);
    const esc = window.escapeHtml || function (value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    };

    // Toplu sıfırla butonu (sadece incelenen varsa göster)
    const resetBtnHtml = reviewedCount > 0 ? `
        <div style="margin-bottom:1rem;display:flex;align-items:center;gap:10px;padding:10px 16px;background:var(--bg-input);border-radius:10px;border:1px solid var(--border)">
            <span class="material-icons-round" style="color:#22c55e;font-size:18px">check_circle</span>
            <span style="font-size:.875rem;color:var(--text-secondary)">${reviewedCount} / ${questions.length} soru editör tarafından incelendi</span>
            <button onclick="window.browseResetReviewed('${topicId || ''}')" style="margin-left:auto;padding:5px 12px;background:#fef3c7;color:#92400e;border:1px solid #fde68a;border-radius:6px;cursor:pointer;font-size:.8rem;font-weight:600;display:flex;align-items:center;gap:5px">
                <span class="material-icons-round" style="font-size:14px">restart_alt</span>
                İnceleme İşaretlerini Sıfırla
            </button>
        </div>` : '';

    const headerEl = document.createElement('div');
    headerEl.innerHTML = resetBtnHtml;
    if (resetBtnHtml) listEl.before(headerEl);
    const questionCards = questions.map((q, idx) => `
        <div style="background:var(--bg-input); border-radius:12px; padding:1.25rem; border:1px solid var(--border); margin-bottom:1rem; position:relative">
            <div style="position:absolute; top:1rem; right:1rem; display:flex; gap:0.5rem; align-items:center">
                ${q._reviewed ? `<span title="Editör tarafından incelendi" style="background:#f0fdf4;color:#15803d;border:1px solid #22c55e;border-radius:6px;padding:3px 7px;font-size:.72rem;font-weight:700;display:flex;align-items:center;gap:3px"><span class="material-icons-round" style="font-size:13px">check</span>İncelendi</span>` : ''}
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

window.browseResetReviewed = async function (topicId) {
    const resolvedTopicId = topicId || window.currentBrowseTopicId;
    if (!resolvedTopicId) { showToast('Konu seçilmedi', 'error'); return; }
    if (!confirm('Bu konudaki tüm inceleme işaretleri sıfırlanacak. Emin misin?')) return;
    try {
        const res = await fetch(API + '/editor/reset-reviewed', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ topicId: resolvedTopicId })
        });
        const data = await res.json();
        if (data.success) {
            showToast(`${data.resetCount} sorunun inceleme işareti sıfırlandı`, 'success');
            window.loadBrowseQuestions(resolvedTopicId);
        } else {
            showToast('Hata: ' + (data.error || 'Bilinmeyen'), 'error');
        }
    } catch (e) {
        showToast('Bağlantı hatası', 'error');
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


