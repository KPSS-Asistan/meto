// GLOBAL STATE
window.state = {
    questions: [],
    topics: [],
    selectedTopic: null,
    predictedTopic: null,
    validationResult: null
};

// INITIALIZATION
document.addEventListener('DOMContentLoaded', async () => {
    try {
        window.state.topics = await API.getTopics();
        populateTopicSelects();
        UI.showPage('input');

        // Check server status
        document.getElementById('serverStatus').innerText = 'Online';
    } catch (e) {
        document.getElementById('serverStatus').innerText = 'Offline';
        document.getElementById('serverStatus').style.color = 'var(--error)';
        alert('Sunucuya bağlanılamadı! Lütfen "node question_server.js" komutunu çalıştırın.');
    }
});

// ROUTER & NAVIGATION
window.UI = {
    showPage(pageId) {
        // Hide all pages
        document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
        document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));

        // Show target page
        const targetPage = document.getElementById(`page-${pageId}`);
        if (targetPage) targetPage.classList.add('active');

        // Update sidebar
        const navMap = {
            'input': 0,
            'detect': 1,
            'editor': 2,
            'export': 3
        };
        const navItems = document.querySelectorAll('.sidebar .nav-item');
        if (navItems[navMap[pageId]]) navItems[navMap[pageId]].classList.add('active');

        // Page specific init logic
        if (pageId === 'editor') renderEditor();
        if (pageId === 'export') prepareExport();
    },

    setLoading(active, text = 'İşleniyor...') {
        const el = document.getElementById('loadingOverlay');
        const txt = document.getElementById('loadingText');
        if (active) {
            txt.innerText = text;
            el.style.display = 'flex';
        } else {
            el.style.display = 'none';
        }
    }
};

// HELPER: Populate Selects
function populateTopicSelects() {
    const lessons = [...new Set(window.state.topics.map(t => t.lesson))];
    const selects = ['aiLessonSelect', 'manualLesson'];

    selects.forEach(id => {
        const el = document.getElementById(id);
        if (!el) return;
        el.innerHTML = '<option value="">Ders Seçin</option>';
        lessons.forEach(l => {
            el.innerHTML += `<option value="${l}">${l}</option>`;
        });
    });
}

// Global functions for HTML event handlers
window.filterTopics = (lesson, targetSelectId = 'manualTopic') => {
    const target = document.getElementById(targetSelectId);
    target.innerHTML = '<option value="">Konu Seçin</option>';

    window.state.topics
        .filter(t => t.lesson === lesson)
        .forEach(t => {
            target.innerHTML += `<option value="${t.id}">${t.name}</option>`;
        });
};
