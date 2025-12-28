const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
let content = fs.readFileSync(serverPath, 'utf8');

// loadQuestions fonksiyonunu bul ve değiştir
const oldFunc = `const loadQuestions = async (topicId) => {
    try {
        const data = await fs.readFile(path.join(QUESTIONS_DIR, \`\${topicId}.json\`), 'utf8');
        return JSON.parse(data);
    } catch { return []; }
};`;

const newFunc = `// GitHub repo URL
const GITHUB_RAW_URL = 'https://raw.githubusercontent.com/mertcanasdf/meto/main/questions';

const loadQuestions = async (topicId) => {
    // Önce GitHub'dan çekmeyi dene
    try {
        const response = await fetch(\`\${GITHUB_RAW_URL}/\${topicId}.json\`);
        if (response.ok) {
            const data = await response.json();
            // Başarılı ise lokal cache'e de kaydet
            await fs.writeFile(path.join(QUESTIONS_DIR, \`\${topicId}.json\`), JSON.stringify(data, null, 4), 'utf8').catch(() => {});
            return data;
        }
    } catch (e) {
        console.log(\`GitHub'dan çekilemedi (\${topicId}), lokal dosya kullanılıyor...\`);
    }
    
    // GitHub başarısız olursa lokal dosyadan oku
    try {
        const data = await fs.readFile(path.join(QUESTIONS_DIR, \`\${topicId}.json\`), 'utf8');
        return JSON.parse(data);
    } catch { return []; }
};`;

if (content.includes('const loadQuestions = async (topicId)')) {
    // Regex ile bul
    const regex = /const loadQuestions = async \(topicId\) => \{[\s\S]*?catch \{ return \[\]; \}\s*\};/;
    content = content.replace(regex, newFunc);
    fs.writeFileSync(serverPath, content, 'utf8');
    console.log('loadQuestions updated to use GitHub!');
} else {
    console.log('loadQuestions not found');
}
