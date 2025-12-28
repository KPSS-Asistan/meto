const fs = require('fs');
const path = require('path');

const QUESTIONS_DIR = path.join(__dirname, '..', 'assets', 'data', 'questions');
const VALID_WORDS_FILE = path.join(__dirname, 'valid_words.json');

// Levenshtein distance implementation
function levenshtein(a, b) {
    if (a.length === 0) return b.length;
    if (b.length === 0) return a.length;

    const matrix = [];

    // increment along the first column of each row
    let i;
    for (i = 0; i <= b.length; i++) {
        matrix[i] = [i];
    }

    // increment each column in the first row
    let j;
    for (j = 0; j <= a.length; j++) {
        matrix[0][j] = j;
    }

    // Fill in the rest of the matrix
    for (i = 1; i <= b.length; i++) {
        for (j = 1; j <= a.length; j++) {
            if (b.charAt(i - 1) == a.charAt(j - 1)) {
                matrix[i][j] = matrix[i - 1][j - 1];
            } else {
                matrix[i][j] = Math.min(
                    matrix[i - 1][j - 1] + 1, // substitution
                    Math.min(
                        matrix[i][j - 1] + 1, // insertion
                        matrix[i - 1][j] + 1 // deletion
                    )
                );
            }
        }
    }

    return matrix[b.length][a.length];
}

// Helper: Common Prefix Length
function getCommonPrefixLen(a, b) {
    let i = 0;
    while (i < a.length && i < b.length && a.charCodeAt(i) === b.charCodeAt(i)) i++;
    return i;
}

async function analyzeTypos() {
    let files = [];
    try {
        files = await fs.promises.readdir(QUESTIONS_DIR);
    } catch (e) {
        return { error: "Questions directory not found" };
    }

    // Load/Reload Whitelist
    let validWordsSet = new Set();
    try {
        if (fs.existsSync(VALID_WORDS_FILE)) {
            const data = await fs.promises.readFile(VALID_WORDS_FILE, 'utf8');
            JSON.parse(data).forEach(w => validWordsSet.add(w));
        }
    } catch (e) {
        // Ignore whitelist error
    }

    const jsonFiles = files.filter(f => f.endsWith('.json'));
    const wordCounts = {};
    const wordFiles = {};

    for (const file of jsonFiles) {
        const filePath = path.join(QUESTIONS_DIR, file);
        let content;
        try {
            content = await fs.promises.readFile(filePath, 'utf8');
        } catch (e) { continue; }

        let questions;
        try { questions = JSON.parse(content); } catch { continue; }

        const extractWords = (text) => {
            if (!text) return;
            // Clean text: keep Turkish chars
            // Also replace non-breaking spaces
            const clean = text.replace(/<[^>]*>/g, ' ')
                .replace(/&nbsp;/g, ' ')
                .replace(/[0-9]/g, ' ')
                .replace(/[.,;:"'?!()\[\]{}\-\/\\|=%&+*^#@_]/g, ' ')
                .toLowerCase();

            const words = clean.split(/\s+/);
            words.forEach(w => {
                w = w.trim();
                // Visual min length 5
                if (w.length < 5) return;

                // Only consider words with letters (Turkish support)
                if (/^[a-zğüşıöç]+$/.test(w)) {
                    wordCounts[w] = (wordCounts[w] || 0) + 1;
                    if (!wordFiles[w]) wordFiles[w] = new Set();
                    wordFiles[w].add(file);
                }
            });
        };

        questions.forEach(q => {
            extractWords(q.q);
            extractWords(q.e);
            if (q.o && Array.isArray(q.o)) q.o.forEach(o => extractWords(o));
            if (q.options && typeof q.options === 'object') {
                Object.values(q.options).forEach(v => extractWords(v));
            }
        });
    }

    // 2. Identify Rare vs Common words
    const rareWords = [];
    const commonByLen = {};

    Object.entries(wordCounts).forEach(([word, count]) => {
        if (word.length < 5) return;

        // Skip if in whitelist
        if (validWordsSet.has(word)) return;

        if (count === 1) {
            rareWords.push(word);
        } else if (count >= 15) {
            const len = word.length;
            if (!commonByLen[len]) commonByLen[len] = [];
            commonByLen[len].push(word);
        }
    });

    // 3. Fuzzy match
    const results = [];

    for (const rare of rareWords) {
        const len = rare.length;
        const maxDist = len >= 8 ? 2 : 1;

        // Candidates
        let candidates = [];
        for (let l = len - maxDist; l <= len + maxDist; l++) {
            if (commonByLen[l]) candidates = candidates.concat(commonByLen[l]);
        }

        let bestMatch = null;
        let bestDist = 100;

        for (const common of candidates) {
            const dist = levenshtein(rare, common);

            if (dist <= maxDist && dist < bestDist) {
                // SUFFIX GUARD (Morphology Check)
                // If words share the same stem (e.g. >60% prefix match), ignore it.
                // This filters out valid Turkish suffix variations.
                const prefixLen = getCommonPrefixLen(rare, common);
                const ratio = prefixLen / Math.max(len, common.length);

                if (ratio > 0.60) {
                    continue;
                }

                bestDist = dist;
                bestMatch = common;
            }
        }

        if (bestMatch) {
            const score = 1 - (bestDist / len);
            results.push({
                word: rare,
                suggestion: bestMatch,
                score: score,
                files: Array.from(wordFiles[rare]),
                dist: bestDist
            });
        }
    }

    // Sort by confidence
    results.sort((a, b) => {
        if (Math.abs(b.score - a.score) > 0.01) return b.score - a.score;
        return a.word.localeCompare(b.word);
    });

    return { totalWords: Object.keys(wordCounts).length, typos: results };
}

module.exports = { analyzeTypos, levenshtein };
