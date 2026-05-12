// =====================================================================
// AKILLI SORU EKLE MODULE
// =====================================================================
window.addSmart = (() => {
    const API = () => window.CONFIG?.API_URL || 'http://localhost:8002';
    let _allTopics = [];
    let _topicId = null;
    let _topicName = null;
    let _topicLesson = null;
    let _lastResult = null;

    function asToast(msg, type = 'success') {
        const t = document.getElementById('toast');
        if (!t) return;
        t.textContent = msg;
        t.className = 'toast show' + (type === 'error' ? ' toast-error' : type === 'warn' ? ' toast-warn' : '');
        clearTimeout(asToast._timer);
        asToast._timer = setTimeout(() => { t.className = 'toast'; }, 3500);
    }

    async function init() {
        try {
            const res = await fetch(`${API()}/topics`);
            _allTopics = await res.json();
            populateLessons();
        } catch (e) {
            asToast('Konular yüklenemedi: ' + e.message, 'error');
        }
    }

    function populateLessons() {
        const sel = document.getElementById('as-lesson-select');
        if (!sel) return;
        const lessons = [...new Set(_allTopics.map(t => t.lesson).filter(Boolean))].sort();
        sel.innerHTML = '<option value="">Ders Seç...</option>' +
            lessons.map(l => `<option value="${l}">${l}</option>`).join('');
    }

    function onLessonChange() {
        const lesson = document.getElementById('as-lesson-select')?.value;
        const topicSel = document.getElementById('as-topic-select');
        if (!topicSel) return;
        const filtered = lesson ? _allTopics.filter(t => t.lesson === lesson) : _allTopics;
        topicSel.innerHTML = '<option value="">Konu Seç...</option>' +
            filtered.map(t => `<option value="${t.id}">${t.name}</option>`).join('');
        _topicId = null; _topicName = null; _topicLesson = null;
    }

    function onTopicChange() {
        const val = document.getElementById('as-topic-select')?.value;
        const topic = _allTopics.find(t => t.id === val);
        _topicId = topic?.id || null;
        _topicName = topic?.name || null;
        _topicLesson = topic?.lesson || null;
    }

    function clearForm() {
        ['as-q', 'as-o0', 'as-o1', 'as-o2', 'as-o3', 'as-o4', 'as-subtopic', 'as-explanation'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.value = '';
        });
        const ans = document.getElementById('as-answer');
        if (ans) ans.value = '0';
        const diff = document.getElementById('as-difficulty');
        if (diff) diff.value = '3';
        _lastResult = null;
        resetResult();
    }

    function resetResult() {
        document.getElementById('as-placeholder').style.display = '';
        document.getElementById('as-loading').style.display = 'none';
        document.getElementById('as-result').style.display = 'none';
        const saveBtn = document.getElementById('as-save-btn');
        if (saveBtn) { saveBtn.disabled = true; saveBtn.style.opacity = '0.5'; }
    }

    function readForm() {
        return {
            q: document.getElementById('as-q')?.value.trim() || '',
            o: [0,1,2,3,4].map(i => document.getElementById(`as-o${i}`)?.value.trim() || ''),
            a: parseInt(document.getElementById('as-answer')?.value || '0'),
            e: document.getElementById('as-explanation')?.value.trim() || '',
            d: parseInt(document.getElementById('as-difficulty')?.value || '3'),
            subtopic: document.getElementById('as-subtopic')?.value.trim() || '',
        };
    }

    async function _generateOne(difficulty, subtopic, model) {
        const genDiff = difficulty === 0 ? Math.ceil(Math.random() * 5) : difficulty;
        const res = await fetch(`${API()}/api/ai/generate-one`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ topicId: _topicId, topicName: _topicName, lesson: _topicLesson, subtopic, difficulty: genDiff, model })
        });
        const data = await res.json();
        if (!data.success) throw new Error(data.error || 'Üretim başarısız');
        return { ...data.question, d: data.question.d || genDiff };
    }

    function _fillForm(q) {
        const qEl = document.getElementById('as-q');
        if (qEl) qEl.value = q.q || '';
        [0,1,2,3,4].forEach(i => {
            const el = document.getElementById(`as-o${i}`);
            if (el) el.value = (q.o || [])[i] || '';
        });
        const ansEl = document.getElementById('as-answer');
        if (ansEl) ansEl.value = q.a ?? 0;
        const expEl = document.getElementById('as-explanation');
        if (expEl) expEl.value = q.e || '';
        const diffEl = document.getElementById('as-difficulty');
        if (diffEl) diffEl.value = q.d || 3;
        const subEl = document.getElementById('as-subtopic');
        if (subEl && q.subtopic) subEl.value = q.subtopic;
    }

    async function generateWithAI() {
        if (!_topicId) { asToast('Önce ders ve konu seçin', 'warn'); return; }

        const count = Math.min(20, Math.max(1, parseInt(document.getElementById('as-gen-count')?.value || '1') || 1));
        const difficulty = parseInt(document.getElementById('as-gen-difficulty')?.value ?? '3');
        const model = document.getElementById('as-model-select')?.value || 'google/gemini-3.1-flash-lite-preview';
        const subtopic = document.getElementById('as-subtopic')?.value.trim() || '';

        const btn = document.getElementById('as-generate-btn');
        const setBtn = (label) => { if (btn) { btn.disabled = !!label; btn.innerHTML = label || '<span class="material-icons-round" style="font-size:20px">auto_awesome</span> AI ile Üret'; } };

        setBtn('<span class="material-icons-round" style="font-size:18px;animation:spin 1s linear infinite">sync</span> Üretiliyor...');

        try {
            if (count === 1) {
                // Tek soru → formu doldur
                const q = await _generateOne(difficulty, subtopic, model);
                _fillForm(q);
                _lastResult = null;
                resetResult();
                asToast('✨ Soru üretildi! Düzenleyin ardından analiz edin.', 'success');
            } else {
                // Çoklu soru → hepsini taslağa kaydet
                const questions = [];
                let done = 0;
                setBtn(`<span class="material-icons-round" style="font-size:18px;animation:spin 1s linear infinite">sync</span> 0/${count}...`);
                for (let i = 0; i < count; i++) {
                    try {
                        const q = await _generateOne(difficulty, subtopic, model);
                        questions.push({ ...q, topicId: _topicId, _draftAddedAt: new Date().toISOString() });
                    } catch(e) {
                        console.warn(`Soru ${i+1} üretilemedi:`, e.message);
                    }
                    done++;
                    setBtn(`<span class="material-icons-round" style="font-size:18px;animation:spin 1s linear infinite">sync</span> ${done}/${count}...`);
                }
                if (questions.length === 0) throw new Error('Hiç soru üretilemedi');

                const saveRes = await fetch(`${API()}/api/ai-content/add-draft`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ moduleType: 'questions', topicId: _topicId, items: questions })
                });
                const saveData = await saveRes.json();
                if (!saveData.success) throw new Error(saveData.error || 'Taslağa kayıt başarısız');

                asToast(`✨ ${questions.length} soru taslağa eklendi!`, 'success');
                if (typeof window.showPage === 'function') window.showPage('drafts');
                if (typeof window.loadAllDrafts === 'function') window.loadAllDrafts();
            }
        } catch(e) {
            asToast('Üretim hatası: ' + e.message, 'error');
        } finally {
            setBtn(null);
        }
    }

    async function analyze() {
        if (!_topicId) { asToast('Önce konu seçin', 'warn'); return; }
        const q = readForm();
        if (!q.q) { asToast('Soru metnini girin', 'warn'); return; }
        const emptyOpts = q.o.filter(o => !o);
        if (emptyOpts.length > 0) { asToast('Tüm 5 şıkkı doldurun', 'warn'); return; }
        if (!q.e) { asToast('Açıklama girin', 'warn'); return; }

        document.getElementById('as-placeholder').style.display = 'none';
        document.getElementById('as-loading').style.display = '';
        document.getElementById('as-result').style.display = 'none';
        document.getElementById('as-analyze-btn').disabled = true;

        const model = document.getElementById('as-model-select')?.value || 'google/gemini-3.1-flash-lite-preview';
        try {
            const res = await fetch(`${API()}/api/ai/deep-analyze`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ question: q, topicInfo: { name: _topicName, lesson: _topicLesson }, model })
            });
            const data = await res.json();
            if (!data.success) throw new Error(data.error || 'Analiz başarısız');
            _lastResult = data;
            renderResult(data);
        } catch (e) {
            asToast('Analiz hatası: ' + e.message, 'error');
            resetResult();
        } finally {
            document.getElementById('as-loading').style.display = 'none';
            document.getElementById('as-analyze-btn').disabled = false;
        }
    }

    function renderResult(data) {
        const verdictColors = {
            'Geçerli': { bg: 'rgba(16,185,129,0.15)', border: 'rgba(16,185,129,0.4)', color: '#34d399', icon: 'check_circle' },
            'Küçük düzeltme gerekli': { bg: 'rgba(234,179,8,0.12)', border: 'rgba(234,179,8,0.35)', color: '#fbbf24', icon: 'info' },
            'Revizyon gerekli': { bg: 'rgba(249,115,22,0.12)', border: 'rgba(249,115,22,0.35)', color: '#fb923c', icon: 'warning' },
            'Hatalı': { bg: 'rgba(239,68,68,0.12)', border: 'rgba(239,68,68,0.35)', color: '#f87171', icon: 'cancel' }
        };
        const vc = verdictColors[data.verdict] || verdictColors['Revizyon gerekli'];
        const banner = document.getElementById('as-verdict-banner');
        banner.style.cssText = `padding:0.75rem 1rem;border-radius:10px;margin-bottom:1rem;display:flex;align-items:center;gap:10px;background:${vc.bg};border:1px solid ${vc.border}`;
        document.getElementById('as-verdict-icon').textContent = vc.icon;
        document.getElementById('as-verdict-icon').style.color = vc.color;
        document.getElementById('as-verdict-text').textContent = data.verdict;
        document.getElementById('as-verdict-text').style.color = vc.color;
        document.getElementById('as-verdict-summary').textContent = data.summary || '';
        document.getElementById('as-score').textContent = (data.score || '-') + '/10';
        document.getElementById('as-score').style.color = vc.color;

        const list = document.getElementById('as-criteria-list');
        list.innerHTML = (data.criteria || []).map(c => {
            const hasErr = c.hasError;
            return `<div style="padding:0.6rem 0.8rem;border-radius:8px;background:${hasErr ? 'rgba(239,68,68,0.07)' : 'rgba(255,255,255,0.03)'};border:1px solid ${hasErr ? 'rgba(239,68,68,0.25)' : 'rgba(255,255,255,0.07)'}">
                <div style="display:flex;align-items:center;gap:6px;margin-bottom:${c.explanation ? '4px' : '0'}">
                    <span class="material-icons-round" style="font-size:15px;color:${hasErr ? '#f87171' : '#34d399'}">${hasErr ? 'error' : 'check_circle'}</span>
                    <span style="font-size:0.8rem;font-weight:700;color:var(--text-primary)">${c.id}. ${c.name}</span>
                </div>
                ${c.explanation ? `<div style="font-size:0.78rem;color:var(--text-muted);margin-left:21px">${c.explanation}</div>` : ''}
                ${c.suggestion ? `<div style="font-size:0.78rem;color:#fbbf24;margin-left:21px;margin-top:2px">💡 ${c.suggestion}</div>` : ''}
            </div>`;
        }).join('');

        document.getElementById('as-result').style.display = '';
        const saveBtn = document.getElementById('as-save-btn');
        if (saveBtn) { saveBtn.disabled = false; saveBtn.style.opacity = '1'; }
    }

    async function save() {
        if (!_topicId) { asToast('Konu seçilmedi', 'warn'); return; }
        const q = readForm();
        if (!q.q || q.o.some(o => !o) || !q.e) {
            asToast('Formu eksiksiz doldurun', 'warn'); return;
        }

        const question = {
            ...q,
            topicId: _topicId,
            _analyzed: !!_lastResult,
            _analyzedAt: _lastResult ? new Date().toISOString() : undefined,
            _analysisResult: _lastResult ? {
                criteria: _lastResult.criteria,
                verdict: _lastResult.verdict,
                score: _lastResult.score,
                summary: _lastResult.summary
            } : undefined
        };

        const saveBtn = document.getElementById('as-save-btn');
        if (saveBtn) saveBtn.disabled = true;

        try {
            const res = await fetch(`${API()}/api/ai-content/add-draft`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ moduleType: 'questions', topicId: _topicId, items: [question] })
            });
            const data = await res.json();
            if (!data.success) throw new Error(data.error || 'Kayıt başarısız');
            asToast(`📥 Taslağa eklendi (${_topicName})`, 'success');
            clearForm();
            // Taslaklar sayfasına geç
            if (window.showPage) {
                window.showPage('drafts');
                if (window.loadAllDrafts) setTimeout(() => window.loadAllDrafts(), 200);
            }
        } catch (e) {
            asToast('Kayıt hatası: ' + e.message, 'error');
            if (saveBtn) saveBtn.disabled = false;
        }
    }

    async function gitPushSmart() {
        try {
            const res = await fetch(`${API()}/api/git-push`, { method: 'POST' });
            const data = await res.json();
            if (data.success && data.message && !data.message.includes('atlandı') && !data.message.includes('yok'))
                asToast('☁️ GitHub\'a push edildi', 'success');
        } catch {}
    }

    // Sayfa açıldığında init çalıştır ve showPage hook'u kur
    const _origShowPage = window.showPage;
    window.showPage = function(page) {
        _origShowPage && _origShowPage(page);
        if (page === 'add-smart') {
            if (_allTopics.length === 0) init();
            else populateLessons(); // Zaten yüklüyse dropdown'ı tekrar doldur
        }
    };
    // DOMContentLoaded sonrasında da init'i tetikle (sayfa zaten açıksa)
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => init());
    } else {
        init();
    }

    return { init, onLessonChange, onTopicChange, clearForm, generateWithAI, analyze, save };
})();
