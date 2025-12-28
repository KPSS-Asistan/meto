const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
let content = fs.readFileSync(serverPath, 'utf8');

// Eski /all-questions endpoint'ini bul ve yenisiyle değiştir
const oldEndpointStart = content.indexOf("// GET /all-questions");
if (oldEndpointStart === -1) {
    console.log('Endpoint not found');
    process.exit(1);
}

// Endpoint'in sonunu bul (bir sonraki // GET veya if bloğunun bitmesi)
let endIdx = content.indexOf("// GET /stats", oldEndpointStart);
if (endIdx === -1) {
    endIdx = content.indexOf("        // GET /", oldEndpointStart + 50);
}

const newEndpoint = `// GET /all-questions - Tum sorular (Zorluk filtreleme icin)
        if (pathname === '/all-questions' && req.method === 'GET') {
            try {
                const allQuestions = {};
                const topicsInfo = {};
                
                for (const [topicId, topicInfo] of Object.entries(TOPICS)) {
                    const questions = await loadQuestions(topicId);
                    
                    // Her soruya zorluk ekle
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

        `;

content = content.substring(0, oldEndpointStart) + newEndpoint + content.substring(endIdx);
fs.writeFileSync(serverPath, content, 'utf8');
console.log('/all-questions endpoint fixed!');
