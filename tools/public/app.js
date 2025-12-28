// GLOBAL CONFIG
if (typeof API === 'undefined') {
    window.API = window.API_URL || 'http://localhost:3456';
}

function showToast(msg, type = 'success') {
    const t = document.getElementById('toast');
    if (!t) return;
    t.innerHTML = msg;
    t.style.borderLeftColor = type === 'error' ? '#ef4444' : '#22c55e';
    t.style.display = 'block';
    setTimeout(() => t.style.display = 'none', 5000);
}

// ══════════════════════════════════════════════════════════════════════════
// DASHBOARD
// ══════════════════════════════════════════════════════════════════════════
async function loadStats() {
    try {
        const res = await fetch(API + '/stats');
        const data = await res.json();
        const el = (id, v) => { if (document.getElementById(id)) document.getElementById(id).innerText = v; };

        el('statTotal', data.totalQuestions || 0);
        el('statTopics', data.totalTopics || 0);
        el('statMissing', data.missingExplanations || 0);
        const q = Math.round(((data.totalQuestions || 1 - (data.missingExplanations || 0)) / (data.totalQuestions || 1)) * 100);
        el('statQuality', `%${q}`);

        const list = document.getElementById('lessonStats');
        if (list && data.byLesson) {
            list.innerHTML = Object.keys(data.byLesson).sort().map(l => `
                <div style="background:var(--input-bg); padding:1rem; border-radius:8px; display:flex; justify-content:space-between; align-items:center">
                    <span style="font-weight:600">${l}</span>
                    <span style="background:rgba(99,102,241,0.1); color:var(--accent); padding:2px 8px; border-radius:4px; font-size:0.8rem; font-weight:bold">${data.byLesson[l].count} Soru</span>
                </div>
             `).join('');
        }
    } catch (e) { }
}

// ══════════════════════════════════════════════════════════════════════════
// SMART SYNC & CONFIG
// ══════════════════════════════════════════════════════════════════════════
async function checkGitStatus() {
    try {
        const res = await fetch(API + '/git/status');
        const data = await res.json();
        if (document.getElementById('gitBranch')) document.getElementById('gitBranch').innerText = data.branch;

        const remoteInfo = document.getElementById('gitRemoteInfo');
        if (remoteInfo) remoteInfo.innerText = data.remote || 'Ayarlanmamış';

        const list = document.getElementById('gitStatusList');
        if (!list) return;

        if (data.changes.length === 0) {
            list.innerHTML = `
                <div style="text-align:center; margin-top:3rem; color:var(--text-muted); opacity:0.6">
                    <span class="material-icons-round" style="font-size:3rem">check_circle</span>
                    <p>Her şey güncel!</p>
                </div>`;
            updateSyncBtn('idle');
        } else {
            updateSyncBtn('ready');
            list.innerHTML = data.changes.map(c => {
                const type = c.trim().substring(0, 2).trim();
                const rawFile = c.trim().substring(2).trim();
                const fileName = rawFile.split('/').pop().replace('.json', '');

                let badgeClass = 'badge-mod';
                let icon = 'edit_note';
                if (type.includes('?')) { badgeClass = 'badge-new'; icon = 'note_add'; }
                if (type.includes('D')) { badgeClass = 'badge-mod'; icon = 'delete'; }

                return `
                <div class="file-item">
                    <div class="file-icon"><span class="material-icons-round" style="font-size:1.2rem">${icon}</span></div>
                    <div class="file-name">${fileName}</div>
                    <div class="file-badge ${badgeClass}">${type}</div>
                </div>`
            }).join('');
        }
    } catch (e) { console.error(e); }
}

async function configureGit() {
    const current = document.getElementById('gitRemoteInfo')?.innerText || '';
    const newUrl = prompt("Yeni GitHub Repository URL'ini girin:", current);

    if (!newUrl || newUrl === current) return;

    try {
        const res = await fetch(API + '/git/set-remote', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ url: newUrl })
        });
        const data = await res.json();
        if (data.success) {
            showToast('Remote URL güncellendi!', 'success');
            checkGitStatus();
        } else {
            showToast('Hata: ' + data.error, 'error');
        }
    } catch (e) { showToast('Ayarlama hatası', 'error'); }
}

async function smartSync() {
    const btn = document.getElementById('syncBtn');
    if (btn.classList.contains('loading')) return;

    updateSyncBtn('loading');

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

        updateSyncBtn('ready');
    }
}

function updateSyncBtn(state) {
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
}

// ══════════════════════════════════════════════════════════════════════════
// DATA LOGIC
// ══════════════════════════════════════════════════════════════════════════
async function loadAddTopics() {
    const res = await fetch(API + '/topics');
    const topics = await res.json();
    const sel = document.getElementById('addTopicSelect');
    if (sel) {
        sel.innerHTML = '<option value="">Konu Seçin...</option>';
        topics.forEach(t => { sel.innerHTML += `<option value="${t.id}">${t.name} (${t.lesson})</option>`; });
    }
}

async function addQuestion() {
    const topicId = document.getElementById('addTopicSelect').value;
    if (!topicId) return showToast('Lütfen konu seçin', 'error');

    const question = {
        subtopic: document.getElementById('addSubtopic').value,
        q: document.getElementById('addQuestionText').value,
        o: [
            document.getElementById('opt0').value, document.getElementById('opt1').value,
            document.getElementById('opt2').value, document.getElementById('opt3').value,
            document.getElementById('opt4').value
        ],
        a: parseInt(document.getElementById('addCorrectAns').value),
        e: document.getElementById('addExplanation').value
    };

    if (!question.q) return showToast('Soru metni boş', 'error');

    try {
        const res = await fetch(API + '/add', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ topicId, questions: [question] })
        });
        const data = await res.json();
        if (data.success) {
            showToast('Soru kaydedildi!', 'success');
            document.getElementById('addQuestionText').value = '';
            document.getElementById('addExplanation').value = '';
        }
    } catch (e) { showToast('Hata', 'error'); }
}

async function searchQuestions() {
    const q = document.getElementById('searchInput').value;
    if (q.length < 3) return;
    try {
        const res = await fetch(API + `/search?q=${encodeURIComponent(q)}`);
        const data = await res.json();
        renderList(data.results, null);
    } catch (e) { }
}

async function loadBrowseTopics() { /* ... */ }
async function loadBrowseQuestions() { /* ... */ }

function renderList(questions, topicId) {
    const list = document.getElementById('browseList');
    list.innerHTML = `<div style="margin-bottom:1rem;color:var(--text-muted)">${questions.length} sonuç</div>`;
    questions.forEach(q => {
        list.innerHTML += `
        <div class="card" style="margin-bottom:1rem; padding:1rem">
            <div style="display:flex; justify-content:space-between; margin-bottom:0.5rem">
                 <span style="font-weight:bold; color:var(--accent)">${q.subtopic || 'Genel'}</span>
                 <button style="color:#ef4444; background:none; border:none; cursor:pointer" onclick="deleteQuestion('${q.topicId || topicId}', '${q.id}')">Sil</button>
            </div>
            <p>${q.q}</p>
        </div>`;
    });
}

async function deleteQuestion(tid, qid) {
    if (!confirm('Silinsin mi?')) return;
    await fetch(API + `/questions/${tid}/${qid}`, { method: 'DELETE' });
    showToast('Silindi', 'success');
}
