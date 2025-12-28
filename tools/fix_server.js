const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');

let content = fs.readFileSync(serverPath, 'utf8');

// Bozuk kısmı bul ve sil
const brokenStart = content.indexOf('// AI Soru Kontrolcusu v2');
const brokenEnd = content.indexOf('});', content.indexOf('return allIssues;', brokenStart));

if (brokenStart !== -1 && brokenEnd !== -1) {
    // Bozuk kodu sil
    content = content.substring(0, brokenStart) + content.substring(brokenEnd + 3);
    console.log('Broken code removed');
}

// Dosyanın sonuna temiz fonksiyonu ekle
const cleanCode = `

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
        
        const prompt = \`Sen KPSS soru kontrolcususun. \${batch.length} soruyu analiz et.

KONU: \${topicInfo.name} (\${topicInfo.lesson})

\${questionsText}

KONTROL: Yazim hatasi, mantik hatasi, yanlis cevap, eksik aciklama

SADECE HATA OLAN SORULARI RAPORLA!

JSON FORMAT:
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
            const content = data.choices?.[0]?.message?.content || '';
            
            try {
                const jsonMatch = content.match(/\\[[\\s\\S]*\\]/);
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
            } catch (e) {}
        } catch (e) {}
        
        if (i + BATCH_SIZE < questions.length) {
            await new Promise(r => setTimeout(r, 500));
        }
    }
    
    return allIssues;
}
`;

if (!content.includes('reviewQuestionsWithAI_Batch')) {
    content = content.trim() + cleanCode;
    console.log('Batch function added');
}

fs.writeFileSync(serverPath, content, 'utf8');
console.log('Server file fixed!');

// Syntax check
try {
    require(serverPath);
    console.log('Syntax OK!');
} catch (e) {
    console.log('Still has syntax error:', e.message);
}
