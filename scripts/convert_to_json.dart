// Dart verilerini JSON'a dönüştürme scripti
// Çalıştır: dart run scripts/convert_to_json.dart

import 'dart:io';
import 'dart:convert';

void main() async {
  final baseDir = Directory.current.path;
  final outputDir = '$baseDir/github_data';
  
  print('📦 Verileri JSON\'a dönüştürme başlıyor...\n');
  
  // Flashcards
  await convertFlashcards(baseDir, outputDir);
  
  // Stories
  await convertStories(baseDir, outputDir);
  
  // Explanations
  await convertExplanations(baseDir, outputDir);
  
  // Matching Games
  await convertMatchingGames(baseDir, outputDir);
  
  // Version.json güncelle
  await updateVersionJson(outputDir);
  
  print('\n✅ Tüm dönüşümler tamamlandı!');
  print('📁 Çıktı klasörü: $outputDir');
}

Future<void> convertFlashcards(String baseDir, String outputDir) async {
  final flashcardsDir = Directory('$baseDir/lib/core/data/flashcards');
  final outputFlashcardsDir = Directory('$outputDir/flashcards');
  
  if (!await outputFlashcardsDir.exists()) {
    await outputFlashcardsDir.create(recursive: true);
  }
  
  print('📚 Flashcards dönüştürülüyor...');
  
  await for (final file in flashcardsDir.list()) {
    if (file is File && file.path.endsWith('.dart')) {
      final fileName = file.path.split(Platform.pathSeparator).last.replaceAll('.dart', '');
      final topicId = topicIdMap[fileName];
      
      if (topicId != null) {
        final content = await file.readAsString();
        final flashcards = parseFlashcardsFromDart(content);
        
        if (flashcards.isNotEmpty) {
          final jsonFile = File('${outputFlashcardsDir.path}/$topicId.json');
          await jsonFile.writeAsString(
            const JsonEncoder.withIndent('  ').convert(flashcards),
          );
          print('  ✅ $fileName -> $topicId.json (${flashcards.length} kart)');
        }
      }
    }
  }
}

List<Map<String, String>> parseFlashcardsFromDart(String content) {
  final flashcards = <Map<String, String>>[];
  
  // Çok satırlı format: { 'question': '...', 'answer': '...', }
  final multiLineRegex = RegExp(
    r"{\s*'question':\s*'([^']*(?:''[^']*)*)'\s*,\s*'answer':\s*'([^']*(?:''[^']*)*)'\s*,\s*(?:'additionalInfo':\s*'([^']*(?:''[^']*)*)'\s*,?\s*)?}",
    multiLine: true,
    dotAll: true,
  );
  
  // Tek satırlı format: {'question': '...', 'answer': '...'}
  final singleLineRegex = RegExp(
    r"\{'question':\s*'([^']*(?:''[^']*)*)'\s*,\s*'answer':\s*'([^']*(?:''[^']*)*)'\s*(?:,\s*'additionalInfo':\s*'([^']*(?:''[^']*)*)'\s*)?\}",
    multiLine: true,
  );
  
  // Her iki regex'i de dene
  for (final regex in [multiLineRegex, singleLineRegex]) {
    for (final match in regex.allMatches(content)) {
      final question = match.group(1)?.replaceAll("''", "'").replaceAll(r"\'", "'") ?? '';
      final answer = match.group(2)?.replaceAll("''", "'").replaceAll(r"\'", "'") ?? '';
      final additionalInfo = match.group(3)?.replaceAll("''", "'").replaceAll(r"\'", "'") ?? '';
      
      if (question.isNotEmpty && answer.isNotEmpty) {
        // Duplicate kontrolü
        final exists = flashcards.any((f) => f['question'] == question);
        if (!exists) {
          flashcards.add({
            'question': question,
            'answer': answer,
            if (additionalInfo.isNotEmpty) 'additionalInfo': additionalInfo,
          });
        }
      }
    }
  }
  
  return flashcards;
}

// ═══════════════════════════════════════════════════════════════════════════
// STORIES
// ═══════════════════════════════════════════════════════════════════════════

