import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kpss_2026/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GitHub Raw URL üzerinden modüler veri senkronizasyonu
/// Her konu (topic) ayrı ayrı güncellenebilir
/// 
/// GITHUB REPO YAPISI:
/// kpss-data/
/// ├── version.json                    # Tüm versiyonlar
/// ├── questions/{topicId}.json        # Her konu için ayrı soru dosyası
/// ├── flashcards/{topicId}.json       # Her konu için ayrı flashcard
/// ├── stories/{topicId}.json          # Her konu için ayrı hikaye
/// ├── explanations/{topicId}.json     # Her konu için ayrı konu anlatımı
/// └── matching_games/{topicId}.json   # Her konu için ayrı eşleştirme
///
/// KULLANIM:
/// 1. Yeni içerik eklemek için: İlgili JSON dosyasını güncelle
/// 2. version.json'da ilgili topic versiyonunu artır
/// 3. GitHub'a commit at
/// 4. Uygulama otomatik indirir
class GitHubSyncService {
  static final GitHubSyncService _instance = GitHubSyncService._internal();
  factory GitHubSyncService() => _instance;
  GitHubSyncService._internal();

  // ═══════════════════════════════════════════════════════════════════════════
  // GITHUB AYARLARI
  // ═══════════════════════════════════════════════════════════════════════════
  static const String _username = 'mertcanasdf';
  static const String _repo = 'meto';
  static const String _branch = 'main';
  
  // Private repo için GitHub token (Settings > Tokens > repo yetkisi)
  // Build: flutter build apk --dart-define=GITHUB_TOKEN=xxx
  // ⚠️ GÜVENLİK: Token ASLA hardcode edilmemeli, sadece dart-define ile geçilmeli
  static const String _token = String.fromEnvironment('GITHUB_TOKEN');
  
  // Token yoksa public repo olarak davran (raw.githubusercontent.com)
  // Token varsa private repo olarak davran (api.github.com)
  static bool get _isPrivate => _token.isNotEmpty;
  
  static String get _repoBase => _isPrivate 
      ? 'https://api.github.com/repos/$_username/$_repo/contents'
      : 'https://raw.githubusercontent.com/$_username/$_repo/$_branch';
  
  static String get _versionUrl => _isPrivate
      ? '$_repoBase/version.json'
      : '$_repoBase/version.json';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // VERİ TİPLERİ
  // ═══════════════════════════════════════════════════════════════════════════
  static const String typeQuestions = 'questions';
  static const String typeFlashcards = 'flashcards';
  static const String typeStories = 'stories';
  static const String typeExplanations = 'explanations';
  static const String typeMatchingGames = 'matching_games';
  
