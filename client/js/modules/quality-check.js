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

    // Toast yardımcısı — global toast varsa kullan, yoksa alert
    function aaToast(msg, type = 'success') {
        const t = document.getElementById('toast');
        const m = document.getElementById('toastMessage');
        if (!t || !m) { alert(msg); return; }
        m.textContent = msg;
        t.style.background = type === 'error' ? 'var(--danger)' : type === 'warn' ? '#d97706' : 'var(--success)';
        t.classList.add('show');
        setTimeout(() => t.classList.remove('show'), 3500);
    }

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
        if (!_topicId) { renderQuestionList([]); document.getElementById('aa-bulk-btn').disabled = true; return; }
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

    // 7. kriter hariç herhangi bir kriterinde hata olan analiz edilmiş soruları toplu sil
    async function deleteErrored() {
        if (!_topicId || !_questions.length) { aaToast('Önce konu seçin', 'warn'); return; }

        const errored = _questions.filter(q =>
            q._analyzed &&
            q._analysisResult?.criteria?.some(c => c.id !== 7 && c.id !== 12 && c.hasError === true)
        );

        if (!errored.length) {
            aaToast('7. ve 12. kriter dışında hata olan soru bulunamadı ✅', 'warn');
            return;
        }

        const preview = errored.slice(0, 3).map(q => `• ${(q.q || '').substring(0, 60)}...`).join('\n');
        const ok = confirm(
            `7. ve 12. kriter dışında hata bulunan ${errored.length} soru silinecek:\n\n${preview}${errored.length > 3 ? `\n...ve ${errored.length - 3} tane daha` : ''}\n\nEmin misiniz?`
        );
        if (!ok) return;

        let deleted = 0;
        let failed = 0;
        for (const q of errored) {
            try {
                const res = await fetch(`${API()}/questions/${encodeURIComponent(_topicId)}/${encodeURIComponent(q.id)}`, { method: 'DELETE' });
                const data = await res.json();
                if (!data.success) throw new Error(data.error);
                const idx = _questions.indexOf(q);
                if (idx !== -1) _questions.splice(idx, 1);
                if (_currentQuestion === q) { _currentQuestion = null; resetContent(); }
                deleted++;
            } catch (e) {
                console.error('[deleteErrored]', q.id, e.message);
                failed++;
            }
        }

        applyFilter();
        aaToast(`🗑️ ${deleted} soru silindi${failed ? `, ${failed} hata` : ''}`, failed ? 'warn' : 'success');
        if (deleted > 0) gitPush();
    }

    // Kayıt sonrası git push
    async function gitPush() {        try {
            const res = await fetch(`${API()}/api/git-push`, { method: 'POST' });
            const data = await res.json();
            if (data.success) {
                if (data.message && !data.message.includes('atlandı')) aaToast('☁️ GitHub\'a push edildi', 'success');
            } else {
                console.warn('[git-push]', data.error);
                aaToast('⚠️ Push başarısız: ' + data.error, 'warn');
            }
        } catch (e) {
            console.warn('[git-push] network error', e.message);
        }
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
            if (typeof aaToast === 'function') aaToast('✅ Soru silindi');
            gitPush();
        } catch (e) {
            aaToast('❌ ' + e.message, 'error');
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
        if (!_currentQuestion) {
            alert('Lütfen önce bir soru seçin');
            return;
        }
        if (!_topicId) {
            alert('Konu bilgisi eksik, sayfayı yenileyin');
            return;
        }
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
            const url = `${API()}/questions/${encodeURIComponent(_topicId)}/${qId}`;
            console.log('[save] PUT', url, updatedQ);
            const res = await fetch(url, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(updatedQ)
            });
            const data = await res.json();
            console.log('[save] response', data);
            if (!data.success) throw new Error(data.error || 'Kayıt başarısız');
            const idx = _questions.indexOf(_currentQuestion);
            if (idx !== -1) { _questions[idx] = updatedQ; _currentQuestion = updatedQ; }
            // Filtre "analiz edilmemiş" ise kaydettiğimiz soru listeden çıkacak — "tümü"ne geç
            const filterSel = document.getElementById('aa-filter-select');
            if (filterSel && filterSel.value === 'unanalyzed') filterSel.value = 'all';
            applyFilter();
            aaToast('✅ Kaydedildi');
            gitPush();
        } catch (e) {
            console.error('[save] error', e);
            aaToast('❌ ' + e.message, 'error');
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

        const toAnalyze = _questions.filter(q => !q._analyzed);
        if (!toAnalyze.length) {
            aaToast('Bu konudaki tüm sorular zaten analiz edilmiş', 'warn');
            return;
        }

        // Kaç paralel worker kullanılacak? UI input'tan oku
        const workerCount = Math.max(1, parseInt(document.getElementById('aa-worker-count')?.value) || 3);

        const ok = confirm(`${toAnalyze.length} soru analiz edilecek.\n${workerCount > 1 ? `⚡ ${workerCount} API key ile paralel çalışacak` : '1 sıralı worker'}.\nDevam edilsin mi?`);
        if (!ok) return;

        _bulkRunning = true;
        _bulkStop = false;
        const model = document.getElementById('aa-model-select')?.value || 'google/gemini-3.1-flash-lite-preview';
        const total = toAnalyze.length;
        let done = 0;
        let errCount = 0;
        const queue = [...toAnalyze]; // işlenecek kuyruk

        document.getElementById('aa-bulk-progress').style.display = 'block';
        document.getElementById('aa-bulk-btn').disabled = true;
        document.getElementById('aa-stop-btn').style.display = '';
        document.getElementById('aa-analyze-btn').disabled = true;
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
            document.getElementById('aa-bulk-label').textContent = `Analiz ediliyor: ${done}/${total} (${workerCount} paralel)`;
        };
        updateProgress();

        // Her worker kuyruktaki sıradaki soruyu alıp işler
        async function worker(workerId) {
            while (queue.length > 0 && !_bulkStop) {
                const q = queue.shift();
                if (!q) break;
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

                    const updatedQ = {
                        ...q,
                        _analyzed: true,
                        _analyzedAt: new Date().toISOString(),
                        _analysisResult: { criteria: data.criteria, verdict: data.verdict, score: data.score, summary: data.summary }
                    };
                    const saveRes = await fetch(`${API()}/questions/${encodeURIComponent(_topicId)}/${encodeURIComponent(q.id)}`, {
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
                    console.error(`[worker${workerId}] hata (${q.id}):`, e.message);
                }
                updateProgress();
            }
        }

        // N worker başlat, hepsi bitene kadar bekle
        await Promise.all(
            Array.from({ length: workerCount }, (_, i) => worker(i + 1))
        );

        _bulkRunning = false;
        const filterSel = document.getElementById('aa-filter-select');
        if (filterSel) filterSel.value = 'analyzed';
        applyFilter();
        document.getElementById('aa-stop-btn').style.display = 'none';
        document.getElementById('aa-bulk-btn').disabled = false;
        document.getElementById('aa-bulk-label').textContent = _bulkStop
            ? `⏹ Durduruldu: ${done} / ${total} tamamlandı`
            : `✅ Tamamlandı: ${done - errCount} başarılı, ${errCount} hatalı`;
        aaToast(_bulkStop
            ? `⏹ Analiz durduruldu: ${done}/${total} soru işlendi`
            : `✅ Toplu analiz tamamlandı: ${done - errCount}/${total} başarılı`, _bulkStop ? 'warn' : 'success');
        if (done > errCount) gitPush();
        _bulkStop = false;
    }

    function stopBulk() {
        _bulkStop = true;
        document.getElementById('aa-stop-btn').disabled = true;
        document.getElementById('aa-stop-btn').innerHTML = '<span class="material-icons-round" style="font-size:18px">hourglass_empty</span> Durduruluyor...';
    }

    // ─── Tüm Konuları Analiz Et ─────────────────────────────────
    async function bulkAnalyzeAll() {
        if (_bulkRunning) return;

        // Kaç paralel worker kullanılacak? UI input'tan oku
        const workerCount = Math.max(1, parseInt(document.getElementById('aa-worker-count')?.value) || 3);

        // Tüm konuları yükle
        let allTopics = [];
        try {
            const res = await fetch(`${API()}/topics`);
            allTopics = await res.json();
        } catch (e) {
            aaToast('❌ Konular yüklenemedi: ' + e.message, 'error');
            return;
        }

        const model = document.getElementById('aa-model-select')?.value || 'google/gemini-3.1-flash-lite-preview';

        const ok = confirm(`${allTopics.length} konudaki tüm analiz edilmemiş sorular işlenecek.\n⚡ ${workerCount} paralel worker.\nBu işlem uzun sürebilir. Devam edilsin mi?`);
        if (!ok) return;

        _bulkRunning = true;
        _bulkStop = false;

        document.getElementById('aa-bulk-progress').style.display = 'block';
        document.getElementById('aa-stop-btn').style.display = '';
        document.getElementById('aa-stop-btn').disabled = false;
        document.getElementById('aa-stop-btn').innerHTML = '<span class="material-icons-round" style="font-size:18px">stop</span> Durdur';
        document.getElementById('aa-bulk-btn').disabled = true;

        let totalDone = 0, totalErr = 0, totalQuestions = 0;
        const labelEl = document.getElementById('aa-bulk-label');
        const barEl = document.getElementById('aa-bulk-bar');
        const pctEl = document.getElementById('aa-bulk-pct');
        const okEl = document.getElementById('aa-bulk-ok');
        const errEl = document.getElementById('aa-bulk-err');
        const remEl = document.getElementById('aa-bulk-remain');

        // Önce tüm konuların soru sayısını sayalım
        labelEl.textContent = 'Sorular yükleniyor...';

        // Büyük kuyruk: { q, topicId, topicName, topicLesson }
        const globalQueue = [];
        for (const topic of allTopics) {
            if (_bulkStop) break;
            try {
                const res = await fetch(`${API()}/questions/${encodeURIComponent(topic.id)}`);
                const qs = await res.json();
                const arr = Array.isArray(qs) ? qs : (qs.questions || []);
                const unanalyzed = arr.filter(q => !q._analyzed);
                unanalyzed.forEach(q => globalQueue.push({ q, topicId: topic.id, topicName: topic.name, topicLesson: topic.lesson }));
            } catch {}
        }

        totalQuestions = globalQueue.length;
        if (!totalQuestions) {
            aaToast('✅ Tüm konulardaki sorular zaten analiz edilmiş', 'warn');
            _bulkRunning = false;
            document.getElementById('aa-stop-btn').style.display = 'none';
            document.getElementById('aa-bulk-btn').disabled = false;
            return;
        }

        labelEl.textContent = `${totalQuestions} soru bulundu, analiz başlıyor (${workerCount} worker)...`;
        barEl.style.width = '0%'; pctEl.textContent = '0%';
        okEl.textContent = '0'; errEl.textContent = '0'; remEl.textContent = totalQuestions;

        const updateProg = () => {
            const pct = Math.round((totalDone / totalQuestions) * 100);
            barEl.style.width = pct + '%';
            pctEl.textContent = pct + '%';
            okEl.textContent = totalDone - totalErr;
            errEl.textContent = totalErr;
            remEl.textContent = totalQuestions - totalDone;
        };

        async function allTopicsWorker(wid) {
            while (globalQueue.length > 0 && !_bulkStop) {
                const item = globalQueue.shift();
                if (!item) break;
                const { q, topicId, topicName, topicLesson } = item;
                labelEl.textContent = `[${wid}] ${topicName}: ${(q.q || '').substring(0, 50)}...`;
                try {
                    const res = await fetch(`${API()}/api/ai/deep-analyze`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ question: q, topicInfo: { name: topicName, lesson: topicLesson }, model })
                    });
                    const data = await res.json();
                    if (!data.success) throw new Error(data.error);
                    const updatedQ = { ...q, _analyzed: true, _analyzedAt: new Date().toISOString(), _analysisResult: { criteria: data.criteria, verdict: data.verdict, score: data.score, summary: data.summary } };
                    const saveRes = await fetch(`${API()}/questions/${encodeURIComponent(topicId)}/${encodeURIComponent(q.id)}`, {
                        method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(updatedQ)
                    });
                    if (!(await saveRes.json()).success) throw new Error('Kayıt başarısız');
                    // Eğer o an açık konu buysa memory'de güncelle
                    if (topicId === _topicId) {
                        const idx = _questions.findIndex(x => x.id === q.id);
                        if (idx !== -1) _questions[idx] = updatedQ;
                    }
                    totalDone++;
                } catch (e) {
                    totalErr++; totalDone++;
                    console.error(`[allWorker${wid}] ${topicId}/${q.id}:`, e.message);
                }
                updateProg();
            }
        }

        await Promise.all(Array.from({ length: workerCount }, (_, i) => allTopicsWorker(i + 1)));

        _bulkRunning = false;
        if (_topicId) applyFilter();
        document.getElementById('aa-stop-btn').style.display = 'none';
        document.getElementById('aa-bulk-btn').disabled = false;
        labelEl.textContent = _bulkStop
            ? `⏹ Durduruldu: ${totalDone}/${totalQuestions} tamamlandı`
            : `✅ Tüm konular tamamlandı: ${totalDone - totalErr} başarılı, ${totalErr} hatalı`;
        aaToast(_bulkStop
            ? `⏹ Durduruldu: ${totalDone}/${totalQuestions}`
            : `✅ ${totalDone - totalErr}/${totalQuestions} soru analiz edildi`, _bulkStop ? 'warn' : 'success');
        if (totalDone > totalErr) gitPush();
        _bulkStop = false;
    }

    return { init, loadTopics, onTopicChange, onFilterChange, onQuestionChange, onSearchInput, selectQuestion, deleteQuestion, deleteErrored, analyze, save, nextQuestion, fillEditor, bulkAnalyze, bulkAnalyzeAll, stopBulk };
})();

