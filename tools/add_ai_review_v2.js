const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');

let content = fs.readFileSync(serverPath, 'utf8');

// /flutter-sync endpoint'inden sonra ekle
const insertPoint = "// GET /flutter-sync";
const idx = content.indexOf(insertPoint);

if (idx === -1) {
    console.log('Insertion point not found');
    process.exit(1);
}

// Zaten var mı kontrol et
if (content.includes('/ai-review')) {
    console.log('AI Review endpoint already exists');
    process.exit(0);
}

const aiReviewCode = `
        // GET /ai-review - AI ile tum konudaki sorulari kontrol et
        if (pathname === '/ai-review' && req.method === 'GET') {
            const topicId = url.searchParams.get('topicId');
            
            if (!topicId) {
                return sendJSON(res, { error: 'topicId gerekli' }, 400);
            }
            
            try {
                const questions = await loadQuestions(topicId);
                const topicInfo = TOPICS[topicId];
                
                if (!topicInfo) {
                    return sendJSON(res, { error: 'Konu bulunamadi' }, 404);
                }
                
                // Tum sorulari batch halinde analiz et
                const issues = await reviewQuestionsWithAI_Batch(questions, topicInfo);
                
                return sendJSON(res, {
                    topicId,
                    topicName: topicInfo.name,
                    reviewed: questions.length,
                    total: questions.length,
                    issues
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }

`;

// Insert before flutter-sync
content = content.substring(0, idx) + aiReviewCode + content.substring(idx);

// Add batch function at end
const batchFunction = `

// ═══════════════════════════════════════════════════════════════════
// AI SORU KONTROLCUSU (BATCH)
// ═══════════════════════════════════════════════════════════════════

async function reviewQuestionsWithAI_Batch(questions, topicInfo) {
    const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY || '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';
    
    const allIssues = [];
    const BATCH_SIZE = 10;
    
    for (let i = 0; i < questions.length; i += BATCH_SIZE) {
        const batch = questions.slice(i, i + BATCH_SIZE);
        
        let questionsText = '';
        batch.forEach((q, idx) => {
            questionsText += \`
--- SORU \${idx + 1} (ID: \${q.id}) ---
Metin: \${q.q}
A) \${q.o?.[0] || ''}
B) \${q.o?.[1] || ''}
C) \${q.o?.[2] || ''}
D) \${q.o?.[3] || ''}
E) \${q.o?.[4] || ''}
Dogru: \${['A','B','C','D','E'][q.a]}
Aciklama: \${q.e || 'YOK'}
\`;
        });
        
        const prompt = \`KPSS soru kontrolcusu. \${batch.length} soruyu analiz et.

KONU: \${topicInfo.name} (\${topicInfo.lesson})

\${questionsText}

KONTROL: yazim hatasi, mantik hatasi, yanlis cevap, eksik aciklama

SADECE HATA OLAN SORULARI RAPORLA!

JSON:
[{"id":"xxx","hasIssue":true,"severity":"low/medium/high","issues":[{"type":"yazim/mantik","description":"..."}],"suggestion":"..."}]

Hata yoksa: []
SADECE JSON!\`;

        try {
            const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
                method: 'POST',
                headers: {
                    'Authorization': \`Bearer \${OPENROUTER_API_KEY}\`,
                    'Content-Type': 'application/json',
                    'HTTP-Referer': 'http://localhost:3456'
                },
                body: JSON.stringify({
                    model: 'google/gemini-2.0-flash-001',
                    messages: [{ role: 'user', content: prompt }],
                    temperature: 0.1,
                    max_tokens: 2000
                })
            });

            const data = await response.json();
            const aiContent = data.choices?.[0]?.message?.content || '';
            
            try {
                const jsonMatch = aiContent.match(/\\[[\\s\\S]*\\]/);
                if (jsonMatch) {
                    const results = JSON.parse(jsonMatch[0]);
                    results.forEach(r => {
                        if (r.hasIssue && r.id) {
                            const originalQ = batch.find(q => q.id === r.id);
                            allIssues.push({
                                questionId: r.id,
                                questionPreview: (originalQ?.q || '').substring(0, 80) + '...',
                                severity: r.severity || 'medium',
                                issues: r.issues || [],
                                suggestion: r.suggestion || ''
                            });
                        }
                    });
                }
            } catch (e) { console.log('Parse error'); }
        } catch (e) { console.log('API error:', e.message); }
        
        // Rate limiting
        if (i + BATCH_SIZE < questions.length) {
            await new Promise(r => setTimeout(r, 500));
        }
    }
    
    return allIssues;
}
`;

if (!content.includes('reviewQuestionsWithAI_Batch')) {
    content = content.trim() + batchFunction;
}

fs.writeFileSync(serverPath, content, 'utf8');
console.log('AI Review endpoint added successfully!');

// Syntax check
const { execSync } = require('child_process');
try {
    execSync('node --check tools/question_server.js', { cwd: path.join(__dirname, '..') });
    console.log('Syntax OK!');
} catch (e) {
    console.log('Syntax error!');
}