  static const List<String> allTypes = [
    typeQuestions,
    typeFlashcards,
    typeStories,
    typeExplanations,
    typeMatchingGames,
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHE KEY'LERİ
  // ═══════════════════════════════════════════════════════════════════════════
  static String _versionKey(String type, String topicId) => 'github_${type}_${topicId}_version';
  static String _dataKey(String type, String topicId) => 'github_${type}_${topicId}_data';
  static const String _lastSyncKey = 'github_last_sync';
  static const String _versionsKey = 'github_versions_cache';

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  
  // Cached versions
  Map<String, dynamic>? _remoteVersions;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANA SYNC FONKSİYONLARI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tüm veri tiplerini senkronize et
  /// force: true ise günlük limiti atla
  Future<MultiSyncResult> syncAll({bool force = false}) async {
    AppLogger.info('🚀 GitHubSyncService.syncAll() başlatıldı');
    
    if (_isSyncing) {
      AppLogger.warning('⚠️ Sync zaten devam ediyor, atlanıyor');
      return MultiSyncResult(success: false, message: 'Sync zaten devam ediyor');
    }
    
    // ⚡ GÜNDE 1 KERE: Son kontrolden 24 saat geçmediyse skip et
    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt('github_last_version_check') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceLastCheck = (now - lastCheck) / (1000 * 60 * 60);
      
      if (hoursSinceLastCheck < 24) {
        AppLogger.info('⏭️ Son versiyon kontrolünden ${hoursSinceLastCheck.toStringAsFixed(1)} saat geçti, 24 saat dolmadı - skip');
        return MultiSyncResult(success: true, message: 'Günlük kontrol limiti - ${(24 - hoursSinceLastCheck).toStringAsFixed(0)} saat sonra tekrar denenecek');
      }
    }
    
    _isSyncing = true;
    
    try {
      // 1. Version.json'u indir
      final versions = await _fetchRemoteVersions();
      AppLogger.debug('📋 Versions fetched: ${versions?.keys.toList()}');
      if (versions == null) {
        AppLogger.warning('❌ Versions null, sync iptal');
        _isSyncing = false;
        return MultiSyncResult(success: false, message: 'Versiyon bilgisi alınamadı');
      }
      
      final results = <String, SyncResult>{};
      int totalDownloaded = 0;
      
      // 2. Her veri tipi için kontrol et
      for (final type in allTypes) {
        final typeVersions = versions[type] as Map<String, dynamic>?;
        if (typeVersions == null) continue;
        
        // Her topic için kontrol et
        for (final entry in typeVersions.entries) {
          final topicId = entry.key;
          final remoteVersion = entry.value as int? ?? 0;
          
          final result = await _syncTopic(type, topicId, remoteVersion);
          results['${type}_$topicId'] = result;
          
          if (result.downloaded) totalDownloaded++;
        }
      }
      
      // 3. Son sync zamanını kaydet + versiyon kontrol zamanı
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      await prefs.setInt('github_last_version_check', DateTime.now().millisecondsSinceEpoch);
      
      _isSyncing = false;
      return MultiSyncResult(
        success: true,
        message: '$totalDownloaded içerik güncellendi',
        results: results,
        downloadedCount: totalDownloaded,
      );
      
    } catch (e) {
      AppLogger.error('❌ Sync hatası', e);
      _isSyncing = false;
      return MultiSyncResult(success: false, message: 'Hata: $e');
    }
  }

  /// Belirli bir veri tipini senkronize et (örn: sadece flashcards)
  Future<MultiSyncResult> syncType(String type) async {
    try {
      final versions = await _fetchRemoteVersions();
      if (versions == null) {
        return MultiSyncResult(success: false, message: 'Versiyon bilgisi alınamadı');
      }
      
      final typeVersions = versions[type] as Map<String, dynamic>?;
      if (typeVersions == null) {
        return MultiSyncResult(success: false, message: '$type için versiyon bulunamadı');
      }
      
      final results = <String, SyncResult>{};
      int totalDownloaded = 0;
      
      for (final entry in typeVersions.entries) {
        final topicId = entry.key;
        final remoteVersion = entry.value as int? ?? 0;
        
        final result = await _syncTopic(type, topicId, remoteVersion);
        results['${type}_$topicId'] = result;
        
        if (result.downloaded) totalDownloaded++;
      }
      
      return MultiSyncResult(
        success: true,
        message: '$totalDownloaded $type güncellendi',
        results: results,
        downloadedCount: totalDownloaded,
      );
      
    } catch (e) {
      return MultiSyncResult(success: false, message: 'Hata: $e');
    }
  }

