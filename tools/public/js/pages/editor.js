window.PageEditor = {
    async runValidation() {
        UI.showPage('editor');
        UI.setLoading(true, 'Sorular Denetleniyor...');

        try {
            const res = await API.validate(window.state.selectedTopic.id, window.state.questions);
            window.state.validationResult = res;
            this.render();
            UI.setLoading(false);
        } catch (e) {
            UI.setLoading(false);
            alert('Validasyon hatası: ' + e.message);
        }
    },

    render() {
        const list = document.getElementById('questionList');
        list.innerHTML = '';

        const results = window.state.validationResult.results;
        let validCount = 0;
        let errorCount = 0;

        results.forEach((item, idx) => {
            const isValid = item.status === 'valid';
            if (isValid) validCount++; else errorCount++;

            const div = document.createElement('div');
            div.className = `question-card ${isValid ? 'valid' : 'error'}`;

            // Header
            let headerHtml = `
                <div style="display:flex; justify-content:space-between; margin-bottom:0.8rem; align-items:center;">
                    <span style="font-weight:bold; color:var(--text-muted)">#${idx + 1}</span>
                    <div style="display:flex; gap:0.5rem">
                        ${!isValid ?
                    `<button class="btn btn-outline" style="font-size:0.75rem; padding:0.3rem 0.6rem" onclick="PageEditor.fixWithAi(${idx})">🪄 Düzelt</button>` :
                    '<span class="badge badge-success">✓ Hazır</span>'}
                         <button class="btn btn-outline" style="font-size:0.75rem; padding:0.3rem" onclick="PageEditor.deleteQuestion(${idx})">🗑️</button>
                    </div>
                </div>
            `;

            // Errors
            let errorsHtml = '';
            if (!isValid) {
                errorsHtml = `<div style="margin-bottom:0.8rem; background:rgba(239,68,68,0.1); padding:0.5rem; border-radius:6px;">
                    ${item.errors.map(e => `<div style="color:var(--error); font-size:0.8rem; margin-bottom:0.2rem">⚠️ ${e.msg}</div>`).join('')}
                </div>`;
            }

            // Inputs
            const q = window.state.questions[idx];
            let inputsHtml = `
                <div style="margin-bottom:0.5rem">
                    <label style="font-size:0.7rem; color:var(--text-muted)">SORU METNİ</label>
                    <textarea rows="2" onchange="PageEditor.update(${idx}, 'q', this.value)">${q.q || ''}</textarea>
                </div>
                
                <div style="margin-bottom:0.5rem">
                    <label style="font-size:0.7rem; color:var(--text-muted)">SEÇENEKLER (Doğru şıkkı seçin)</label>
                    <div style="display:grid; gap:0.3rem;">
                        ${[0, 1, 2, 3, 4].map(i => `
                            <div style="display:flex; gap:0.5rem; align-items:center">
                                <input type="radio" name="q${idx}_ans" ${q.a === i ? 'checked' : ''} 
                                       onchange="PageEditor.update(${idx}, 'a', ${i})" style="width:20px; margin:0">
                                <input type="text" value="${q.o?.[i] || ''}" style="margin:0"
                                       onchange="PageEditor.updateOption(${idx}, ${i}, this.value)">
                            </div>
                        `).join('')}
                    </div>
                </div>

                <div style="margin-top:0.5rem">
                     <label style="font-size:0.7rem; color:var(--text-muted)">AÇIKLAMA (Opsiyonel)</label>
                     <textarea rows="1" onchange="PageEditor.update(${idx}, 'e', this.value)">${q.e || ''}</textarea>
                </div>
            `;

            div.innerHTML = headerHtml + errorsHtml + inputsHtml;
            list.appendChild(div);
        });

        // Stats Update
        document.getElementById('statTotal').innerText = results.length + ' Toplam';
        document.getElementById('statError').innerText = errorCount + ' Hata';

        const exportBtn = document.getElementById('btnGoToExport');
        if (errorCount === 0 && results.length > 0) {
            exportBtn.disabled = false;
            exportBtn.className = 'btn btn-success';
            exportBtn.innerHTML = 'Her Şey Hazır ➔ Kaydet';
        } else {
            exportBtn.disabled = true;
            exportBtn.className = 'btn btn-outline';
            exportBtn.innerHTML = errorCount > 0 ? `${errorCount} Hatayı Düzeltin` : 'Soru Yok';
        }
    },

    update(idx, field, val) {
        window.state.questions[idx][field] = val;
    },

    updateOption(qIdx, oIdx, val) {
        if (!window.state.questions[qIdx].o) window.state.questions[qIdx].o = [];
        window.state.questions[qIdx].o[oIdx] = val;
    },

    deleteQuestion(idx) {
        if (confirm('Silmek istiyor musunuz?')) {
            window.state.questions.splice(idx, 1);
            this.runValidation();
        }
    },

    async fixWithAi(idx) {
        UI.setLoading(true, 'Soru Düzeltiliyor...');
        const q = window.state.questions[idx];
        const errors = window.state.validationResult.results[idx].errors;

        try {
            const fixed = await API.fixQuestion(q, errors);
            if (fixed) {
                window.state.questions[idx] = fixed;
                await this.runValidation();
            } else {
                throw new Error('AI düzeltme yapamadı');
            }
        } catch (e) {
            UI.setLoading(false);
            alert('AI Fix hatası: ' + e.message);
        }
    },

    async autoFixAll() {
        const errors = window.state.validationResult.results
            .map((r, i) => ({ idx: i, status: r.status, errors: r.errors }))
            .filter(r => r.status !== 'valid');

        if (errors.length === 0) return alert('Düzeltilecek hata yok!');
        if (errors.length > 5) return alert('Çok fazla hata var, lütfen tek tek düzeltin.');

        if (!confirm(`${errors.length} soruyu AI ile düzeltmek istiyor musunuz?`)) return;

        for (const item of errors) {
            await this.fixWithAi(item.idx);
        }
    }
};
