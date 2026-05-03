const fs = require('fs').promises;
const path = require('path');
const { QUESTIONS_DIR } = require('../config');
const { sendJSON, parseBody } = require('../utils/helper');
const { loadQuestions, saveQuestions } = require('../services/questionService');

const { TOPICS } = require('../config/topics');

async function handleQuestionRoutes(req, res, pathname, searchParams) {

    const findQuestionIndex = (questions, questionId) => {
        const rawId = decodeURIComponent(questionId);
        let idx = questions.findIndex(q => String(q.id) === rawId);
        if (idx !== -1) return idx;

        const numericIndex = Number(rawId);
        if (Number.isInteger(numericIndex) && numericIndex >= 0 && numericIndex < questions.length) {
            return numericIndex;
        }

        return -1;
    };

    // GET /questions/:topicId/:questionId - Single question fetch for editing
    if (pathname.startsWith('/questions/') && req.method === 'GET') {
        const parts = pathname.split('/');
        if (parts.length === 4) {
            const topicId = decodeURIComponent(parts[2]);
            const questionId = parts[3];

            try {
                const questions = await loadQuestions(topicId);
                const idx = findQuestionIndex(questions, questionId);
                if (idx === -1) {
                    return sendJSON(res, { error: 'Question not found' }, 404);
                }

                return sendJSON(res, { success: true, question: questions[idx], index: idx });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }

    // GET /find-question
    if (pathname === '/find-question' && req.method === 'GET') {
        const qId = searchParams.get('id');
        if (!qId) return sendJSON(res, { error: 'No id provided' }, 400);

        try {
            const files = await fs.readdir(QUESTIONS_DIR);
            const jsonFiles = files.filter(f => f.endsWith('.json'));

            for (const file of jsonFiles) {
                try {
                    const filePath = path.join(QUESTIONS_DIR, file);
                    const fileContent = await fs.readFile(filePath, 'utf8');
                    const questions = JSON.parse(fileContent);

                    const found = questions.find(q => q.id === qId);
                    if (found) {
                        const topicId = path.basename(file, '.json');
                        return sendJSON(res, { success: true, topicId, question: found });
                    }
                } catch (e) { }
            }
            return sendJSON(res, { success: false, error: 'Question not found' }, 404);
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // PUT /questions/:topicId/:questionId
    if (pathname.startsWith('/questions/') && req.method === 'PUT') {
        const parts = pathname.split('/');
        if (parts.length === 4) {
            const topicId = parts[2];
            const questionId = parts[3];

            try {
                const body = await parseBody(req);
                const questions = await loadQuestions(topicId);

                const idx = findQuestionIndex(questions, questionId);
                if (idx === -1) return sendJSON(res, { error: 'Question not found' }, 404);

                questions[idx] = { ...questions[idx], ...body };

                await saveQuestions(topicId, questions);
                return sendJSON(res, { success: true, question: questions[idx] });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }

    // GET /topics
    if (pathname === '/topics' && req.method === 'GET') {
        try {
            const files = await fs.readdir(QUESTIONS_DIR);
            const jsonFiles = files.filter(f => f.endsWith('.json'));

            const topics = await Promise.all(jsonFiles.map(async f => {
                const id = path.basename(f, '.json');
                const info = TOPICS[id];

                let count = 0;
                try {
                    const content = await fs.readFile(path.join(QUESTIONS_DIR, f), 'utf8');
                    const json = JSON.parse(content);
                    if (Array.isArray(json)) count = json.length;
                } catch { }

                if (info) {
                    return { id, name: info.name, lesson: info.lesson, count };
                } else {
                    let lesson = 'Diğer';
                    if (id.startsWith('tarih')) lesson = 'TARİH';
                    else if (id.startsWith('cog')) lesson = 'COĞRAFYA';
                    else if (id.startsWith('vat')) lesson = 'VATANDAŞLIK';
                    else if (id.startsWith('tur')) lesson = 'TÜRKÇE';
                    else if (id.startsWith('mat')) lesson = 'MATEMATİK';

                    return { id, name: id, lesson, count };
                }
            }));

            return sendJSON(res, topics);
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // GET /questions/:topicId - Browse soruları
    if (pathname.startsWith('/questions/') && req.method === 'GET') {
        const parts = pathname.split('/');
        if (parts.length === 3) {
            const topicId = decodeURIComponent(parts[2]);
            try {
                const questions = await loadQuestions(topicId);
                return sendJSON(res, questions);
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }

    // DELETE /questions/:topicId/:questionId
    if (pathname.startsWith('/questions/') && req.method === 'DELETE') {
        const parts = pathname.split('/');
        if (parts.length === 4) {
            const topicId = decodeURIComponent(parts[2]);
            const questionId = decodeURIComponent(parts[3]);

            try {
                const questions = await loadQuestions(topicId);
                const idx = findQuestionIndex(questions, questionId);

                if (idx === -1) {
                    return sendJSON(res, { error: 'Question not found' }, 404);
                }

                questions.splice(idx, 1);
                await saveQuestions(topicId, questions);

                return sendJSON(res, { success: true, message: 'Soru silindi' });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }
    }

    // POST /validate
    if (pathname === '/validate' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { topicId, questions } = body;

            // Load existing questions for duplicate check
            let existingQuestions = [];
            try {
                if (topicId) existingQuestions = await loadQuestions(topicId);
            } catch { }

            const results = questions.map((q, i) => {
                const errors = [];
                const warnings = [];

                // Basic Validation
                if (!q.q || q.q.trim().length < 5) errors.push('Soru metni çok kısa veya boş');
                if (!q.o || !Array.isArray(q.o) || q.o.length !== 5) errors.push('Şık sayısı 5 olmalı');
                if (q.a === undefined || q.a < 0 || q.a > 4) errors.push('Doğru cevap (a) 0-4 arasında olmalı');

                // Duplicate Check (Server-side)
                const normalize = (t) => (t || '').toString().toLowerCase().replace(/[^a-z0-9]/g, '');
                const qText = normalize(q.q);

                // Helper: Check option similarity (>= 60% matches)
                const areOptionsSimilar = (opts1, opts2) => {
                    if (!opts1 || !opts2) return false;
                    const n1 = opts1.map(o => normalize(o));
                    const n2 = opts2.map(o => normalize(o));
                    // Count how many options from n1 exist in n2
                    const matches = n1.filter(o => n2.includes(o)).length;
                    return matches >= 3; // 3/5 = 60%
                };

                if (qText.length > 10) {
                    // 1. Check DB
                    const isDupDB = existingQuestions.some(eq =>
                        normalize(eq.q) === qText && areOptionsSimilar(q.o, eq.o)
                    );
                    if (isDupDB) {
                        errors.push('Bu soru zaten veritabanında var (Şıklar benzer)');
                    }

                    // 2. Check Internal (Batch içinde tekrar)
                    const isDupInternal = questions.slice(0, i).some(prev =>
                        normalize(prev.q) === qText && areOptionsSimilar(q.o, prev.o)
                    );
                    if (isDupInternal) {
                        errors.push('Bu soru liste içinde tekrar ediyor (Şıklar benzer)');
                    }
                }

                return {
                    status: errors.length > 0 ? 'invalid' : 'valid',
                    errors: errors,
                    warnings: warnings
                };
            });

            return sendJSON(res, { results });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /add - Toplu soru ekleme
    if (pathname === '/add' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { topicId, questions: newQuestions } = body;

            if (!topicId) {
                return sendJSON(res, { error: 'topicId gerekli' }, 400);
            }
            if (!newQuestions || !Array.isArray(newQuestions) || newQuestions.length === 0) {
                return sendJSON(res, { error: 'questions dizisi gerekli' }, 400);
            }

            // Mevcut soruları yükle
            let existingQuestions = [];
            try {
                existingQuestions = await loadQuestions(topicId);
            } catch {
                // Dosya yoksa boş dizi ile başla
                existingQuestions = [];
            }

            // Yeni sorulara ID ata ve ekle
            const topicInfo = TOPICS[topicId];
            const prefix = topicInfo?.prefix || topicId.substring(0, 3).toLowerCase();

            const addedQuestions = [];
            for (const q of newQuestions) {
                // ID oluştur
                const timestamp = Date.now();
                const random = Math.random().toString(36).substring(2, 6);
                const newId = q.id || `${prefix}_${timestamp}_${random}`;

                const newQuestion = {
                    id: newId,
                    topicId: topicId,
                    ...q
                };

                existingQuestions.push(newQuestion);
                addedQuestions.push(newQuestion);
            }

            // Kaydet
            await saveQuestions(topicId, existingQuestions);

            return sendJSON(res, {
                success: true,
                added: addedQuestions.length,
                questions: addedQuestions
            });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    return false;
}

module.exports = handleQuestionRoutes;
