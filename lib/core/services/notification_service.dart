import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Bildirim Servisi - Push & Local Notifications
/// 
/// Özellikler:
/// - Günlük çalışma hatırlatıcısı
/// - Streak uyarısı (gece yarısından önce)
/// - Motivasyon bildirimleri
/// - Push notifications (Firebase Messaging)
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Notification Channel IDs
  static const String _dailyReminderChannelId = 'daily_reminder';
  static const String _streakChannelId = 'streak_alert';
  static const String _motivationChannelId = 'motivation';
  static const String _generalChannelId = 'general';
  
  // SharedPreferences Keys
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyDailyReminderTime = 'daily_reminder_time';
  static const String _keyStreakAlertEnabled = 'streak_alert_enabled';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Bildirim servisini başlat
  static Future<void> initialize() async {
    // Timezone'u başlat
    tz.initializeTimeZones();
    
    // Android ayarları
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS ayarları
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Android notification channels oluştur
    await _createNotificationChannels();
    
    // Firebase Messaging ayarları
    await _setupFirebaseMessaging();
    
    // Varsayılan bildirimleri planla
    await _scheduleDefaultNotifications();
  }
  
  /// Android notification channels oluştur
  static Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Günlük hatırlatıcı kanalı
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _dailyReminderChannelId,
          'Günlük Hatırlatıcı',
          description: 'Günlük çalışma hatırlatmaları',
          importance: Importance.high,
        ),
      );
      
      // Streak uyarı kanalı
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _streakChannelId,
          'Seri Uyarısı',
          description: 'Çalışma serisi uyarıları',
          importance: Importance.high,
        ),
      );
      
      // Motivasyon kanalı
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _motivationChannelId,
          'Motivasyon',
          description: 'Motivasyon bildirimleri',
          importance: Importance.defaultImportance,
        ),
      );
      
      // Genel kanal
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _generalChannelId,
          'Genel',
          description: 'Genel bildirimler',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }
  
  /// Firebase Messaging ayarları
  static Future<void> _setupFirebaseMessaging() async {
    // Foreground mesajları dinle
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Background mesaj handler
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Token al (debug için)
    if (kDebugMode) {
      final token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
    }
  }
  
  /// Foreground mesaj handler
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    
    // Local notification göster
    if (message.notification != null) {
      showNotification(
        title: message.notification!.title ?? 'KPSS Asistan',
        body: message.notification!.body ?? '',
      );
    }
  }
  
  /// Background mesaj handler
  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background message: ${message.notification?.title}');
  }
  
  /// Bildirime tıklandığında
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Deep linking ile ilgili sayfaya yönlendir
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PERMISSIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Bildirim izni iste
  static Future<bool> requestPermission() async {
    // permission_handler ile izin kontrolü
    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      // iOS için ek izinler
      if (Platform.isIOS) {
        await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        await _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
      return true;
    }
    
    return false;
  }
  
  /// Bildirim izni durumu
  static Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
  
  /// İzin kalıcı olarak reddedilmiş mi?
  static Future<bool> isPermissionPermanentlyDenied() async {
    final status = await Permission.notification.status;
    return status.isPermanentlyDenied;
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // LOCAL NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Anlık bildirim göster
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = _generalChannelId,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == _dailyReminderChannelId ? 'Günlük Hatırlatıcı' :
      channelId == _streakChannelId ? 'Seri Uyarısı' :
      channelId == _motivationChannelId ? 'Motivasyon' : 'Genel',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  /// Günlük hatırlatıcı planla
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    // Mevcut hatırlatıcıyı iptal et
    await _localNotifications.cancel(1);
    
    // Yeni hatırlatıcı planla
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // Eğer bugünkü saat geçtiyse yarına planla
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    final androidDetails = AndroidNotificationDetails(
      _dailyReminderChannelId,
      'Günlük Hatırlatıcı',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    try {
      await _localNotifications.zonedSchedule(
        1, // Sabit ID - günlük hatırlatıcı
        '📚 Çalışma Zamanı!',
        'Bugünkü hedeflerini tamamlamayı unutma. Başarı düzenli çalışmayla gelir!',
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Her gün tekrarla
      );
    } catch (e) {
      // Android 12+ exact alarm izni yoksa sessizce devam et
      debugPrint('⚠️ Exact alarm izni yok, bildirim planlanamadı: $e');
    }
    
    // Ayarı kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDailyReminderTime, '$hour:$minute');
  }
  
  /// Streak uyarısı planla (gece 22:00)
  static Future<void> scheduleStreakAlert() async {
    // Mevcut uyarıyı iptal et
    await _localNotifications.cancel(2);
    
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 22, 0);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    final androidDetails = AndroidNotificationDetails(
      _streakChannelId,
      'Seri Uyarısı',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    try {
      await _localNotifications.zonedSchedule(
        2, // Sabit ID - streak uyarısı
        '🔥 Serin Tehlikede!',
        'Bugün henüz çalışmadın. Serini kaybetmemek için hemen başla!',
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // Android 12+ exact alarm izni yoksa sessizce devam et
      debugPrint('⚠️ Streak alarm izni yok, bildirim planlanamadı: $e');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStreakAlertEnabled, true);
  }
  
  /// Varsayılan bildirimleri planla
  static Future<void> _scheduleDefaultNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
    
    if (!enabled) return;
    
    // Günlük hatırlatıcı (varsayılan 19:00)
    final reminderTime = prefs.getString(_keyDailyReminderTime);
    if (reminderTime == null) {
      await scheduleDailyReminder(hour: 19, minute: 0);
    } else {
      final parts = reminderTime.split(':');
      await scheduleDailyReminder(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    
    // Streak uyarısı
    final streakEnabled = prefs.getBool(_keyStreakAlertEnabled) ?? true;
    if (streakEnabled) {
      await scheduleStreakAlert();
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Bildirimleri aç/kapat
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
    
    if (enabled) {
      await _scheduleDefaultNotifications();
    } else {
      await cancelAllNotifications();
    }
  }
  
  /// Tüm bildirimleri iptal et
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
  
  /// Günlük hatırlatıcıyı iptal et
  static Future<void> cancelDailyReminder() async {
    await _localNotifications.cancel(1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDailyReminderTime);
  }
  
  /// Streak uyarısını iptal et
  static Future<void> cancelStreakAlert() async {
    await _localNotifications.cancel(2);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStreakAlertEnabled, false);
  }
  
  /// Bugün çalışıldığını bildir (streak uyarısını iptal et)
  static Future<void> markTodayAsStudied() async {
    // Bugünkü streak uyarısını iptal et
    await _localNotifications.cancel(2);
    
    // Yarın için yeniden planla
    await scheduleStreakAlert();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MOTIVATION NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Motivasyon bildirimi gönder
  static Future<void> sendMotivationNotification() async {
    final messages = [
      ('💪 Harika Gidiyorsun!', 'Her gün bir adım daha yakınsın hedefe.'),
      ('🎯 Odaklan!', 'Bugün de hedeflerini tamamla, başarı senin!'),
      ('🌟 Sen Yaparsın!', 'Binlerce öğrenci başardı, sıra sende!'),
      ('📚 Çalışma Vakti!', 'Küçük adımlar, büyük başarılar getirir.'),
      ('🚀 İlerle!', 'Her çözdüğün soru seni bir adım öne taşır.'),
    ];
    
    final random = DateTime.now().millisecondsSinceEpoch % messages.length;
    final message = messages[random];
    
    await showNotification(
      title: message.$1,
      body: message.$2,
      channelId: _motivationChannelId,
    );
  }
}
