const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
let content = fs.readFileSync(serverPath, 'utf8');

// Response'a reviewedQuestionIds ekle
const oldResponse = `return sendJSON(res, {
                    topicId,
                    topicName: topicInfo.name,
                    reviewed: questionsToReview.length,
                    total: questions.length,
                    issues
                });`;

const newResponse = `return sendJSON(res, {
                    topicId,
                    topicName: topicInfo.name,
                    reviewed: questionsToReview.length,
                    total: questions.length,
                    issues,
                    reviewedQuestionIds: questionsToReview.map(q => q.id)
                });`;

if (content.includes(oldResponse)) {
    content = content.replace(oldResponse, newResponse);
    fs.writeFileSync(serverPath, content, 'utf8');
    console.log('Added reviewedQuestionIds to response!');
} else {
    console.log('Response pattern not found');
}
