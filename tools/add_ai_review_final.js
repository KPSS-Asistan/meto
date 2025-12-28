const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
let content = fs.readFileSync(serverPath, 'utf8');

// /all-questions endpoint'inden sonra ekle
const insertPoint = content.indexOf("// GET /stats");

if (insertPoint === -1) {
    console.log('Could not find insertion point');
    process.exit(1);
}

if (content.includes('/ai-review')) {
    console.log('/ai-review already exists');
    process.exit(0);
}

const aiReviewCode = `
        // GET /ai-review - AI ile konu soruları kontrol et
        if (pathname === '/ai-review' && req.method === 'GET') {
            const topicId = url.searchParams.get('topicId');
            const limit = parseInt(url.searchParams.get('limit')) || 50;
            
            if (!topicId) {
                return sendJSON(res, { error: 'topicId gerekli' }, 400);
            }
            
            try {
                const questions = await loadQuestions(topicId);
                const topicInfo = TOPICS[topicId];
                
                if (!topicInfo) {
                    return sendJSON(res, { error: 'Konu bulunamadi' }, 404);
                }
                
                // Sorulari batch halinde analiz et
                const questionsToReview = questions.slice(0, limit);
                const issues = await reviewQuestionsWithAI_Batch(questionsToReview, topicInfo);
                
                return sendJSON(res, {
                    topicId,
                    topicName: topicInfo.name,
                    reviewed: questionsToReview.length,
                    total: questions.length,
                    issues
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }

        `;

content = content.substring(0, insertPoint) + aiReviewCode + content.substring(insertPoint);

// Batch review fonksiyonunu da dosyanın sonuna ekle
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
        
        const prompt = \`KPSS soru kalite kontrolcususun. \${batch.length} soruyu analiz et.

KONU: \${topicInfo.name} (\${topicInfo.lesson})

\${questionsText}

KONTROL: yazim hatasi, mantik hatasi, yanlis cevap, eksik aciklama

SADECE HATA OLAN SORULARI RAPORLA!

JSON FORMAT:
[{"id":"soru_id","hasIssue":true,"severity":"low/medium/high","issues":[{"type":"yazim/mantik/aciklama","description":"..."}],"suggestion":"..."}]

Hata yoksa bos array dondur: []
SADECE JSON dondur, baska bir sey yazma!\`;

        try {
            const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
                method: 'POST',
                headers: {
                    'Authorization': \`Bearer \${OPENROUTER_API_KEY}\`,
                    'Content-Type': 'application/json',
                    'HTTP-Referer': 'http://localhost:3456',
                    'X-Title': 'KPSS Question Review'
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
            } catch (e) { console.log('JSON parse error:', e.message); }
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
console.log('/ai-review endpoint and batch function added!');
