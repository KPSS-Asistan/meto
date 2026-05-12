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

        // İnceleme istatistiği
        if (data.totalQuestions > 0 && data.reviewedQuestions !== undefined) {
            const pct = Math.round((data.reviewedQuestions / data.totalQuestions) * 100);
            el('statReviewed', `${data.reviewedQuestions} / ${data.totalQuestions}`);
            const bar = document.getElementById('statReviewedBar');
            if (bar) bar.style.width = pct + '%';
            const pctEl = document.getElementById('statReviewedPct');
            if (pctEl) pctEl.textContent = pct + '%';
        }

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


