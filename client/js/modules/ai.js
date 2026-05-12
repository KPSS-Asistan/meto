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


