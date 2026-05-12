/* === modules\flashcards.js === */

/**
 * Flashcards Module
 * Flashcard setleri için CRUD işlemleri
 */

// Global variables
let currentFlashcardFile = null;
let flashcardData = [];

// Initialize flashcards module
function initFlashcards() {
    loadFlashcardFiles();
}

// Load flashcard files list
async function loadFlashcardFiles() {
    try {
        const response = await fetch(API + '/flashcards');
        const data = await response.json();

        console.log('[Flashcards] Response:', data);

        if (data.success) {
            const select = document.getElementById('flashcardFile');
            select.innerHTML = '<option value="">Set seçin...</option>';

            console.log('[Flashcards] Files to add:', data.flashcards.length);
            data.flashcards.forEach(file => {
                const option = document.createElement('option');
                option.value = file.filename;
                option.textContent = `${file.title || file.id} (${file.count} kart)`;
                select.appendChild(option);
                console.log('[Flashcards] Added:', file.title || file.id);
            });
        }
    } catch (error) {
        console.error('Flashcard dosyaları yüklenemedi:', error);
    }
}

// Load specific flashcard file
async function loadFlashcardFile() {
    const select = document.getElementById('flashcardFile');
    const filename = select.value;

    if (!filename) {
        document.getElementById('flashcardEditor').value = '';
        currentFlashcardFile = null;
        flashcardData = [];
        return;
    }

    try {
        const response = await fetch(API + `/flashcards/${filename}`);
        const data = await response.json();

        if (data.success) {
            currentFlashcardFile = filename;
            flashcardData = data.cards;
            document.getElementById('flashcardEditor').value = JSON.stringify(data.cards, null, 2);
        }
    } catch (error) {
        console.error('Flashcard dosyası yüklenemedi:', error);
        showToast('Flashcard dosyası yüklenemedi', 'error');
    }
}

// Save flashcards - Save the entire array
async function saveFlashcards() {
    if (!currentFlashcardFile) {
        showToast('Önce bir flashcard seti seçin', 'warning');
        return;
    }

    const editor = document.getElementById('flashcardEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const cards = JSON.parse(jsonText);

        // Validate structure
        if (!Array.isArray(cards)) {
            showToast('Flashcard verisi bir dizi olmalı', 'error');
            return;
        }

        for (let i = 0; i < cards.length; i++) {
            const card = cards[i];
            if (!card.question || !card.answer) {
                showToast(`Kart ${i + 1}: question ve answer alanları zorunlu`, 'error');
                return;
            }
        }

        // Save entire array to server
        const response = await fetch(API + `/flashcards/${currentFlashcardFile}/save`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ cards })
        });

        const data = await response.json();

        if (data.success) {
            showToast('Flashcards kaydedildi', 'success');
            flashcardData = cards;
            // Refresh file list
            loadFlashcardFiles();
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

// Validate flashcards
function validateFlashcards() {
    const editor = document.getElementById('flashcardEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const cards = JSON.parse(jsonText);

        if (!Array.isArray(cards)) {
            showToast('Flashcard verisi bir dizi olmalı', 'error');
            return;
        }

        let errors = [];
        let warnings = [];

        cards.forEach((card, index) => {
            if (!card.question) {
                errors.push(`Kart ${index + 1}: question alanı eksik`);
            }
            if (!card.answer) {
                errors.push(`Kart ${index + 1}: answer alanı eksik`);
            }
            if (card.question && card.question.length < 3) {
                warnings.push(`Kart ${index + 1}: question çok kısa`);
            }
            if (card.answer && card.answer.length < 3) {
                warnings.push(`Kart ${index + 1}: answer çok kısa`);
            }
        });

        if (errors.length > 0) {
            showToast('Hatalar: ' + errors.join(', '), 'error');
        } else if (warnings.length > 0) {
            showToast('Uyarılar: ' + warnings.join(', '), 'warning');
        } else {
            showToast('Tüm flashcard\'lar geçerli', 'success');
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
window.initFlashcards = initFlashcards;
window.loadFlashcardFiles = loadFlashcardFiles;
window.loadFlashcardFile = loadFlashcardFile;
window.saveFlashcards = saveFlashcards;
window.validateFlashcards = validateFlashcards;


