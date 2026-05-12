/* === modules\matching_games.js === */

/**
 * Matching Games Module
 * Eşleştirme oyunları için CRUD işlemleri
 */

// Global variables
let currentMatchingGameFile = null;
let matchingGameData = [];

// Initialize matching games module
function initMatchingGames() {
    loadMatchingGameFiles();
}

// Load matching game files list
async function loadMatchingGameFiles() {
    try {
        const response = await fetch('/matching-games');
        const data = await response.json();

        if (data.success) {
            const select = document.getElementById('matchingGameFile');
            select.innerHTML = '<option value="">Dosya seçin...</option>';

            data.games.forEach(file => {
                const option = document.createElement('option');
                option.value = file.filename;
                option.textContent = `${file.title || file.id} (${file.count} oyun)`;
                select.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Eşleştirme oyunu dosyaları yüklenemedi:', error);
    }
}

// Load specific matching game file
async function loadMatchingGameFile() {
    const select = document.getElementById('matchingGameFile');
    const filename = select.value;

    if (!filename) {
        document.getElementById('matchingGameEditor').value = '';
        currentMatchingGameFile = null;
        matchingGameData = [];
        return;
    }

    try {
        const response = await fetch(`/matching-games/${filename}`);
        const data = await response.json();

        if (data.success) {
            currentMatchingGameFile = filename;
            matchingGameData = data.games;
            document.getElementById('matchingGameEditor').value = JSON.stringify(data.games, null, 2);
        }
    } catch (error) {
        console.error('Eşleştirme oyunu dosyası yüklenemedi:', error);
        showToast('Eşleştirme oyunu dosyası yüklenemedi', 'error');
    }
}

// Save matching games - Save the entire array
async function saveMatchingGames() {
    if (!currentMatchingGameFile) {
        showToast('Önce bir oyun dosyası seçin', 'warning');
        return;
    }

    const editor = document.getElementById('matchingGameEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const games = JSON.parse(jsonText);

        // Validate structure
        if (!Array.isArray(games)) {
            showToast('Oyun verisi bir dizi olmalı', 'error');
            return;
        }

        for (let i = 0; i < games.length; i++) {
            const game = games[i];
            if (!game.title || !game.question || !game.pairs) {
                showToast(`Oyun ${i + 1}: title, question ve pairs alanları zorunlu`, 'error');
                return;
            }
            if (!Array.isArray(game.pairs)) {
                showToast(`Oyun ${i + 1}: pairs bir dizi olmalı`, 'error');
                return;
            }
        }

        // Save entire array to server
        const response = await fetch(`/matching-games/${currentMatchingGameFile}/save`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ games })
        });

        const data = await response.json();

        if (data.success) {
            showToast('Eşleştirme oyunları kaydedildi', 'success');
            matchingGameData = games;
            // Refresh file list
            loadMatchingGameFiles();
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

// Validate matching games
function validateMatchingGames() {
    const editor = document.getElementById('matchingGameEditor');
    const jsonText = editor.value.trim();

    if (!jsonText) {
        showToast('JSON verisi girin', 'warning');
        return;
    }

    try {
        const games = JSON.parse(jsonText);

        if (!Array.isArray(games)) {
            showToast('Oyun verisi bir dizi olmalı', 'error');
            return;
        }

        let errors = [];
        let warnings = [];

        games.forEach((game, index) => {
            if (!game.title) {
                errors.push(`Oyun ${index + 1}: title alanı eksik`);
            }
            if (!game.question) {
                errors.push(`Oyun ${index + 1}: question alanı eksik`);
            }
            if (!game.pairs) {
                errors.push(`Oyun ${index + 1}: pairs alanı eksik`);
            }
            if (game.pairs && !Array.isArray(game.pairs)) {
                errors.push(`Oyun ${index + 1}: pairs bir dizi olmalı`);
            }
            if (game.title && game.title.length < 5) {
                warnings.push(`Oyun ${index + 1}: title çok kısa`);
            }
            if (game.question && game.question.length < 10) {
                warnings.push(`Oyun ${index + 1}: question çok kısa`);
            }
            if (game.pairs && Array.isArray(game.pairs)) {
                if (game.pairs.length < 2) {
                    warnings.push(`Oyun ${index + 1}: en az 2 çift olmalı`);
                }
                game.pairs.forEach((pair, pairIndex) => {
                    if (!pair.left || !pair.right) {
                        errors.push(`Oyun ${index + 1}, çift ${pairIndex + 1}: left ve right alanları zorunlu`);
                    }
                });
            }
            if (game.difficulty && !['easy', 'medium', 'hard'].includes(game.difficulty)) {
                warnings.push(`Oyun ${index + 1}: geçersiz difficulty`);
            }
        });

        if (errors.length > 0) {
            showToast('Hatalar: ' + errors.join(', '), 'error');
        } else if (warnings.length > 0) {
            showToast('Uyarılar: ' + warnings.join(', '), 'warning');
        } else {
            showToast('Tüm eşleştirme oyunları geçerli', 'success');
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
window.loadMatchingGameFiles = loadMatchingGameFiles;
window.loadMatchingGameFile = loadMatchingGameFile;
window.saveMatchingGames = saveMatchingGames;
window.validateMatchingGames = validateMatchingGames;


