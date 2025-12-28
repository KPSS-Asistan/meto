const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { TOPICS, LESSON_TARGETS } = require('./topics');

const app = express();
const PORT = 3456;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.static(path.join(__dirname, 'public')));

// Paths
const QUESTIONS_DIR = path.join(__dirname, '../assets/data/questions');

// ═══════════════════════════════════════════════════════════════════════════
// ENDPOINTS
// ═══════════════════════════════════════════════════════════════════════════

// 1. Get Topics
app.get('/topics', (req, res) => {
    try {
        const topicsList = [];
        for (const [id, data] of Object.entries(TOPICS)) {
            const filePath = path.join(QUESTIONS_DIR, `${id}.json`);
            let count = 0;
            if (fs.existsSync(filePath)) {
                try {
                    const content = fs.readFileSync(filePath, 'utf8');
                    const questions = JSON.parse(content);
                    count = questions.length;
                } catch (e) { count = 0; }
            }

            topicsList.push({
                id,
                ...data,
                count
            });
        }
        res.json(topicsList);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// 2. Get Stats
app.get('/stats', (req, res) => {
    try {
        let totalQuestions = 0;
        let totalTopics = 0;
        let missingExplanations = 0;
        let totalQuality = 0;
        const byLesson = {};
        const byTopic = [];

        for (const [id, data] of Object.entries(TOPICS)) {
            totalTopics++;
            const filePath = path.join(QUESTIONS_DIR, `${id}.json`);
            let count = 0;
            let topicQuality = 0;
            let topicMissing = 0;

            if (fs.existsSync(filePath)) {
                try {
                    const content = fs.readFileSync(filePath, 'utf8');
                    const questions = JSON.parse(content);
                    count = questions.length;

                    questions.forEach(q => {
                        if (!q.e || q.e.length < 5) {
                            topicMissing++;
                            missingExplanations++;
                        }
                    });
                } catch (e) { }
            }

            totalQuestions += count;

            if (!byLesson[data.lesson]) byLesson[data.lesson] = { count: 0 };
            byLesson[data.lesson].count += count;

            byTopic.push({
                id,
                name: data.name,
                lesson: data.lesson,
                count,
                missingExplanations: topicMissing,
                avgQuality: 0 // Simplified for now
            });
        }

        res.json({
            totalQuestions,
            totalTopics,
            avgQualityScore: 0,
            missingExplanations,
            byLesson,
            byTopic,
            qualityDistribution: { excellent: 0, good: 0, average: 0, poor: 0 }
        });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// 3. Get Questions for Topic
app.get('/questions/:topicId', (req, res) => {
    try {
        const { topicId } = req.params;
        const filePath = path.join(QUESTIONS_DIR, `${topicId}.json`);

        if (!fs.existsSync(filePath)) {
            return res.json([]);
        }

        const content = fs.readFileSync(filePath, 'utf8');
        let questions = JSON.parse(content);

        // Add temporary IDs if invalid
        questions = questions.map((q, i) => ({
            ...q,
            id: q.id || `${topicId}_${i}_${Date.now()}`
        }));

        res.json(questions);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// 4. DELETE Question
app.post('/delete', (req, res) => {
    try {
        const { topicId, questionId } = req.body;
        if (!topicId) return res.status(400).json({ error: 'Topic ID required' });

        const filePath = path.join(QUESTIONS_DIR, `${topicId}.json`);
        if (!fs.existsSync(filePath)) {
            return res.status(404).json({ error: 'Topic file not found' });
        }

        const content = fs.readFileSync(filePath, 'utf8');
        let questions = JSON.parse(content);
        const originalLength = questions.length;

        // Filter out the question (check both id and direct object comparison logic if needed)
        // Since dashboard passes questionId, we use that.
        // NOTE: If questionId is index-based in dashboard, this might be tricky if ids aren't stable.
        // Assuming Dashboard sends the ID property of the question object.

        questions = questions.filter(q => q.id !== questionId);

        // If length didn't change, maybe it's index based?
        // Let's assume dashboard sends proper IDs.

        fs.writeFileSync(filePath, JSON.stringify(questions, null, 2), 'utf8');

        console.log(`🗑️ Deleted question from ${topicId}. Count: ${originalLength} -> ${questions.length}`);

        res.json({ success: true, count: questions.length });
    } catch (e) {
        console.error('Delete error:', e);
        res.status(500).json({ error: e.message });
    }
});

// 5. Add Questions
app.post('/add', (req, res) => {
    try {
        const { topicId, questions } = req.body;
        if (!topicId || !questions) return res.status(400).json({ error: 'Missing data' });

        const filePath = path.join(QUESTIONS_DIR, `${topicId}.json`);
        let currentQuestions = [];

        if (fs.existsSync(filePath)) {
            try {
                currentQuestions = JSON.parse(fs.readFileSync(filePath, 'utf8'));
            } catch (e) { }
        }

        // Add IDs and timestamp
        const newQuestions = questions.map((q, i) => ({
            ...q,
            id: `${topicId}_${Date.now()}_${i}`,
            topicId: topicId,
            createdAt: new Date().toISOString()
        }));

        currentQuestions = [...currentQuestions, ...newQuestions];

        fs.writeFileSync(filePath, JSON.stringify(currentQuestions, null, 2), 'utf8');

        console.log(`✅ Added ${questions.length} questions to ${topicId}`);
        res.json({ success: true, count: currentQuestions.length });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Start Server
app.listen(PORT, () => {
    console.log(`🚀 Server Fix running at http://localhost:${PORT}`);
    console.log(`sz Data Dir: ${QUESTIONS_DIR}`);
});
