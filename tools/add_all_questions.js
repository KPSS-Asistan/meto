const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
let content = fs.readFileSync(serverPath, 'utf8');

// /stats endpoint'inden önce /all-questions ekle
const statsPattern = "// GET /stats";
const idx = content.indexOf(statsPattern);

if (idx === -1) {
    console.log('Could not find /stats endpoint');
    process.exit(1);
}

if (content.includes('/all-questions')) {
    console.log('/all-questions already exists');
    process.exit(0);
}

const allQuestionsEndpoint = `
        // GET /all-questions - Tum sorular (Zorluk filtreleme icin)
        if (pathname === '/all-questions' && req.method === 'GET') {
            try {
                const allQuestions = [];
                
                for (const [topicId, topicInfo] of Object.entries(TOPICS)) {
                    const questions = await loadQuestions(topicId);
                    questions.forEach(q => {
                        allQuestions.push({
                            ...q,
                            topicId,
                            topicName: topicInfo.name,
                            lesson: topicInfo.lesson,
                            difficulty: calculateDifficultyScore(q)
                        });
                    });
                }
                
                return sendJSON(res, { 
                    questions: allQuestions,
                    total: allQuestions.length
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }

        `;

content = content.substring(0, idx) + allQuestionsEndpoint + content.substring(idx);
fs.writeFileSync(serverPath, content, 'utf8');
console.log('/all-questions endpoint added!');