Future<void> convertStories(String baseDir, String outputDir) async {
  final storiesDir = Directory('$baseDir/lib/core/data/stories');
  final outputStoriesDir = Directory('$outputDir/stories');
  
  if (!await outputStoriesDir.exists()) {
    await outputStoriesDir.create(recursive: true);
  }
  
  print('📖 Stories dönüştürülüyor...');
  
  await for (final file in storiesDir.list()) {
    if (file is File && file.path.endsWith('.dart')) {
      final fileName = file.path.split(Platform.pathSeparator).last.replaceAll('.dart', '');
      final topicId = topicIdMap[fileName];
      
      if (topicId != null) {
        final content = await file.readAsString();
        final stories = parseStoriesFromDart(content);
        
        if (stories.isNotEmpty) {
          final jsonFile = File('${outputStoriesDir.path}/$topicId.json');
          await jsonFile.writeAsString(
            const JsonEncoder.withIndent('  ').convert(stories),
          );
          print('  ✅ $fileName -> $topicId.json (${stories.length} hikaye)');
        }
      }
    }
  }
}

List<Map<String, dynamic>> parseStoriesFromDart(String content) {
  final stories = <Map<String, dynamic>>[];
  
  // Story pattern: { 'title': '...', 'content': '''...''', 'keyPoints': [...], 'order': N }
  final storyBlockRegex = RegExp(
    r"\{\s*'title':\s*'([^']+)'\s*,\s*'content':\s*'''([\s\S]*?)'''\s*,\s*'keyPoints':\s*\[([\s\S]*?)\]\s*,\s*'order':\s*(\d+)",
    multiLine: true,
  );
  
  for (final match in storyBlockRegex.allMatches(content)) {
    final title = match.group(1) ?? '';
    final storyContent = match.group(2)?.trim() ?? '';
    final keyPointsRaw = match.group(3) ?? '';
    final order = int.tryParse(match.group(4) ?? '0') ?? 0;
    
    // Parse keyPoints
    final keyPoints = <String>[];
    final keyPointRegex = RegExp(r"'([^']*(?:''[^']*)*)'");
    for (final kpMatch in keyPointRegex.allMatches(keyPointsRaw)) {
      final kp = kpMatch.group(1)?.replaceAll("''", "'").replaceAll(r"\'", "'") ?? '';
      if (kp.isNotEmpty) keyPoints.add(kp);
    }
    
    if (title.isNotEmpty && storyContent.isNotEmpty) {
      stories.add({
        'title': title,
        'content': storyContent,
        'keyPoints': keyPoints,
        'order': order,
      });
    }
  }
  
  // Sort by order
  stories.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
  
  return stories;
}

// ═══════════════════════════════════════════════════════════════════════════
// EXPLANATIONS
// ═══════════════════════════════════════════════════════════════════════════

Future<void> convertExplanations(String baseDir, String outputDir) async {
  final explanationsDir = Directory('$baseDir/lib/core/data/explanations');
  final outputExplanationsDir = Directory('$outputDir/explanations');
  
  if (!await outputExplanationsDir.exists()) {
    await outputExplanationsDir.create(recursive: true);
  }
  
  print('📝 Explanations dönüştürülüyor...');
  
  await for (final file in explanationsDir.list()) {
    if (file is File && file.path.endsWith('.dart')) {
      final fileName = file.path.split(Platform.pathSeparator).last.replaceAll('.dart', '');
      final topicId = explanationTopicIdMap[fileName];
      
      if (topicId != null) {
        final content = await file.readAsString();
        final explanations = parseExplanationsFromDart(content);
        
        if (explanations.isNotEmpty) {
          final jsonFile = File('${outputExplanationsDir.path}/$topicId.json');
          await jsonFile.writeAsString(
            const JsonEncoder.withIndent('  ').convert(explanations),
          );
          print('  ✅ $fileName -> $topicId.json (${explanations.length} açıklama)');
        }
      }
    }
  }
}

List<Map<String, dynamic>> parseExplanationsFromDart(String content) {
  final explanations = <Map<String, dynamic>>[];
  
  // Explanation pattern: { 'title': '...', 'content': '...', 'order': N }
  final expRegex = RegExp(
    r"\{\s*'title':\s*'([^']*(?:''[^']*)*)'\s*,\s*'content':\s*'([^']*(?:''[^']*)*)'\s*,\s*'order':\s*(\d+)",
    multiLine: true,
  );
  
  for (final match in expRegex.allMatches(content)) {
    final title = match.group(1)?.replaceAll("''", "'") ?? '';
    final expContent = match.group(2)?.replaceAll("''", "'") ?? '';
    final order = int.tryParse(match.group(3) ?? '0') ?? 0;
    
    if (title.isNotEmpty && expContent.isNotEmpty) {
      explanations.add({
        'title': title,
        'content': expContent,
        'order': order,
      });
    }
  }
  
  explanations.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
  
  return explanations;
}

