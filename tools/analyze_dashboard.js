const http = require('http');
const fs = require('fs');

async function getJSON(path) {
    return new Promise((resolve, reject) => {
        http.get('http://localhost:3456' + path, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => resolve(JSON.parse(data)));
        }).on('error', reject);
    });
}

async function analyze() {
    const lines = [];
    const log = (s) => { lines.push(s); console.log(s); };

    try {
        const stats = await getJSON('/stats');
        const topics = await getJSON('/topics');

        log('');
        log('========== KPSS DASHBOARD - TAM ANALIZ RAPORU ==========');
        log('');

        log('GENEL ISTATISTIKLER');
        log('-------------------');
        log('   Toplam Soru: ' + stats.totalQuestions);
        log('   Aciklamali:  ' + stats.withExplanation);
        log('');

        log('DERS BAZINDA DAGILIM');
        log('--------------------');
        const lessons = Object.entries(stats.byLesson).sort((a, b) => b[1].count - a[1].count);
        lessons.forEach(([lesson, data]) => {
            log('   ' + lesson.padEnd(18) + ': ' + data.count + ' soru');
        });
        log('');

        log('KONU DETAYLARI (Dolu Olanlar)');
        log('-----------------------------');
        const filledTopics = topics.filter(t => t.count > 0).sort((a, b) => b.count - a.count);
        filledTopics.forEach(t => {
            log('   ' + String(t.count).padStart(4) + ' soru | ' + t.lesson.substring(0, 12).padEnd(12) + ' | ' + t.name);
        });
        log('');

        log('BOS KONULAR');
        log('-----------');
        const emptyTopics = topics.filter(t => t.count === 0);
        const emptyByLesson = {};
        emptyTopics.forEach(t => {
            if (!emptyByLesson[t.lesson]) emptyByLesson[t.lesson] = [];
            emptyByLesson[t.lesson].push(t.name);
        });
        Object.entries(emptyByLesson).forEach(([lesson, names]) => {
            log('   ' + lesson + ': ' + names.length + ' bos konu');
            names.forEach(n => log('      - ' + n));
        });
        log('');

        log('OZET');
        log('----');
        log('   Dolu Konu:  ' + filledTopics.length + '/' + topics.length);
        log('   Bos Konu:   ' + emptyTopics.length + '/' + topics.length);
        log('   Doluluk:    ' + ((filledTopics.length / topics.length) * 100).toFixed(1) + '%');
        log('');
        log('=========================================================');

        fs.writeFileSync('tools/rapor.txt', lines.join('\n'), 'utf8');
        console.log('\nRapor tools/rapor.txt dosyasina kaydedildi.');

    } catch (e) {
        console.log('HATA:', e.message);
    }
}

analyze();
