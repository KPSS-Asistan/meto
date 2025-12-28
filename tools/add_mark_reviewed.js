const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
let content = fs.readFileSync(serverPath, 'utf8');

// /ai-review endpoint'inden sonra /mark-reviewed endpoint'i ekle
const insertPoint = content.indexOf("// GET /stats");

if (insertPoint === -1) {
    console.log('Could not find insertion point');
    process.exit(1);
}

if (content.includes('/mark-reviewed')) {
    console.log('/mark-reviewed already exists');
    process.exit(0);
}

const markReviewedEndpoint = `
        // POST /mark-reviewed - Soruyu kontrol edildi olarak işaretle
        if (pathname === '/mark-reviewed' && req.method === 'POST') {
            try {
                const { topicId, questionIds } = await parseBody(req);
                
                if (!topicId || !questionIds || !questionIds.length) {
                    return sendJSON(res, { error: 'topicId ve questionIds gerekli' }, 400);
                }
                
                const questions = await loadQuestions(topicId);
                let markedCount = 0;
                
                questions.forEach(q => {
                    if (questionIds.includes(q.id)) {
                        q.aiReviewed = new Date().toISOString();
                        markedCount++;
                    }
                });
                
                if (markedCount > 0) {
                    await saveQuestions(topicId, questions);
                }
                
                return sendJSON(res, { 
                    success: true, 
                    markedCount,
                    message: markedCount + ' soru kontrol edildi olarak işaretlendi'
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }

        `;

content = content.substring(0, insertPoint) + markReviewedEndpoint + content.substring(insertPoint);
fs.writeFileSync(serverPath, content, 'utf8');
console.log('/mark-reviewed endpoint added!');
