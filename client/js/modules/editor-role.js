/**
 * editor-role.js — Editör paneli (inceleme kuyruğu)
 * Özellikler: konu filtresi, geri al, atlanan sayacı, klavye kısayolları
 */

(function () {
    'use strict';

    const EDITOR_API = (window.CONFIG && window.CONFIG.API_URL)
        ? window.CONFIG.API_URL
        : window.location.origin;

    window._editorState = {
        current: null,       // { question, topicId, topicName }
        stats: null,         // { total, reviewed, remaining }
        editOpen: false,
        lastMarked: null,    // { questionId, topicId } — geri al için
        selectedTopicId: ''  // konu filtresi
    };
    window._editorSkipped = new Set();

    // ─── Toast ───────────────────────────────────────────────────────────────
    let _toastTimeout = null;
    function editorToast(msg, type = 'info') {
        let el = document.getElementById('editorToast');
        if (!el) {
            el = document.createElement('div');
            el.id = 'editorToast';
            Object.assign(el.style, {
                position: 'fixed', bottom: '32px', left: '50%',
                transform: 'translateX(-50%)',
                padding: '10px 22px', borderRadius: '8px',
                fontFamily: "'Inter',sans-serif", fontSize: '14px',
                fontWeight: '600', zIndex: '99999',
                boxShadow: '0 4px 16px rgba(0,0,0,.22)',
                transition: 'opacity .3s ease', pointerEvents: 'none'
            });
            document.body.appendChild(el);
        }
        const colors = {
            ok:   { bg: '#22c55e', color: '#fff' },
            err:  { bg: '#ef4444', color: '#fff' },
            warn: { bg: '#f97316', color: '#fff' },
            info: { bg: '#1e293b', color: '#fff' }
        };
        const c = colors[type] || colors.info;
        el.style.background = c.bg;
        el.style.color = c.color;
        el.textContent = msg;
        el.style.opacity = '1';
        clearTimeout(_toastTimeout);
        _toastTimeout = setTimeout(() => { el.style.opacity = '0'; }, 3000);
    }

    // ─── Sekme geçişi ─────────────────────────────────────────────────────────
    function editorShowTab(name) {
        ['review', 'search'].forEach(t => {
            const btn   = document.getElementById(`editorTab_${t}`);
            const panel = document.getElementById(`editorPanel_${t}`);
            if (!btn || !panel) return;
            const active = t === name;
            btn.classList.toggle('active', active);
            panel.style.display = active ? '' : 'none';
        });
    }

    // ─── İlerleme ────────────────────────────────────────────────────────────
    function editorUpdateProgress(stats) {
        const el = document.getElementById('editorProgress');
        if (!el) return;
        if (!stats) {
            el.innerHTML = `<div style="color:#94a3b8;font-size:.85rem">Yükleniyor...</div>`;
            return;
        }
        const pct = stats.total > 0 ? Math.round((stats.reviewed / stats.total) * 100) : 0;
        el.innerHTML = `
            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">
                <span style="font-size:.8rem;font-weight:700;color:#64748b;letter-spacing:.04em;text-transform:uppercase">İLERLEME</span>
                <span style="font-size:.85rem;font-weight:700;color:#6366f1">${pct}%</span>
            </div>
            <div style="height:8px;background:#e2e8f0;border-radius:99px;overflow:hidden;margin-bottom:10px">
                <div style="height:100%;width:${pct}%;background:linear-gradient(90deg,#6366f1,#818cf8);border-radius:99px;transition:width .5s ease"></div>
            </div>
            <div style="display:flex;gap:20px;font-size:.82rem;color:#94a3b8">
                <span><strong style="color:#22c55e">${stats.reviewed}</strong> incelendi</span>
                <span><strong style="color:#f97316">${stats.remaining}</strong> bekliyor</span>
                <span><strong style="color:#64748b">${stats.total}</strong> toplam</span>
            </div>`;
    }

    // ─── Atlanan sayacı güncelle ──────────────────────────────────────────────
    function editorUpdateSkipBadge() {
        const badge = document.getElementById('editorSkipBadge');
        if (!badge) return;
        const count = window._editorSkipped.size;
        badge.textContent = count > 0 ? `${count} soru atlandı — sıfırla` : '';
        badge.style.display = count > 0 ? 'inline-block' : 'none';
    }

    // ─── Geri al butonunu göster/gizle ───────────────────────────────────────
    function editorUpdateUndoBtn() {
        const btn = document.getElementById('editorBtnUndo');
        if (!btn) return;
        btn.style.display = window._editorState.lastMarked ? '' : 'none';
    }

    // ─── Done ekranı ─────────────────────────────────────────────────────────
    function editorShowDone() {
        const card = document.getElementById('editorQuestionCard');
        if (card) card.innerHTML = `
            <div style="text-align:center;padding:56px 16px;color:#64748b">
                <span class="material-icons-round" style="font-size:72px;color:#22c55e">check_circle</span>
                <h2 style="margin:16px 0 8px;font-size:1.5rem;color:#1e293b">Tüm sorular incelendi!</h2>
                <p style="font-size:.95rem">Havuzda bekleyen soru kalmadı.</p>
            </div>`;
        const actions = document.getElementById('editorActions');
        if (actions) actions.style.display = 'none';
    }

    // ─── Soru kartı render ────────────────────────────────────────────────────
    function editorRenderQuestion(q, topicName) {
        const card = document.getElementById('editorQuestionCard');
        if (!card) return;
        const labels = ['A', 'B', 'C', 'D', 'E'];
        const opts = Array.isArray(q.o) ? q.o : [];
        const optHtml = opts.map((o, i) => {
            const correct = q.a === i;
            return `<li class="eopt${correct ? ' correct' : ''}">
                <strong>${labels[i]})</strong> ${escHtml(o)}
            </li>`;
        }).join('');

        card.innerHTML = `
            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:10px">
                <span style="font-size:11px;color:#94a3b8;font-weight:600;letter-spacing:.05em;text-transform:uppercase">${escHtml(q.id || '')}</span>
                <span style="font-size:11px;background:#eff6ff;color:#3b82f6;padding:3px 10px;border-radius:99px;font-weight:600">${escHtml(topicName || '')}</span>
            </div>
            <p style="font-size:1rem;line-height:1.7;margin-bottom:14px;color:#1e293b;font-weight:500">${escHtml(q.q || '')}</p>
            <ul style="list-style:none;padding:0;margin:0">${optHtml}</ul>
            ${q.e ? `<div class="eexplain"><strong>Açıklama:</strong> ${escHtml(q.e)}</div>` : ''}
        `;

        const actions = document.getElementById('editorActions');
        if (actions) actions.style.display = '';

        const editSection = document.getElementById('editorEditSection');
        if (editSection) editSection.style.display = 'none';
        window._editorState.editOpen = false;
        const btnEdit = document.getElementById('editorBtnEdit');
        if (btnEdit) btnEdit.textContent = 'Düzenle';

        _fillEditForm(q);
    }

    function _fillEditForm(q) {
        const fq = document.getElementById('editQ');
        const fe = document.getElementById('editE');
        if (fq) fq.value = q.q || '';
        if (fe) fe.value = q.e || '';
        const opts = Array.isArray(q.o) ? q.o : [];
        for (let i = 0; i < 5; i++) {
            const fi = document.getElementById(`editO${i}`);
            if (fi) fi.value = opts[i] || '';
        }
        const labels = ['A', 'B', 'C', 'D', 'E'];
        const fa = document.getElementById('editA');
        if (fa) {
            fa.innerHTML = labels.map((l, i) =>
                `<option value="${i}" ${q.a === i ? 'selected' : ''}>${l})</option>`
            ).join('');
        }
    }

    // ─── Sonraki soru yükle ───────────────────────────────────────────────────
    async function editorLoadNext() {
        const card = document.getElementById('editorQuestionCard');
        if (card) card.innerHTML = `<div style="text-align:center;padding:48px;color:#94a3b8">
            <span class="material-icons-round" style="font-size:42px;display:block;animation:spin 1s linear infinite">refresh</span>
            <p style="margin-top:12px;font-size:.9rem">Yükleniyor...</p>
        </div>`;
        const actions = document.getElementById('editorActions');
        if (actions) actions.style.display = 'none';

        const skipList = Array.from(window._editorSkipped).join(',');
        const topicId  = window._editorState.selectedTopicId;
        let url = `${EDITOR_API}/editor/next-question`;
        const params = [];
        if (skipList) params.push(`skip=${encodeURIComponent(skipList)}`);
        if (topicId)  params.push(`topicId=${encodeURIComponent(topicId)}`);
        if (params.length) url += '?' + params.join('&');

        try {
            const resp = await authFetch(url);
            const data = await resp.json();

            if (data.done) {
                window._editorState.current = null;
                window._editorState.stats = data.stats || null;
                editorUpdateProgress(data.stats);
                editorShowDone();
                return;
            }

            window._editorState.current = {
                question: data.question,
                topicId:  data.topicId,
                topicName: data.topicName || data.topicId
            };
            window._editorState.stats = data.stats;
            editorUpdateProgress(data.stats);
            editorRenderQuestion(data.question, data.topicName || data.topicId);
        } catch (e) {
            if (card) card.innerHTML = `<p style="color:#ef4444;padding:16px">Hata: ${escHtml(e.message)}</p>`;
        }
    }

    // ─── İşaretle + Sonraki ──────────────────────────────────────────────────
    async function editorMarkAndNext(withEdits) {
        const cur = window._editorState.current;
        if (!cur) return;

        const body = { questionId: cur.question.id, topicId: cur.topicId };

        if (withEdits) {
            const fq = document.getElementById('editQ');
            const fe = document.getElementById('editE');
            const fa = document.getElementById('editA');
            const opts = [];
            for (let i = 0; i < 5; i++) {
                const fi = document.getElementById(`editO${i}`);
                opts.push(fi ? fi.value : '');
            }
            body.edits = {
                q: fq ? fq.value.trim() : undefined,
                o: opts,
                a: fa ? Number(fa.value) : undefined,
                e: fe ? fe.value.trim() : undefined
            };
        }

        try {
            const resp = await authFetch(`${EDITOR_API}/editor/mark`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body)
            });
            const data = await resp.json();
            if (!resp.ok) throw new Error(data.error || 'Kayıt hatası');

            // Geri al için kaydet
            window._editorState.lastMarked = { questionId: cur.question.id, topicId: cur.topicId };
            editorUpdateUndoBtn();

            editorToast(withEdits ? 'Düzenlendi ve işaretlendi ✓' : 'İşaretlendi ✓', 'ok');
            window._editorSkipped.delete(String(cur.question.id));
            editorUpdateSkipBadge();
            editorLoadNext();
        } catch (e) {
            editorToast(e.message, 'err');
        }
    }

    // ─── Geri Al ─────────────────────────────────────────────────────────────
    async function editorUndo() {
        const last = window._editorState.lastMarked;
        if (!last) return;

        try {
            const resp = await authFetch(`${EDITOR_API}/editor/unmark`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(last)
            });
            const data = await resp.json();
            if (!resp.ok) throw new Error(data.error || 'Geri alma hatası');

            window._editorState.lastMarked = null;
            editorUpdateUndoBtn();
            editorToast('İşaret geri alındı', 'warn');
            editorLoadNext();
        } catch (e) {
            editorToast(e.message, 'err');
        }
    }

    // ─── Atla ────────────────────────────────────────────────────────────────
    function editorSkip() {
        const cur = window._editorState.current;
        if (!cur) return;
        window._editorSkipped.add(String(cur.question.id));
        editorUpdateSkipBadge();
        editorToast('Soru atlandı', 'info');
        editorLoadNext();
    }

    // ─── Atlananları sıfırla ──────────────────────────────────────────────────
    function editorResetSkipped() {
        window._editorSkipped.clear();
        editorUpdateSkipBadge();
        editorToast('Atlananlar sıfırlandı', 'info');
        editorLoadNext();
    }

    // ─── Edit formu aç/kapat ─────────────────────────────────────────────────
    function editorToggleEdit() {
        const section = document.getElementById('editorEditSection');
        if (!section) return;
        window._editorState.editOpen = !window._editorState.editOpen;
        section.style.display = window._editorState.editOpen ? '' : 'none';
        const btn = document.getElementById('editorBtnEdit');
        if (btn) btn.textContent = window._editorState.editOpen ? 'İptal' : 'Düzenle';
        if (window._editorState.editOpen) {
            const fq = document.getElementById('editQ');
            if (fq) fq.focus();
        }
    }

    // ─── Konu filtresi yükle ─────────────────────────────────────────────────
    async function editorLoadTopics() {
        const select = document.getElementById('editorTopicFilter');
        if (!select) return;
        try {
            const resp = await authFetch(`${EDITOR_API}/editor/topics`);
            const topics = await resp.json();
            if (!Array.isArray(topics)) return;
            select.innerHTML = `<option value="">Tüm Konular</option>` +
                topics.map(t =>
                    `<option value="${escAttr(t.id)}">${escHtml(t.name)} (${t.reviewed}/${t.total})</option>`
                ).join('');
        } catch { /* topic yüklenemese de devam et */ }
    }

    // ─── Arama ────────────────────────────────────────────────────────────────
    async function editorSearch() {
        const input = document.getElementById('editorSearchInput');
        const q = input ? input.value.trim() : '';
        if (q.length < 2) { editorToast('En az 2 karakter girin', 'err'); return; }

        const resultsEl = document.getElementById('editorSearchResults');
        if (resultsEl) resultsEl.innerHTML = '<p style="color:#94a3b8;padding:16px 0">Aranıyor...</p>';

        try {
            const resp = await authFetch(`${EDITOR_API}/editor/search?q=${encodeURIComponent(q)}`);
            const data = await resp.json();
            if (!resp.ok) throw new Error(data.error || 'Arama hatası');

            if (!resultsEl) return;
            if (!data.results.length) {
                resultsEl.innerHTML = '<p style="color:#94a3b8;padding:16px 0">Sonuç bulunamadı.</p>';
                return;
            }
            resultsEl.innerHTML = data.results.map(r => editorSearchCard(r)).join('');
        } catch (e) {
            editorToast(e.message, 'err');
        }
    }

    function editorSearchCard(r) {
        const labels = ['A', 'B', 'C', 'D', 'E'];
        const opts = Array.isArray(r.o) ? r.o : [];
        const optHtml = opts.map((o, i) => {
            const correct = r.a === i;
            return `<li class="eopt${correct ? ' correct' : ''}">
                <strong>${labels[i]})</strong> ${escHtml(o)}</li>`;
        }).join('');

        return `<div class="ecard" style="margin-bottom:12px">
            <div style="display:flex;align-items:center;gap:8px;margin-bottom:8px">
                <span style="font-size:11px;color:#94a3b8;font-weight:600;letter-spacing:.05em;text-transform:uppercase">${escHtml(r.id || '')}</span>
                <span style="font-size:11px;background:#eff6ff;color:#3b82f6;padding:2px 8px;border-radius:99px;font-weight:600">${escHtml(r.topicName || r.topicId || '')}</span>
            </div>
            <p style="margin:0 0 12px;line-height:1.6;color:#1e293b;font-weight:500">${escHtml(r.q || '')}</p>
            <ul style="list-style:none;padding:0;margin:0">${optHtml}</ul>
            ${r.e ? `<div class="eexplain"><strong>Açıklama:</strong> ${escHtml(r.e)}</div>` : ''}
        </div>`;
    }

    // ─── authFetch ───────────────────────────────────────────────────────────
    function authFetch(url, options = {}) {
        const token = localStorage.getItem('kpss_admin_token');
        if (!options.headers) options.headers = {};
        if (token) options.headers['Authorization'] = `Bearer ${token}`;
        return fetch(url, options);
    }

    // ─── HTML escape ─────────────────────────────────────────────────────────
    function escHtml(str) {
        if (typeof str !== 'string') return str === undefined || str === null ? '' : String(str);
        return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
                  .replace(/"/g, '&quot;').replace(/'/g, '&#039;');
    }
    function escAttr(str) {
        return String(str || '').replace(/"/g, '&quot;').replace(/'/g, '&#039;');
    }

    // ─── Klavye kısayolları ───────────────────────────────────────────────────
    function editorKeyHandler(e) {
        // Textarea/input odaktayken çalışmasın
        if (['INPUT','TEXTAREA','SELECT'].includes(e.target.tagName)) return;
        const tab = document.getElementById('editorPanel_review');
        if (!tab || tab.style.display === 'none') return;

        if (e.code === 'Space' || e.key === ' ') {
            e.preventDefault();
            editorMarkAndNext(false);
        } else if (e.key === 's' || e.key === 'S') {
            editorSkip();
        } else if (e.key === 'e' || e.key === 'E') {
            editorToggleEdit();
        } else if (e.key === 'z' && (e.ctrlKey || e.metaKey)) {
            e.preventDefault();
            editorUndo();
        }
    }

    // ─── Uygulama başlat ─────────────────────────────────────────────────────
    function initEditorApp() {
        editorShowTab('review');
        editorUpdateProgress(null);
        editorUpdateSkipBadge();
        editorUpdateUndoBtn();

        // Tab butonları
        const tabReview = document.getElementById('editorTab_review');
        const tabSearch = document.getElementById('editorTab_search');
        if (tabReview) tabReview.addEventListener('click', () => editorShowTab('review'));
        if (tabSearch) tabSearch.addEventListener('click', () => editorShowTab('search'));

        // Aksiyon butonları
        const btnMark    = document.getElementById('editorBtnMark');
        const btnEdit    = document.getElementById('editorBtnEdit');
        const btnSaveEdit= document.getElementById('editorBtnSaveEdit');
        const btnSkip    = document.getElementById('editorBtnSkip');
        const btnUndo    = document.getElementById('editorBtnUndo');
        const btnSearch  = document.getElementById('editorBtnSearch');
        const searchInput= document.getElementById('editorSearchInput');
        const skipBadge  = document.getElementById('editorSkipBadge');
        const topicFilter= document.getElementById('editorTopicFilter');

        if (btnMark)     btnMark.addEventListener('click', () => editorMarkAndNext(false));
        if (btnEdit)     btnEdit.addEventListener('click', editorToggleEdit);
        if (btnSaveEdit) btnSaveEdit.addEventListener('click', () => editorMarkAndNext(true));
        if (btnSkip)     btnSkip.addEventListener('click', editorSkip);
        if (btnUndo)     btnUndo.addEventListener('click', editorUndo);
        if (btnSearch)   btnSearch.addEventListener('click', editorSearch);
        if (skipBadge)   skipBadge.addEventListener('click', editorResetSkipped);
        if (searchInput) searchInput.addEventListener('keydown', e => { if (e.key === 'Enter') editorSearch(); });
        if (topicFilter) topicFilter.addEventListener('change', function() {
            window._editorState.selectedTopicId = this.value;
            window._editorSkipped.clear();
            editorUpdateSkipBadge();
            editorLoadNext();
        });

        // Klavye
        document.addEventListener('keydown', editorKeyHandler);

        // Konuları yükle, ardından soruları yükle
        editorLoadTopics().then(() => editorLoadNext());
    }

    // Global erişim
    window.editorToast = editorToast;
    window.editorShowTab = editorShowTab;
    window.initEditorApp = initEditorApp;
    window.editorLoadNext = editorLoadNext;
    window.editorMarkAndNext = editorMarkAndNext;
    window.editorUndo = editorUndo;
    window.editorSkip = editorSkip;
    window.editorToggleEdit = editorToggleEdit;
    window.editorSearch = editorSearch;

})();

