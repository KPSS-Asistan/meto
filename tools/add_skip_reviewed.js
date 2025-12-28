const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
let content = fs.readFileSync(serverPath, 'utf8');

// /ai-review endpoint'ini bul ve skipReviewed parametresi ekle
const oldEndpoint = `if (pathname === '/ai-review' && req.method === 'GET') {
            const topicId = url.searchParams.get('topicId');
            const limit = parseInt(url.searchParams.get('limit')) || 50;`;

const newEndpoint = `if (pathname === '/ai-review' && req.method === 'GET') {
            const topicId = url.searchParams.get('topicId');
            const limit = parseInt(url.searchParams.get('limit')) || 50;
            const skipReviewed = url.searchParams.get('skipReviewed') !== 'false'; // Default: true`;

if (content.includes(oldEndpoint)) {
    content = content.replace(oldEndpoint, newEndpoint);
    console.log('skipReviewed parameter added');
} else {
    console.log('Endpoint pattern not found');
}

// questionsToReview'dan once filtreleme ekle
const oldSlice = 'const questionsToReview = questions.slice(0, limit);';
const newSlice = `// Daha önce kontrol edilenleri atla
                const unreviewedQuestions = skipReviewed 
                    ? questions.filter(q => !q.aiReviewed)
                    : questions;
                const questionsToReview = unreviewedQuestions.slice(0, limit);`;

if (content.includes(oldSlice)) {
    content = content.replace(oldSlice, newSlice);
    console.log('Filter for reviewed questions added');
}

fs.writeFileSync(serverPath, content, 'utf8');
console.log('Done!');