// ═══════════════════════════════════════════════════════════════════════════
// MATCHING GAMES
// ═══════════════════════════════════════════════════════════════════════════

Future<void> convertMatchingGames(String baseDir, String outputDir) async {
  final matchingDir = Directory('$baseDir/lib/core/data/matching_games');
  final outputMatchingDir = Directory('$outputDir/matching_games');
  
  if (!await matchingDir.exists()) {
    print('⚠️ Matching games klasörü bulunamadı');
    return;
  }
  
  if (!await outputMatchingDir.exists()) {
    await outputMatchingDir.create(recursive: true);
  }
  
  print('🎮 Matching Games dönüştürülüyor...');
  
  await for (final file in matchingDir.list()) {
    if (file is File && file.path.endsWith('.dart')) {
      final fileName = file.path.split(Platform.pathSeparator).last.replaceAll('.dart', '');
      final topicId = topicIdMap[fileName];
      
      if (topicId != null) {
        final content = await file.readAsString();
        final games = parseMatchingGamesFromDart(content);
        
        if (games.isNotEmpty) {
          final jsonFile = File('${outputMatchingDir.path}/$topicId.json');
          await jsonFile.writeAsString(
            const JsonEncoder.withIndent('  ').convert(games),
          );
          print('  ✅ $fileName -> $topicId.json (${games.length} eşleşme)');
        }
      }
    }
  }
}

List<Map<String, String>> parseMatchingGamesFromDart(String content) {
  final games = <Map<String, String>>[];
  
  // Matching pattern: {'left': '...', 'right': '...'}
  final matchRegex = RegExp(
    r"\{\s*'left':\s*'([^']*(?:''[^']*)*)'\s*,\s*'right':\s*'([^']*(?:''[^']*)*)'\s*\}",
    multiLine: true,
  );
  
  for (final match in matchRegex.allMatches(content)) {
    final left = match.group(1)?.replaceAll("''", "'") ?? '';
    final right = match.group(2)?.replaceAll("''", "'") ?? '';
    
    if (left.isNotEmpty && right.isNotEmpty) {
      games.add({'left': left, 'right': right});
    }
  }
  
  return games;
}

// ═══════════════════════════════════════════════════════════════════════════
// VERSION.JSON GÜNCELLE
// ═══════════════════════════════════════════════════════════════════════════

Future<void> updateVersionJson(String outputDir) async {
  final version = <String, dynamic>{
    'last_updated': DateTime.now().toIso8601String().split('T')[0],
  };
  
  // Her klasördeki JSON dosyalarını tara
  for (final type in ['flashcards', 'stories', 'explanations', 'matching_games']) {
    final dir = Directory('$outputDir/$type');
    if (await dir.exists()) {
      final typeVersions = <String, int>{};
      await for (final file in dir.list()) {
        if (file is File && file.path.endsWith('.json')) {
          final topicId = file.path.split(Platform.pathSeparator).last.replaceAll('.json', '');
          typeVersions[topicId] = 1;
        }
      }
      if (typeVersions.isNotEmpty) {
        version[type] = typeVersions;
      }
    }
  }
  
  final versionFile = File('$outputDir/version.json');
  await versionFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(version),
  );
  print('\n📋 version.json güncellendi');
}

// ═══════════════════════════════════════════════════════════════════════════
// TOPIC ID MAPS
// ═══════════════════════════════════════════════════════════════════════════