(function () {
    'use strict';

    const EDITOR_API = (window.CONFIG && window.CONFIG.API_URL)
        ? window.CONFIG.API_URL
        : window.location.origin;

    // Editör state
    window._editorState = {
        current: null,   // { question, topicId }
        stats: null,     // { total, reviewed, remaining }
        editOpen: false
    };
    window._editorSkipped = new Set(); // atlanan soru id'leri

    // ─── Toast (kendi fixed toast'u) ──────────────────────────────────────────
    let _toastTimeout = null;
    function editorToast(msg, type /* 'ok'|'err'|'info' */ = 'info') {
        let el = document.getElementById('editorToast');
        if (!el) {
            el = document.createElement('div');
            el.id = 'editorToast';
            Object.assign(el.style, {
                position: 'fixed', bottom: '32px', left: '50%',
                transform: 'translateX(-50%)',
                padding: '10px 22px', borderRadius: '8px',
                fontFamily: 'sans-serif', fontSize: '14px',
                fontWeight: '600', zIndex: '99999',
                boxShadow: '0 4px 16px rgba(0,0,0,.22)',
                transition: 'opacity .3s ease',
                pointerEvents: 'none'
            });
            document.body.appendChild(el);
        }
        const colors = {
            ok: { bg: '#27ae60', color: '#fff' },
            err: { bg: '#e74c3c', color: '#fff' },
            info: { bg: '#2c3e50', color: '#fff' }
        };
        const c = colors[type] || colors.info;
        el.style.background = c.bg;
        el.style.color = c.color;
        el.textContent = msg;
        el.style.opacity = '1';
        clearTimeout(_toastTimeout);
        _toastTimeout = setTimeout(() => { el.style.opacity = '0'; }, 3000);
    }

    // ─── Sekme geçişi ─────────────────────────────────────────────────────────
    function editorShowTab(name /* 'review'|'search' */) {
        const tabs = ['review', 'search'];
        tabs.forEach(t => {
            const btn = document.getElementById(`editorTab_${t}`);
            const panel = document.getElementById(`editorPanel_${t}`);
            if (!btn || !panel) return;
            const active = t === name;
            btn.classList.toggle('active', active);
            panel.style.display = active ? '' : 'none';
        });
    }

    // ─── İlerleme göstergesi ──────────────────────────────────────────────────
    function editorUpdateProgress(stats) {
        const el = document.getElementById('editorProgress');
        if (!el) return;
        if (!stats) {
            el.innerHTML = `<div style="color:#94a3b8;font-size:.85rem">Yükleniyor...</div>`;
            return;
        }
        const pct = stats.total > 0 ? Math.round((stats.reviewed / stats.total) * 100) : 0;
        el.innerHTML = `
            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">
                <span style="font-size:.85rem;font-weight:600;color:#64748b">İLERLEME</span>
                <span style="font-size:.85rem;font-weight:700;color:#6366f1">${pct}%</span>
            </div>
            <div style="height:8px;background:#e2e8f0;border-radius:99px;overflow:hidden;margin-bottom:8px">
                <div style="height:100%;width:${pct}%;background:linear-gradient(90deg,#6366f1,#818cf8);border-radius:99px;transition:width .5s ease"></div>
            </div>
            <div style="display:flex;gap:20px;font-size:.82rem;color:#94a3b8">
                <span><strong style="color:#22c55e">${stats.reviewed}</strong> incelendi</span>
                <span><strong style="color:#f97316">${stats.remaining}</strong> bekliyor</span>
                <span><strong style="color:#64748b">${stats.total}</strong> toplam</span>
            </div>`;
    }

    // ─── "Tüm sorular incelendi" ekranı ──────────────────────────────────────
    function editorShowDone() {
        const card = document.getElementById('editorQuestionCard');
        if (card) card.innerHTML = `
            <div style="text-align:center;padding:56px 16px;color:#64748b">
                <span class="material-icons-round" style="font-size:72px;color:#22c55e">check_circle</span>
                <h2 style="margin:16px 0 8px;font-size:1.5rem;color:#1e293b">Tüm sorular incelendi!</h2>
                <p style="font-size:.95rem">Havuzda bekleyen soru kalmadı.</p>
            </div>`;
        const actions = document.getElementById('editorActions');
        if (actions) actions.style.display = 'none';
    }

    // ─── Soru kartı render ────────────────────────────────────────────────────
    function editorRenderQuestion(q) {
        const card = document.getElementById('editorQuestionCard');
        if (!card) return;

        const opts = Array.isArray(q.o) ? q.o : [];
        const labels = ['A', 'B', 'C', 'D', 'E'];

        const optHtml = opts.map((o, i) => {
            const correct = q.a === i;
            return `<li class="eopt${correct ? ' correct' : ''}">
                <strong>${labels[i]})</strong> ${escHtml(o)}
            </li>`;
        }).join('');

        card.innerHTML = `
            <div style="margin-bottom:8px;color:#94a3b8;font-size:11px;font-weight:600;letter-spacing:.05em;text-transform:uppercase">${escHtml(q.id || '')}</div>
            <p style="font-size:1rem;line-height:1.7;margin-bottom:14px;color:#1e293b;font-weight:500">${escHtml(q.q || '')}</p>
            <ul style="list-style:none;padding:0;margin:0">${optHtml}</ul>
            ${q.e ? `<div class="eexplain"><strong>Açıklama:</strong> ${escHtml(q.e)}</div>` : ''}
        `;

        const actions = document.getElementById('editorActions');
        if (actions) actions.style.display = '';

        // Edit formu varsa kapat + sıfırla
        const editSection = document.getElementById('editorEditSection');
        if (editSection) editSection.style.display = 'none';
        window._editorState.editOpen = false;

        // Formu doldur
        _fillEditForm(q);
    }

    function _fillEditForm(q) {
        const fq = document.getElementById('editQ');
        const fe = document.getElementById('editE');
        if (fq) fq.value = q.q || '';
        if (fe) fe.value = q.e || '';
        const opts = Array.isArray(q.o) ? q.o : [];
        for (let i = 0; i < 5; i++) {
            const fi = document.getElementById(`editO${i}`);
            if (fi) fi.value = opts[i] || '';
        }
        const labels = ['A', 'B', 'C', 'D', 'E'];
        const fa = document.getElementById('editA');
        if (fa) {
            fa.innerHTML = labels.map((l, i) =>
                `<option value="${i}" ${q.a === i ? 'selected' : ''}>${l})</option>`
            ).join('');
        }
    }

    // ─── Sonraki soru yükle ───────────────────────────────────────────────────
    async function editorLoadNext() {
        const card = document.getElementById('editorQuestionCard');
        if (card) card.innerHTML = `<div style="text-align:center;padding:48px;color:#94a3b8">
            <span class="material-icons-round" style="font-size:42px;display:block;animation:spin 1s linear infinite">refresh</span>
            <p style="margin-top:12px;font-size:.9rem">Yükleniyor...</p>
        </div>`;

        const skipList = Array.from(window._editorSkipped).join(',');
        const url = `${EDITOR_API}/editor/next-question` + (skipList ? `?skip=${encodeURIComponent(skipList)}` : '');

        try {
            const resp = await authFetch(url);
            const data = await resp.json();

            if (data.done) {
                window._editorState.current = null;
                window._editorState.stats = data.stats || null;
                editorUpdateProgress(data.stats);
                editorShowDone();
                return;
            }

            window._editorState.current = { question: data.question, topicId: data.topicId };
            window._editorState.stats = data.stats;
            editorUpdateProgress(data.stats);
            editorRenderQuestion(data.question);
        } catch (e) {
            if (card) card.innerHTML = `<p style="color:#e74c3c;padding:16px">Hata: ${escHtml(e.message)}</p>`;
        }
    }

    // ─── İşaretle + Sonraki ──────────────────────────────────────────────────
    async function editorMarkAndNext(withEdits) {
        const cur = window._editorState.current;
        if (!cur) return;

        const body = {
            questionId: cur.question.id,
            topicId: cur.topicId
        };

        if (withEdits) {
            const fq = document.getElementById('editQ');
            const fe = document.getElementById('editE');
            const fa = document.getElementById('editA');
            const opts = [];
            for (let i = 0; i < 5; i++) {
                const fi = document.getElementById(`editO${i}`);
                opts.push(fi ? fi.value : '');
            }
            body.edits = {
                q: fq ? fq.value.trim() : undefined,
                o: opts,
                a: fa ? Number(fa.value) : undefined,
                e: fe ? fe.value.trim() : undefined
            };
        }

        try {
            const resp = await authFetch(`${EDITOR_API}/editor/mark`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body)
            });
            const data = await resp.json();
            if (!resp.ok) throw new Error(data.error || 'Kayıt hatası');
            editorToast(withEdits ? 'Düzenlendi ve işaretlendi ✓' : 'İşaretlendi ✓', 'ok');
            window._editorSkipped.delete(String(cur.question.id)); // skip listesinden çıkar
            editorLoadNext();
        } catch (e) {
            editorToast(e.message, 'err');
        }
    }

    // ─── Atla ────────────────────────────────────────────────────────────────
    function editorSkip() {
        const cur = window._editorState.current;
        if (!cur) return;
        window._editorSkipped.add(String(cur.question.id));
        editorToast('Soru atlandı', 'info');
        editorLoadNext();
    }

    // ─── Edit formu aç/kapat ──────────────────────────────────────────────────
    function editorToggleEdit() {
        const section = document.getElementById('editorEditSection');
        if (!section) return;
        window._editorState.editOpen = !window._editorState.editOpen;
        section.style.display = window._editorState.editOpen ? '' : 'none';
        const btn = document.getElementById('editorBtnEdit');
        if (btn) btn.textContent = window._editorState.editOpen ? 'Düzenlemeyi İptal Et' : 'Düzenle';
    }

    // ─── Arama ────────────────────────────────────────────────────────────────
    async function editorSearch() {
        const input = document.getElementById('editorSearchInput');
        const q = input ? input.value.trim() : '';
        if (q.length < 2) { editorToast('En az 2 karakter girin', 'err'); return; }

        const resultsEl = document.getElementById('editorSearchResults');
        if (resultsEl) resultsEl.innerHTML = '<p style="color:#999">Aranıyor...</p>';

        try {
            const resp = await authFetch(`${EDITOR_API}/editor/search?q=${encodeURIComponent(q)}`);
            const data = await resp.json();
            if (!resp.ok) throw new Error(data.error || 'Arama hatası');

            if (!resultsEl) return;
            if (!data.results.length) {
                resultsEl.innerHTML = '<p style="color:#999;padding:16px 0">Sonuç bulunamadı.</p>';
                return;
            }
            resultsEl.innerHTML = data.results.map(r => editorSearchCard(r)).join('');
        } catch (e) {
            editorToast(e.message, 'err');
        }
    }

    function editorSearchCard(r) {
        const labels = ['A', 'B', 'C', 'D', 'E'];
        const opts = Array.isArray(r.o) ? r.o : [];
        const optHtml = opts.map((o, i) => {
            const correct = r.a === i;
            return `<li class="eopt${correct ? ' correct' : ''}">
                <strong>${labels[i]})</strong> ${escHtml(o)}</li>`;
        }).join('');

        return `<div class="ecard" style="margin-bottom:12px">
            <div style="font-size:11px;color:#94a3b8;font-weight:600;letter-spacing:.05em;text-transform:uppercase;margin-bottom:8px">${escHtml(r.id || '')} — ${escHtml(r.topicId || '')}</div>
            <p style="margin:0 0 12px;line-height:1.6;color:#1e293b;font-weight:500">${escHtml(r.q || '')}</p>
            <ul style="list-style:none;padding:0;margin:0">${optHtml}</ul>
            ${r.e ? `<div class="eexplain"><strong>Açıklama:</strong> ${escHtml(r.e)}</div>` : ''}
        </div>`;
    }

    // ─── authFetch helper ─────────────────────────────────────────────────────
    function authFetch(url, options = {}) {
        const token = localStorage.getItem('adminToken');
        if (!options.headers) options.headers = {};
        if (token) options.headers['Authorization'] = `Bearer ${token}`;
        return fetch(url, options);
    }

    // ─── HTML escape ──────────────────────────────────────────────────────────
    function escHtml(str) {
        if (typeof str !== 'string') return str === undefined || str === null ? '' : String(str);
        return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
                  .replace(/"/g, '&quot;').replace(/'/g, '&#039;');
    }

    // ─── Uygulama Başlat ──────────────────────────────────────────────────────
    function initEditorApp() {
        // İlk sekmeyi göster
        editorShowTab('review');

        // İlerleme alanını hazırla
        editorUpdateProgress(null);

        // Tab butonları
        const tabReview = document.getElementById('editorTab_review');
        const tabSearch = document.getElementById('editorTab_search');
        if (tabReview) tabReview.addEventListener('click', () => editorShowTab('review'));
        if (tabSearch) tabSearch.addEventListener('click', () => editorShowTab('search'));

        // Aksiyonlar
        const btnMark = document.getElementById('editorBtnMark');
        const btnEdit = document.getElementById('editorBtnEdit');
        const btnSaveEdit = document.getElementById('editorBtnSaveEdit');
        const btnSkip = document.getElementById('editorBtnSkip');
        const btnSearch = document.getElementById('editorBtnSearch');
        const searchInput = document.getElementById('editorSearchInput');

        if (btnMark) btnMark.addEventListener('click', () => editorMarkAndNext(false));
        if (btnEdit) btnEdit.addEventListener('click', editorToggleEdit);
        if (btnSaveEdit) btnSaveEdit.addEventListener('click', () => editorMarkAndNext(true));
        if (btnSkip) btnSkip.addEventListener('click', editorSkip);
        if (btnSearch) btnSearch.addEventListener('click', editorSearch);
        if (searchInput) searchInput.addEventListener('keydown', e => { if (e.key === 'Enter') editorSearch(); });

        // İlk soruyu yükle
        editorLoadNext();
    }

    // Global erişim
    window.editorToast = editorToast;
    window.editorShowTab = editorShowTab;
    window.initEditorApp = initEditorApp;
    window.editorLoadNext = editorLoadNext;
    window.editorMarkAndNext = editorMarkAndNext;
    window.editorSkip = editorSkip;
    window.editorToggleEdit = editorToggleEdit;
    window.editorSearch = editorSearch;

})();
