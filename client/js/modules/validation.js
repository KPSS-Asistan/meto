/* === modules\validation.js === */

/**
 * KPSS Dashboard - Validation Module
 * Contains logic for validating questions and checking duplicates.
 */

// Helper: Text Normalization
window.normalizeText = function (t) {
    return (t || '').toString()
        .toLocaleLowerCase('tr-TR')
        .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u')
        .replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c')
        .replace(/[^a-z0-9]/gi, '');
};

// 1. Validate Single Question
window.validateSingleQuestion = function (q) {
    const errors = [];

    // Question Text
    if (!q.q || (typeof q.q === 'string' && q.q.trim() === '')) {
        errors.push('Soru metni tamamen boş.');
    } else {
        const text = q.q.trim();
        if (text.length < 5) errors.push('Soru metni çok kısa.');
        // if (text.length > 2000) errors.push('Soru metni çok uzun (maks. 2000 karakter).');
    }

    // Options
    if (!q.o || !Array.isArray(q.o)) {
        errors.push('Şıklar (o) bir dizi olmalı.');
    } else {
        if (q.o.length !== 5) errors.push(`5 şık olmalı (Şuan: ${q.o.length}).`);
        if (q.o.some(opt => !opt || opt.toString().trim() === '')) {
            errors.push('Boş şık bulunuyor.');
        }
        // Duplicate Options Check/Warning could be here
    }

    // Answer
    if (q.a === undefined || q.a === null || isNaN(q.a)) {
        errors.push('Doğru cevap (a) belirtilmemiş.');
    } else {
        const ans = parseInt(q.a);
        if (ans < 0 || ans > 4) errors.push('Doğru cevap 0-4 arasında olmalı.');
    }

    // Difficulty
    if (q.d !== undefined) {
        const diff = parseInt(q.d);
        if (isNaN(diff) || diff < 1 || diff > 3) {
            errors.push('Zorluk (d) 1, 2 veya 3 olmalı.');
        }
    }

    return errors;
};

// 2. Find Duplicate Questions (Batch Internal Check)
window.findDuplicateQuestions = function (parsedArray) {
    if (!Array.isArray(parsedArray)) return [];

    const seenHashes = new Map(); // Hash -> [{index, options}]
    const duplicates = [];

    parsedArray.forEach((q, i) => {
        if (!q || !q.q) return;

        const cleanText = window.normalizeText(q.q);
        if (cleanText.length < 5) return;

        const currentOptions = (q.o || []).map(o => window.normalizeText(o));

        if (seenHashes.has(cleanText)) {
            const existingList = seenHashes.get(cleanText);

            // Check similarity with any of the existing questions with same text
            const isRealDup = existingList.some(existing => {
                const prevOptions = existing.options;
                // Count matching options (exact normalized match)
                const matchCount = prevOptions.filter(o => currentOptions.includes(o)).length;
                return matchCount >= 3; // 3/5 = 60% Threshold
            });

            if (isRealDup) {
                duplicates.push({
                    index: i + 1,
                    originalIndex: existingList[0].index + 1 // Point to the first occurrence
                });
            } else {
                // Same text but different options -> Add to list
                existingList.push({ index: i, options: currentOptions });
            }
        } else {
            seenHashes.set(cleanText, [{ index: i, options: currentOptions }]);
        }
    });

    return duplicates;
};


