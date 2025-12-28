// GET /all-questions - Tum sorular (Zorluk filtreleme icin)
if (pathname === '/all-questions' && req.method === 'GET') {
    try {
        const allQuestions = {};
        const topicsInfo = {};

        for (const [topicId, topicInfo] of Object.entries(TOPICS)) {
            const questions = await loadQuestions(topicId);

            allQuestions[topicId] = questions.map(q => ({
                ...q,
                difficulty: calculateDifficultyScore(q)
            }));

            topicsInfo[topicId] = {
                name: topicInfo.name,
                lesson: topicInfo.lesson
            };
        }

        return sendJSON(res, {
            questions: allQuestions,
            topics: topicsInfo,
            total: Object.values(allQuestions).reduce((sum, arr) => sum + arr.length, 0)
        });
    } catch (e) {
        return sendJSON(res, { error: e.message }, 500);
    }
}
