window.PageInput = {
    setMode(mode) {
        document.getElementById('mode-paste').style.display = mode === 'paste' ? 'block' : 'none';
        document.getElementById('mode-ai').style.display = mode === 'ai' ? 'block' : 'none';

        document.getElementById('btnPaste').className = mode === 'paste' ? 'btn btn-primary' : 'btn btn-outline';
        document.getElementById('btnAi').className = mode === 'ai' ? 'btn btn-primary' : 'btn btn-outline';
    },

    async processPaste() {
        const raw = document.getElementById('inputText').value;
        if (!raw.trim()) return alert('Lütfen içerik girin!');

        try {
            // Basit temizlik
            let clean = raw.trim();
            if (!clean.startsWith('[')) clean = '[' + clean + ']'; // Tek obje ise array yap

            const parsed = JSON.parse(clean);
            if (!Array.isArray(parsed) && typeof parsed === 'object') {
                window.state.questions = [parsed];
            } else if (Array.isArray(parsed)) {
                window.state.questions = parsed;
            } else {
                throw new Error('Geçersiz format');
            }

            // Go to Detect
            await PageDetect.runDetection();
        } catch (e) {
            alert('JSON Hatası: ' + e.message + '\n\n Lütfen geçerli bir JSON array yapıştırın.');
        }
    },

    async startAiGeneration() {
        const ctx = document.getElementById('aiContext').value;
        const cnt = document.getElementById('aiCount').value;
        const lesson = document.getElementById('aiLessonSelect').value;

        if (!lesson) return alert('Lütfen bir ders seçin!');
        if (!ctx) return alert('Lütfen konu detayı girin!');

        UI.setLoading(true, 'Yapay Zeka Soruları Üretiyor...');
        try {
            const data = await API.generateQuestions(lesson, ctx, parseInt(cnt));

            if (data.error) throw new Error(data.error);
            if (!data.questions || data.questions.length === 0) throw new Error('Soru üretilemedi.');

            window.state.questions = data.questions;

            // Generate sonrası direkt detect'e git
            await PageDetect.runDetection();
        } catch (e) {
            alert('AI Hatası: ' + e.message);
            UI.setLoading(false);
        }
    }
};
