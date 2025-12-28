const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '../lib/core/data/topics_data.dart');
let content = fs.readFileSync(filePath, 'utf8');

// lesson_id'leri eski formata çevir
content = content.replace(/'lesson_id': 'tarih'/g, "'lesson_id': 'caZ5LwfH3QJrBVUQCros'");
content = content.replace(/'lesson_id': 'turkce'/g, "'lesson_id': 'L3i1Rqv2LN3AKFFejuUg'");
content = content.replace(/'lesson_id': 'cografya'/g, "'lesson_id': 'A779wvZWQcbvanmbS8Qz'");
content = content.replace(/'lesson_id': 'vatandaslik'/g, "'lesson_id': '2ztkqV35cWjGRkhYRutg'");

fs.writeFileSync(filePath, content, 'utf8');
console.log('✅ topics_data.dart lesson_id\'leri eski formata döndürüldü!');