  /// Belirli bir topic'i senkronize et
  Future<SyncResult> syncTopic(String type, String topicId) async {
    try {
      final versions = await _fetchRemoteVersions();
      if (versions == null) {
        return SyncResult(success: false, message: 'Versiyon bilgisi alınamadı', downloaded: false);
      }
      
      final typeVersions = versions[type] as Map<String, dynamic>?;
      final remoteVersion = typeVersions?[topicId] as int? ?? 0;
      
      return await _syncTopic(type, topicId, remoteVersion);
      
    } catch (e) {
      return SyncResult(success: false, message: 'Hata: $e', downloaded: false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL SYNC
  // ═══════════════════════════════════════════════════════════════════════════

  Future<SyncResult> _syncTopic(String type, String topicId, int remoteVersion) async {
    final prefs = await SharedPreferences.getInstance();
    final localVersion = prefs.getInt(_versionKey(type, topicId)) ?? 0;
    
    // Versiyon kontrolü - güncelleme yoksa indirme
    if (remoteVersion <= localVersion) {
      AppLogger.debug('⏭️ $type/$topicId güncel (local:$localVersion >= remote:$remoteVersion)');
      return SyncResult(
        success: true,
        message: 'Güncel',
        downloaded: false,
        localVersion: localVersion,
        remoteVersion: remoteVersion,
      );
    }
    
    AppLogger.info('📥 $type/$topicId indiriliyor (local:$localVersion -> remote:$remoteVersion)');
    
    // Yeni veri indir
    try {
      final url = '$_repoBase/$type/$topicId.json';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        return SyncResult(
          success: false,
          message: 'İndirilemedi: ${response.statusCode}',
          downloaded: false,
        );
      }
      
      // Private repo: GitHub API might return base64 encoded content
      String content = response.body;
      if (_isPrivate && response.body.trim().startsWith('{')) {
        try {
          final apiResponse = jsonDecode(response.body);
          if (apiResponse is Map<String, dynamic> && apiResponse.containsKey('content')) {
            final base64Content = apiResponse['content'] as String?;
            if (base64Content != null) {
              final cleanBase64 = base64Content.replaceAll('\n', '').replaceAll('\r', '');
              content = utf8.decode(base64Decode(cleanBase64));
            }
          }
        } catch (_) {
          // Response zaten raw content, base64 değil
        }
      }
      
      // Kaydet
      await prefs.setString(_dataKey(type, topicId), content);
      await prefs.setInt(_versionKey(type, topicId), remoteVersion);
      
      AppLogger.success('✅ $type/$topicId v$remoteVersion indirildi');
      
      return SyncResult(
        success: true,
        message: 'İndirildi',
        downloaded: true,
        localVersion: remoteVersion,
        remoteVersion: remoteVersion,
      );
      
    } catch (e) {
      AppLogger.error('❌ $type/$topicId indirilemedi', e);
      return SyncResult(
        success: false,
        message: 'Hata: $e',
        downloaded: false,
      );
    }
  }

  /// HTTP headers (private repo için token ekler)
  static Map<String, String> get _headers => _isPrivate
      ? {
          'Authorization': 'token $_token',
          'Accept': 'application/vnd.github.v3.raw',
        }
      : {};

  Future<Map<String, dynamic>?> _fetchRemoteVersions() async {
    try {
      AppLogger.debug('🔍 Fetching versions from: $_versionUrl');
      final response = await http.get(
        Uri.parse(_versionUrl),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
      
      AppLogger.debug('📡 Version response: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        AppLogger.warning('❌ Version fetch failed: ${response.statusCode}');
        return null;
      }
      
      // Private repo: GitHub API might return base64 encoded content
      String content = response.body;
      if (_isPrivate && response.body.trim().startsWith('{')) {
        try {
          final apiResponse = jsonDecode(response.body);
          if (apiResponse is Map<String, dynamic> && apiResponse.containsKey('content')) {
            final base64Content = apiResponse['content'] as String?;
            if (base64Content != null) {
              final cleanBase64 = base64Content.replaceAll('\n', '').replaceAll('\r', '');
              content = utf8.decode(base64Decode(cleanBase64));
            }
          } else {
            // Zaten parsed JSON, content olarak kullan
            _remoteVersions = apiResponse;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_versionsKey, response.body);
            return _remoteVersions;
          }
        } catch (_) {
          // Response raw content
        }
      }
      
      _remoteVersions = jsonDecode(content);
      
      // Cache'le
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_versionsKey, response.body);
      
      return _remoteVersions;
      
    } catch (e) {
      AppLogger.error('❌ Version fetch error', e);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VERİ OKUMA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Belirli bir topic için cache'lenmiş veriyi al
  Future<String?> getData(String type, String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dataKey(type, topicId));
  }

  /// Belirli bir topic için cache'lenmiş veriyi JSON olarak al
  Future<dynamic> getDataAsJson(String type, String topicId) async {
    final data = await getData(type, topicId);
    if (data == null) return null;
    try {
      return jsonDecode(data);
    } catch (e) {
      return null;
    }
  }

  /// Belirli bir veri tipi için tüm cache'lenmiş topic'leri al
  Future<Map<String, dynamic>> getAllData(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final prefix = 'github_${type}_';
    final suffix = '_data';
    
    final result = <String, dynamic>{};
    
    for (final key in allKeys) {
      if (key.startsWith(prefix) && key.endsWith(suffix)) {
        final topicId = key.substring(prefix.length, key.length - suffix.length);
        final data = prefs.getString(key);
        if (data != null) {
          try {
            result[topicId] = jsonDecode(data);
          } catch (e) {
            // Skip invalid JSON
          }
        }
      }
    }
    
    return result;
  }

  /// Lokal versiyon bilgisini al
  Future<int> getLocalVersion(String type, String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_versionKey(type, topicId)) ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHE YÖNETİMİ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tüm cache'i temizle
  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys().where((k) => k.startsWith('github_')).toList();
    
    for (final key in allKeys) {
      await prefs.remove(key);
    }
    
    AppLogger.info('🗑️ Tüm GitHub cache temizlendi (${allKeys.length} key)');
  }

  /// Belirli bir veri tipi için cache'i temizle
  Future<void> clearTypeCache(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys().where((k) => k.startsWith('github_${type}_')).toList();
    
    for (final key in allKeys) {
      await prefs.remove(key);
    }
    
    AppLogger.info('🗑️ $type cache temizlendi (${allKeys.length} key)');
  }

  /// Son sync zamanını al
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_lastSyncKey);
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ESKİ API UYUMLULUĞU (questions için)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Eski API: Tüm soruları senkronize et
  Future<SyncResult> syncQuestions() async {
    final result = await syncType(typeQuestions);
    return SyncResult(
      success: result.success,
      message: result.message,
      downloaded: result.downloadedCount > 0,
      downloadedCount: result.downloadedCount,
    );
  }

