/* === modules\stories.js === */

/**
 * Stories Module
 * Hikaye dosyaları için CRUD işlemleri
 */

// Global variables
let currentStoryFile = null;
let storyData = [];

// Initialize stories module
function initStories() {
    loadStoryFiles();
}

// Load story files list
async function loadStoryFiles() {
    try {
        const response = await fetch('/stories');
        const data = await response.json();

        if (data.success) {
            const select = document.getElementById('storyFile');
            select.innerHTML = '<option value="">Dosya seçin...</option>';

            data.stories.forEach(file => {
                const option = document.createElement('option');
                option.value = file.filename;
                option.textContent = `${file.title || file.id} (${file.count} hikaye)`;
                select.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Hikaye dosyaları yüklenemedi:', error);
    }
}

// Load specific story file
async function loadStoryFile() {
    const select = document.getElementById('storyFile');
    const filename = select.value;

    if (!filename) {
        document.getElementById('storyEditor').value = '';
        currentStoryFile = null;
        storyData = [];
        return;
    }

    try {
        const response = await fetch(`/stories/${filename}`);
        const data = await response.json();

        if (data.success) {
            currentStoryFile = filename;
            storyData = data.stories;
            document.getElementById('storyEditor').value = JSON.stringify(data.stories, null, 2);
        }
    } catch (error) {
        console.error('Hikaye dosyası yüklenemedi:', error);
        showToast('Hikaye dosyası yüklenemedi', 'error');
    }
}

// Save stories - Save the entire array
async function saveStories() {
    if (!currentStoryFile) {
        showToast('Önce bir hikaye dosyası seçin', 'warning');
        return;
    }

    const editor = document.getElementById('storyEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const stories = JSON.parse(jsonText);

        // Validate structure
        if (!Array.isArray(stories)) {
            showToast('Hikaye verisi bir dizi olmalı', 'error');
            return;
        }

        for (let i = 0; i < stories.length; i++) {
            const story = stories[i];
            if (!story.title || !story.content) {
                showToast(`Hikaye ${i + 1}: title ve content alanları zorunlu`, 'error');
                return;
            }
        }

        // Save entire array to server
        const response = await fetch(`/stories/${currentStoryFile}/save`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ stories })
        });

        const data = await response.json();

        if (data.success) {
            showToast('Hikayeler kaydedildi', 'success');
            storyData = stories;
            // Refresh file list
            loadStoryFiles();
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

// Validate stories
function validateStories() {
    const editor = document.getElementById('storyEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const stories = JSON.parse(jsonText);

        if (!Array.isArray(stories)) {
            showToast('Hikaye verisi bir dizi olmalı', 'error');
            return;
        }

        let errors = [];
        let warnings = [];

        stories.forEach((story, index) => {
            if (!story.title) {
                errors.push(`Hikaye ${index + 1}: title alanı eksik`);
            }
            if (!story.content) {
                errors.push(`Hikaye ${index + 1}: content alanı eksik`);
            }
            if (story.title && story.title.length < 5) {
                warnings.push(`Hikaye ${index + 1}: title çok kısa`);
            }
            if (story.content && story.content.length < 50) {
                warnings.push(`Hikaye ${index + 1}: content çok kısa`);
            }
            if (story.keyPoints && !Array.isArray(story.keyPoints)) {
                errors.push(`Hikaye ${index + 1}: keyPoints bir dizi olmalı`);
            }
        });

        if (errors.length > 0) {
            showToast('Hatalar: ' + errors.join(', '), 'error');
        } else if (warnings.length > 0) {
            showToast('Uyarılar: ' + warnings.join(', '), 'warning');
        } else {
            showToast('Tüm hikayeler geçerli', 'success');
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
window.initStories = initStories;
window.loadStoryFiles = loadStoryFiles;
window.loadStoryFile = loadStoryFile;
window.saveStories = saveStories;
window.validateStories = validateStories;


