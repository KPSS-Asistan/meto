/* === modules\explanations.js === */

/**
 * Explanations Module
 * Açıklama dosyaları için CRUD işlemleri
 */

// Global variables
let currentExplanationFile = null;
let explanationData = [];

// Initialize explanations module
function initExplanations() {
    loadExplanationFiles();
}

// Load explanation files list
async function loadExplanationFiles() {
    try {
        const response = await fetch('/explanations');
        const data = await response.json();

        if (data.success) {
            const select = document.getElementById('explanationFile');
            select.innerHTML = '<option value="">Dosya seçin...</option>';

            data.explanations.forEach(file => {
                const option = document.createElement('option');
                option.value = file.filename;
                option.textContent = `${file.title || file.id} (${file.count} açıklama)`;
                select.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Açıklama dosyaları yüklenemedi:', error);
    }
}

// Load specific explanation file
async function loadExplanationFile() {
    const select = document.getElementById('explanationFile');
    const filename = select.value;

    if (!filename) {
        document.getElementById('explanationEditor').value = '';
        currentExplanationFile = null;
        explanationData = [];
        return;
    }

    try {
        const response = await fetch(`/explanations/${filename}`);
        const data = await response.json();

        if (data.success) {
            currentExplanationFile = filename;
            explanationData = data.explanations;
            document.getElementById('explanationEditor').value = JSON.stringify(data.explanations, null, 2);
        }
    } catch (error) {
        console.error('Açıklama dosyası yüklenemedi:', error);
        showToast('Açıklama dosyası yüklenemedi', 'error');
    }
}

// Save explanations - Save the entire array instead of just the last item
async function saveExplanations() {
    if (!currentExplanationFile) {
        showToast('Önce bir açıklama dosyası seçin', 'warning');
        return;
    }

    const editor = document.getElementById('explanationEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const explanations = JSON.parse(jsonText);

        // Validate structure
        if (!Array.isArray(explanations)) {
            showToast('Açıklama verisi bir dizi olmalı', 'error');
            return;
        }

        for (let i = 0; i < explanations.length; i++) {
            const explanation = explanations[i];
            if (!explanation.topicId || !explanation.title || !explanation.content) {
                showToast(`Açıklama ${i + 1}: topicId, title ve content alanları zorunlu`, 'error');
                return;
            }
        }

        // Save entire array to server using PUT endpoint
        const response = await fetch(`/explanations/${currentExplanationFile}/save`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ explanations })
        });

        const data = await response.json();

        if (data.success) {
            showToast('Açıklamalar kaydedildi', 'success');
            explanationData = explanations;
            // Refresh file list to show updated count
            loadExplanationFiles();
        } else {
            showToast(data.error || 'Kayıt başarısız', 'error');
        }
    } catch (error) {
        if (error instanceof SyntaxError) {
            showToast('Geçersiz JSON formatı', 'error');
        } else {
            console.error('Kayıt hatası:', error);
            showToast('Kayıt başarısız', 'error');
        }
    }
}

// Validate explanations
function validateExplanations() {
    const editor = document.getElementById('explanationEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const explanations = JSON.parse(jsonText);

        if (!Array.isArray(explanations)) {
            showToast('Açıklama verisi bir dizi olmalı', 'error');
            return;
        }

        let errors = [];
        let warnings = [];

        explanations.forEach((explanation, index) => {
            if (!explanation.topicId) {
                errors.push(`Açıklama ${index + 1}: topicId alanı eksik`);
            }
            if (!explanation.title) {
                errors.push(`Açıklama ${index + 1}: title alanı eksik`);
            }
            if (!explanation.content) {
                errors.push(`Açıklama ${index + 1}: content alanı eksik`);
            }
            if (explanation.title && explanation.title.length < 5) {
                warnings.push(`Açıklama ${index + 1}: title çok kısa`);
            }
            if (explanation.content && explanation.content.length < 20) {
                warnings.push(`Açıklama ${index + 1}: content çok kısa`);
            }
            if (explanation.type && !['general', 'detailed', 'summary'].includes(explanation.type)) {
                warnings.push(`Açıklama ${index + 1}: geçersiz type`);
            }
            if (explanation.difficulty && !['easy', 'medium', 'hard'].includes(explanation.difficulty)) {
                warnings.push(`Açıklama ${index + 1}: geçersiz difficulty`);
            }
        });

        if (errors.length > 0) {
            showToast('Hatalar: ' + errors.join(', '), 'error');
        } else if (warnings.length > 0) {
            showToast('Uyarılar: ' + warnings.join(', '), 'warning');
        } else {
            showToast('Tüm açıklamalar geçerli', 'success');
        }
    } catch (error) {
        if (error instanceof SyntaxError) {
            showToast('Geçersiz JSON formatı', 'error');
        } else {
            showToast('Doğrulama hatası', 'error');
        }
    }
}

// Export functions for global use
window.initExplanations = initExplanations;
window.loadExplanationFiles = loadExplanationFiles;
window.loadExplanationFile = loadExplanationFile;
window.saveExplanations = saveExplanations;
window.validateExplanations = validateExplanations;


