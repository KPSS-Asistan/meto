// AI Soru Kontrolcusu v2 - BATCH PROCESSING
// Tek API çağrısında birden fazla soru analiz edilir

// GET /ai-review?topicId=xxx&limit=100 - Belirli konudaki soruları AI ile kontrol et
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

        // Soruları sınırla
        const questionsToReview = questions.slice(0, limit);

        const results = await reviewQuestionsWithAI_Batch(questionsToReview, topicInfo);

        return sendJSON(res, {
            topicId,
            topicName: topicInfo.name,
            reviewed: questionsToReview.length,
            total: questions.length,
            issues: results
        });
    } catch (e) {
        return sendJSON(res, { error: e.message }, 500);
    }
}

// AI Review fonksiyonu - BATCH VERSION
async function reviewQuestionsWithAI_Batch(questions, topicInfo) {
    const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY || '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';

    const allIssues = [];
    const BATCH_SIZE = 10; // Her batch'te 10 soru

    // Soruları batch'lere böl
    for (let i = 0; i < questions.length; i += BATCH_SIZE) {
        const batch = questions.slice(i, i + BATCH_SIZE);

        // Batch için soru listesi oluştur
        let questionsText = '';
        batch.forEach((q, idx) => {
            questionsText += `
--- SORU ${idx + 1} (ID: ${q.id}) ---
Metin: ${q.q}
A) ${q.o?.[0] || ''}
B) ${q.o?.[1] || ''}
C) ${q.o?.[2] || ''}
D) ${q.o?.[3] || ''}
E) ${q.o?.[4] || ''}
Dogru: ${['A', 'B', 'C', 'D', 'E'][q.a]}
Aciklama: ${q.e || 'YOK'}
`;
        });

        const prompt = `Sen bir KPSS soru kalite kontrolcususun. Asagidaki ${batch.length} soruyu analiz et.

KONU: ${topicInfo.name} (${topicInfo.lesson})

${questionsText}

---
HER SORU ICIN KONTROL ET:
1. Yazim/imla hatasi var mi?
2. Soru anlasilir mi?
3. Secenekler mantikli mi?
4. Dogru cevap dogru mu?
5. Aciklama yeterli mi?

ONEMLI: SADECE HATA OLAN SORULARI RAPORLA!

CEVAP FORMATI (JSON array):
[
  {
    "id": "soru_id",
    "hasIssue": true,
    "severity": "low/medium/high/critical",
    "issues": [{"type": "yazim/mantik/aciklama/secenek", "description": "..."}],
    "suggestion": "..."
  }
]

Hata yoksa bos array dondur: []
SADECE JSON dondur, baska bir sey yazma.`;

        try {
            const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
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
            const content = data.choices?.[0]?.message?.content || '';

            // JSON parse et
            try {
                const jsonMatch = content.match(/\[[\s\S]*\]/);
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
            } catch (parseErr) {
                console.log('JSON parse error:', parseErr.message);
            }
        } catch (apiErr) {
            console.log('API error:', apiErr.message);
        }

        // Batch arası kısa bekleme (rate limiting)
        if (i + BATCH_SIZE < questions.length) {
            await new Promise(r => setTimeout(r, 500));
        }
    }

    return allIssues;
}
