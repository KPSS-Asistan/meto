window.PageExport = {
    prepare() {
        const count = window.state.questions.length;
        const topicName = window.state.selectedTopic ? window.state.selectedTopic.name : '???';

        document.getElementById('finalCount').textContent = count;
        document.getElementById('finalTopic').textContent = topicName;
    },

    async save() {
        UI.setLoading(true, 'Dosyaya Yazılıyor...');
        try {
            const res = await API.saveToFile(window.state.selectedTopic.id, window.state.questions);
            UI.setLoading(false);

            if (res.success) {
                // Success UI
                document.getElementById('page-export').innerHTML = `
                    <div class="card" style="text-align:center; padding:4rem">
                        <div style="font-size:4rem; margin-bottom:1rem">✅</div>
                        <h2>Başarıyla Kaydedildi!</h2>
                        <p style="color:var(--text-muted); margin-bottom:2rem">${res.message}</p>
                        <button class="btn btn-primary" onclick="location.reload()">Yeni İşlem Başlat</button>
                    </div>
                `;
            } else {
                alert('Kaydedilemedi: ' + res.message);
            }
        } catch (e) {
            UI.setLoading(false);
            alert('Kayıt hatası: ' + e.message);
        }
    }
};

// Hook into router (app.js calls prepareExport if it exists)
window.prepareExport = window.PageExport.prepare;
window.saveToFile = window.PageExport.save; // HTML onclick için global yaptık
