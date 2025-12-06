import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:kpss_2026/core/services/local_progress_service.dart';
import 'package:kpss_2026/core/services/notification_service.dart';
import 'package:kpss_2026/core/services/quiz_session_service.dart';
import 'package:kpss_2026/core/services/quiz_stats_service.dart';
import 'package:kpss_2026/core/services/study_schedule_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ayarlar Sayfası - Modern ve Minimalist
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _dailyReminder = true;
  bool _streakAlert = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _reminderTime = '20:00';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _dailyReminder = prefs.getBool('daily_reminder') ?? true;
      _streakAlert = prefs.getBool('streak_alert') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _reminderTime = prefs.getString('reminder_time') ?? '20:00';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          // Görünüm
          _buildSection('Görünüm', cardColor, textColor, subtextColor, [
            _buildSwitchTile(
              icon: Icons.dark_mode_rounded,
              title: 'Karanlık Mod',
              subtitle: 'Göz yorgunluğunu azalt',
              value: _darkMode,
              color: const Color(0xFF6366F1),
              onChanged: (v) {
                setState(() => _darkMode = v);
                unawaited(_saveSetting('dark_mode', v));
              },
            ),
          ]),
          const SizedBox(height: 16),

          // Bildirimler
          _buildSection('Bildirimler', cardColor, textColor, subtextColor, [
            _buildSwitchTile(
              icon: Icons.notifications_active_rounded,
              title: 'Günlük Hatırlatıcı',
              subtitle: 'Her gün çalışmayı unutma',
              value: _dailyReminder,
              color: const Color(0xFF10B981),
              onChanged: (v) async {
                setState(() => _dailyReminder = v);
                await _saveSetting('daily_reminder', v);
                if (v) {
                  // Bildirimi planla
                  final parts = _reminderTime.split(':');
                  await NotificationService.scheduleDailyReminder(
                    hour: int.parse(parts[0]),
                    minute: int.parse(parts[1]),
                  );
                } else {
                  // Bildirimi iptal et
                  await NotificationService.cancelDailyReminder();
                }
              },
            ),
            if (_dailyReminder)
              _buildTapTile(
                icon: Icons.access_time_rounded,
                title: 'Hatırlatma Saati',
                subtitle: _reminderTime,
                color: const Color(0xFFF59E0B),
                onTap: () => _showTimePicker(context),
              ),
            _buildSwitchTile(
              icon: Icons.local_fire_department_rounded,
              title: 'Seri Uyarısı',
              subtitle: 'Gece 22:00\'de hatırlat',
              value: _streakAlert,
              color: const Color(0xFFEF4444),
              onChanged: (v) async {
                setState(() => _streakAlert = v);
                await _saveSetting('streak_alert', v);
                if (v) {
                  await NotificationService.scheduleStreakAlert();
                } else {
                  await NotificationService.cancelStreakAlert();
                }
              },
            ),
          ]),
          const SizedBox(height: 16),

          // Ses ve Titreşim
          _buildSection('Ses & Titreşim', cardColor, textColor, subtextColor, [
            _buildSwitchTile(
              icon: Icons.volume_up_rounded,
              title: 'Ses Efektleri',
              subtitle: 'Doğru/yanlış cevap sesleri',
              value: _soundEnabled,
              color: const Color(0xFF8B5CF6),
              onChanged: (v) {
                setState(() => _soundEnabled = v);
                unawaited(_saveSetting('sound_enabled', v));
              },
            ),
            _buildSwitchTile(
              icon: Icons.vibration_rounded,
              title: 'Titreşim',
              subtitle: 'Dokunsal geri bildirim',
              value: _vibrationEnabled,
              color: const Color(0xFFEC4899),
              onChanged: (v) {
                setState(() => _vibrationEnabled = v);
                unawaited(_saveSetting('vibration_enabled', v));
              },
            ),
          ]),
          const SizedBox(height: 16),

          // Veri Yönetimi
          _buildSection('Veri Yönetimi', cardColor, textColor, subtextColor, [
            _buildTapTile(
              icon: Icons.refresh_rounded,
              title: 'İlerlemeyi Sıfırla',
              subtitle: 'Tüm istatistikleri temizle',
              color: const Color(0xFFF59E0B),
              onTap: () => _showResetDialog(context),
            ),
          ]),
          const SizedBox(height: 16),

          // Hesap
          _buildSection('Hesap', cardColor, textColor, subtextColor, [
            _buildTapTile(
              icon: Icons.logout_rounded,
              title: 'Çıkış Yap',
              subtitle: 'Hesabından çıkış yap',
              color: const Color(0xFF6366F1),
              onTap: () => _showLogoutDialog(context),
            ),
            _buildTapTile(
              icon: Icons.delete_forever_rounded,
              title: 'Hesabı Sil',
              subtitle: 'Tüm verilerin kalıcı olarak silinir',
              color: const Color(0xFFEF4444),
              onTap: () => _showDeleteAccountDialog(context),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Color cardColor, Color textColor, Color subtextColor, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subtextColor)),
        ),
        Container(
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
          child: Column(children: children),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: color, size: 24),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: subtextColor)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: color,
        thumbColor: WidgetStateProperty.all(Colors.white),
      ),
    );
  }

  Widget _buildTapTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: color, size: 24),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: subtextColor)),
      trailing: Icon(Icons.chevron_right_rounded, color: subtextColor),
      onTap: onTap,
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final parts = _reminderTime.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    
    if (picked != null) {
      final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _reminderTime = newTime);
      await _saveSetting('reminder_time', newTime);
      
      // Bildirimi yeni saatle güncelle
      if (_dailyReminder) {
        await NotificationService.scheduleDailyReminder(
          hour: picked.hour,
          minute: picked.minute,
        );
      }
    }
  }

  Future<void> _showResetDialog(BuildContext context) async {
    final confirmed = await _showModernDialog(
      context: context,
      icon: Icons.refresh_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: 'İlerlemeyi Sıfırla',
      message: 'Tüm veriler silinecek:\n\n• Quiz istatistikleri\n• Konu ilerlemesi\n• Flashcard ilerlemesi\n• Yanlış cevaplar\n• Streak bilgisi\n\nBu işlem geri alınamaz.',
      confirmText: 'Tümünü Sıfırla',
      confirmColor: const Color(0xFFF59E0B),
    );

    if (confirmed == true && mounted) {
      // Tüm servisleri sıfırla
      await QuizStatsService.reset();
      
      final localProgress = await LocalProgressService.getInstance();
      await localProgress.clearAllData();
      
      await QuizSessionService.clearAllSessions();
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Tüm veriler sıfırlandı!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await _showModernDialog(
      context: context,
      icon: Icons.logout_rounded,
      iconColor: const Color(0xFF6366F1),
      title: 'Çıkış Yap',
      message: 'Hesabından çıkış yapmak istediğine emin misin?',
      confirmText: 'Çıkış Yap',
      confirmColor: const Color(0xFF6366F1),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        if (!context.mounted) return;
        context.go('/auth');
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yapılamadı: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await _showModernDialog(
      context: context,
      icon: Icons.delete_forever_rounded,
      iconColor: const Color(0xFFEF4444),
      title: 'Hesabı Sil',
      message: '⚠️ DİKKAT!\n\nBu işlem geri alınamaz. Tüm verileriniz kalıcı olarak silinecek:\n\n• Quiz istatistikleri\n• Çalışma geçmişi\n• Hesap bilgileri',
      confirmText: 'Hesabı Kalıcı Olarak Sil',
      confirmColor: const Color(0xFFEF4444),
      isDangerous: true,
    );

    if (confirmed == true && mounted) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('Kullanıcı bulunamadı');
        }
        
        // Tüm local verileri sil
        await QuizStatsService.reset();
        final localProgress = await LocalProgressService.getInstance();
        await localProgress.clearAllData();
        await QuizSessionService.clearAllSessions();
        await StudyScheduleService.clearSchedule();
        
        // SharedPreferences tamamen temizle
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        // Sonra hesabı sil
        await user.delete();
        
        if (!context.mounted) return;
        context.go('/auth');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hesabınız silindi. Hoşça kalın! 👋'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (!context.mounted) return;
        
        String errorMessage;
        if (e.code == 'requires-recent-login') {
          errorMessage = 'Güvenlik için tekrar giriş yapmanız gerekiyor. Lütfen çıkış yapıp tekrar giriş yapın.';
        } else {
          errorMessage = 'Hesap silinemedi: ${e.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 5),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<bool?> _showModernDialog({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    bool isDangerous = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: subtextColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              message,
              style: TextStyle(fontSize: 14, color: subtextColor, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: subtextColor.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'İptal',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: subtextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
          ],
        ),
      ),
    );
  }
}
