window.PageDetect = {
    async runDetection() {
        UI.showPage('detect');
        UI.setLoading(true, 'Konu Analiz Ediliyor...');

        try {
            const data = await API.detectTopic(window.state.questions);
            UI.setLoading(false);

            const resultDiv = document.getElementById('aiDetectionResult');
            const confirmBtn = document.getElementById('btnConfirmTopic');

            if (data.topicId) {
                window.state.predictedTopic = data;

                // Güven rengi
                const confColor = data.confidence > 80 ? 'var(--success)' :
                    data.confidence > 50 ? 'var(--warning)' : 'var(--error)';

                resultDiv.innerHTML = `
                    <div style="font-size:1.5rem; font-weight:bold">${data.ders}</div>
                    <div style="color:var(--primary); margin-top:0.2rem; font-size:1.2rem">➜ ${data.konu}</div>
                    <div style="margin-top:0.8rem; display:flex; align-items:center; gap:0.5rem">
                         <span class="badge" style="background:${confColor}; color:#fff">%${data.confidence} Güven</span>
                         <span style="font-size:0.8rem; color:var(--text-muted)">${data.reason || 'AI tespiti'}</span>
                    </div>
                `;
                confirmBtn.style.display = 'inline-flex';
            } else {
                resultDiv.innerHTML = '<span style="color:var(--warning)">Konu tam tespit edilemedi. Lütfen manuel seçin.</span>';
                confirmBtn.style.display = 'none';
                PageDetect.showManual();
            }

        } catch (e) {
            UI.setLoading(false);
            document.getElementById('aiDetectionResult').innerText = 'Hata oluştu: ' + e.message;
        }
    },

    confirmTopic() {
        // AI tahminini kullan
        const pred = window.state.predictedTopic;
        if (!pred) return;

        // Asıl topic objesini topics listesinden bul (id eşleşmesi)
        const topicObj = window.state.topics.find(t => t.id === pred.topicId);

        if (topicObj) {
            window.state.selectedTopic = topicObj;
            PageEditor.runValidation();
        } else {
            alert('Tespit edilen konu ID sistemde bulunamadı: ' + pred.topicId);
        }
    },

    showManual() {
        document.getElementById('manualSelectDiv').style.display = 'block';
        document.getElementById('detectResultCard').style.opacity = '0.5';
        document.getElementById('detectResultCard').style.pointerEvents = 'none';
    },

    confirmManual() {
        const topicId = document.getElementById('manualTopic').value;
        if (!topicId) return alert('Lütfen bir konu seçin');

        const topicObj = window.state.topics.find(t => t.id === topicId);
        window.state.selectedTopic = topicObj;
        PageEditor.runValidation();
    }
};