  /// Eski API: Tüm soruları al
  Future<String?> getLocalQuestionsJson() async {
    final allData = await getAllData(typeQuestions);
    if (allData.isEmpty) return null;
    
    // Tüm soruları birleştir
    final allQuestions = <dynamic>[];
    for (final topicData in allData.values) {
      if (topicData is List) {
        allQuestions.addAll(topicData);
      }
    }
    
    return jsonEncode(allQuestions);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESULT CLASSES
// ═══════════════════════════════════════════════════════════════════════════

/// Tek bir topic için senkronizasyon sonucu
class SyncResult {
  final bool success;
  final String message;
  final bool downloaded;
  final int? localVersion;
  final int? remoteVersion;
  final int? downloadedCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.downloaded,
    this.localVersion,
    this.remoteVersion,
    this.downloadedCount,
  });

  @override
  String toString() => 'SyncResult(success: $success, downloaded: $downloaded)';
}

/// Çoklu senkronizasyon sonucu
class MultiSyncResult {
  final bool success;
  final String message;
  final Map<String, SyncResult>? results;
  final int downloadedCount;

  MultiSyncResult({
    required this.success,
    required this.message,
    this.results,
    this.downloadedCount = 0,
  });

  @override
  String toString() => 'MultiSyncResult(success: $success, downloaded: $downloadedCount)';
}