final topicIdMap = {
  // TARİH
  'tarih_islamiyet_oncesi': 'JnFbEQt0uA8RSEuy22SQ',
  'tarih_ilk_musluman_turk': '9Hg8tuMRdMTuVY7OZ9HL',
  'tarih_osmanli': 'rl2xQTfv1iUaCyhFzp5V',
  'tarih_kurtulus_savasi': 'DlT19snCttf5j5RUAXLz',
  'tarih_ataturk_ilkeleri': '4GUvpqBBImcLmN2eh1HK',
  'tarih_cumhuriyet': 'onwrfsH02TgIhlyRUh56',
  'tarih_cagdas': 'qBFhnVl9E4oNj8MsBqnB',
  // TÜRKÇE
  'turkce_ses_bilgisi': '80e0wkTLvaTQzPD6puB7',
  'turkce_yapi_bilgisi': 'yWlh5C6jB7lzuJOodr2t',
  'turkce_sozcuk_turleri': 'ICNDiSlTmmjWEQPT6rmT',
  'turkce_sozcukte_anlam': 'JmyiPxf3n96Jkxqsa9jY',
  'turkce_cumlede_anlam': 'AJNLHhhaG2SLWOvxDYqW',
  'turkce_paragrafta_anlam': 'nN8JOTR7LZm01AN2i3sQ',
  'turkce_anlatim_bozukluklari': 'jXcsrl5HEb65DmfpfqqI',
  'turkce_yazim_noktalama': 'qSEqigIsIEBAkhcMTyCE',
  'turkce_sozel_mantik': 'wnt2zWaV1pX8p8s8BBc9',
  // COĞRAFYA
  'cografya_konum': '1FEcPsGduhjcQARpaGBk',
  'cografya_fiziki': 'kbs0Ffved9pCP3Hq9M9k',
  'cografya_iklim': '6e0Thsz2RRNHFcwqQXso',
  'cografya_beseri': 'uYDrMlBCEAho5776WZi8',
  'cografya_ekonomik': 'WxrtQ26p2My4uJa0h1kk',
  'cografya_bolgeler': 'GdpN8uxJNGtexWrkoL1T',
  // VATANDAŞLIK
  'vatandaslik_hukuka_giris': 'AQ0Zph76dzPdr87H1uKa',
  'vatandaslik_anayasa': 'n4OjWupHmouuybQzQ1Fc',
  'vatandaslik_1982_anayasa': 'xXGXiqx2TkCtI4C7GMQg',
  'vatandaslik_devlet_organlari': '1JZAYECyEn7farNNyGyx',
  'vatandaslik_idari_yapi': 'lv93cmhwq7RmOFM5WxWD',
  'vatandaslik_guncel': 'Bo3qqooJsqtIZrK5zc9S',
};

final explanationTopicIdMap = {
  'islamiyet_oncesi_turk_tarihi': 'JnFbEQt0uA8RSEuy22SQ',
  'ilk_musluman_turk_devletleri': '9Hg8tuMRdMTuVY7OZ9HL',
  'osmanli_devleti_tarihi': 'rl2xQTfv1iUaCyhFzp5V',
  'kurtulus_savasi_donemi': 'DlT19snCttf5j5RUAXLz',
  'ataturk_ilke_ve_inkilaplari': '4GUvpqBBImcLmN2eh1HK',
  'cumhuriyet_donemi': 'onwrfsH02TgIhlyRUh56',
  'cagdas_turk_ve_dunya_tarihi': 'qBFhnVl9E4oNj8MsBqnB',
  'ses_bilgisi': '80e0wkTLvaTQzPD6puB7',
  'yapi_bilgisi': 'yWlh5C6jB7lzuJOodr2t',
  'sozcuk_turleri': 'ICNDiSlTmmjWEQPT6rmT',
  'sozcukte_anlam': 'JmyiPxf3n96Jkxqsa9jY',
  'cumlede_anlam': 'AJNLHhhaG2SLWOvxDYqW',
  'paragrafta_anlam': 'nN8JOTR7LZm01AN2i3sQ',
  'anlatim_bozukluklari': 'jXcsrl5HEb65DmfpfqqI',
  'yazim_kurallari_ve_noktalama': 'qSEqigIsIEBAkhcMTyCE',
  'sozel_mantik_ve_akil_yurutme': 'wnt2zWaV1pX8p8s8BBc9',
  'turkiyenin_cografi_konumu': '1FEcPsGduhjcQARpaGBk',
  'turkiyenin_fiziki_ozellikleri': 'kbs0Ffved9pCP3Hq9M9k',
  'turkiyenin_iklimi_ve_bitki_ortusu': '6e0Thsz2RRNHFcwqQXso',
  'beseri_cografya': 'uYDrMlBCEAho5776WZi8',
  'ekonomik_cografya': 'WxrtQ26p2My4uJa0h1kk',
  'turkiyenin_cografi_bolgeleri': 'GdpN8uxJNGtexWrkoL1T',
  'hukuka_giris': 'AQ0Zph76dzPdr87H1uKa',
  'anayasa_hukuku': 'n4OjWupHmouuybQzQ1Fc',
  'anayasa_1982_temel_ilkeleri': 'xXGXiqx2TkCtI4C7GMQg',
  'devlet_organlari': '1JZAYECyEn7farNNyGyx',
  'idari_yapi': 'lv93cmhwq7RmOFM5WxWD',
  'guncel_olaylar': 'Bo3qqooJsqtIZrK5zc9S',
};
