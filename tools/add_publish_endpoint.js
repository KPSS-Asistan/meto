const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
let content = fs.readFileSync(serverPath, 'utf8');

// /git-push endpoint'inden önce /publish-to-github ekle
const insertPoint = content.indexOf("// POST /git-push");

if (insertPoint === -1) {
    console.log('Could not find insertion point');
    process.exit(1);
}

if (content.includes('/publish-to-github')) {
    console.log('/publish-to-github already exists');
    process.exit(0);
}

const publishEndpoint = `
        // POST /publish-to-github - Soruları GitHub'a yayınla
        if (pathname === '/publish-to-github' && req.method === 'POST') {
            try {
                const metoDir = path.join(__dirname, '..', '..', 'meto-data');
                const metoQuestionsDir = path.join(metoDir, 'questions');
                
                // meto-data klasörü var mı?
                if (!fsSync.existsSync(metoDir)) {
                    return sendJSON(res, { error: 'meto-data klasörü bulunamadı' }, 404);
                }
                
                // questions klasörünü oluştur
                if (!fsSync.existsSync(metoQuestionsDir)) {
                    fsSync.mkdirSync(metoQuestionsDir, { recursive: true });
                }
                
                // Lokal sorulardan meto-data'ya kopyala
                const localQuestions = fsSync.readdirSync(QUESTIONS_DIR).filter(f => f.endsWith('.json'));
                let copiedCount = 0;
                const updatedTopics = [];
                
                for (const file of localQuestions) {
                    const srcPath = path.join(QUESTIONS_DIR, file);
                    const destPath = path.join(metoQuestionsDir, file);
                    const content = fsSync.readFileSync(srcPath, 'utf8');
                    const questions = JSON.parse(content);
                    
                    // Sadece dolu dosyaları kopyala
                    if (questions.length > 0) {
                        fsSync.writeFileSync(destPath, content, 'utf8');
                        copiedCount++;
                        updatedTopics.push(file.replace('.json', ''));
                    }
                }
                
                // version.json güncelle
                const versionPath = path.join(metoDir, 'version.json');
                let versionData = { questions: {}, flashcards: {}, stories: {}, explanations: {}, matching_games: {}, lastUpdated: '' };
                
                if (fsSync.existsSync(versionPath)) {
                    try {
                        versionData = JSON.parse(fsSync.readFileSync(versionPath, 'utf8'));
                    } catch {}
                }
                
                // Her güncelenen topic için version artır
                for (const topicId of updatedTopics) {
                    const currentVersion = versionData.questions?.[topicId] || 0;
                    if (!versionData.questions) versionData.questions = {};
                    versionData.questions[topicId] = currentVersion + 1;
                }
                
                versionData.lastUpdated = new Date().toISOString().split('T')[0];
                fsSync.writeFileSync(versionPath, JSON.stringify(versionData, null, 2), 'utf8');
                
                // Git push
                const { exec } = require('child_process');
                const gitCommands = \`cd "\${metoDir}" && git add . && git commit -m "🚀 Sorular güncellendi: \${updatedTopics.length} konu" && git push\`;
                
                exec(gitCommands, (error, stdout, stderr) => {
                    if (error) {
                        console.log('Git push error:', error.message);
                    } else {
                        console.log('Git push success:', stdout);
                    }
                });
                
                return sendJSON(res, {
                    success: true,
                    message: \`\${copiedCount} dosya GitHub'a aktarıldı\`,
                    updatedTopics,
                    versionData: versionData.questions
                });
                
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }

        `;

content = content.substring(0, insertPoint) + publishEndpoint + content.substring(insertPoint);
fs.writeFileSync(serverPath, content, 'utf8');
console.log('/publish-to-github endpoint added!');
