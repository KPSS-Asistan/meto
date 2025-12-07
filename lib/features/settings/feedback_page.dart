import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Geri Bildirim Sayfası - Modern ve Minimalist
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _controller = TextEditingController();
  String _selectedType = 'suggestion';
  bool _isSending = false;

  static const _primaryBlue = Color(0xFF6366F1);

  final _types = [
    {'id': 'suggestion', 'title': 'Öneri', 'icon': Icons.lightbulb_outline_rounded, 'color': Color(0xFFF59E0B)},
    {'id': 'bug', 'title': 'Hata Bildirimi', 'icon': Icons.bug_report_outlined, 'color': Color(0xFFEF4444)},
    {'id': 'question', 'title': 'Soru', 'icon': Icons.help_outline_rounded, 'color': Color(0xFF6366F1)},
    {'id': 'other', 'title': 'Diğer', 'icon': Icons.more_horiz_rounded, 'color': Color(0xFF64748B)},
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen mesajınızı yazın'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    
    try {
      // Firebase'e kaydet
      final user = FirebaseAuth.instance.currentUser;
      final typeInfo = _types.firstWhere((t) => t['id'] == _selectedType);
      
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'message': message,
        'type': _selectedType,
        'typeName': typeInfo['title'],
        'userId': user?.uid,
        'userEmail': user?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new', // new, read, resolved
        'platform': Platform.isAndroid ? 'android' : 'ios'
      });
      
      if (mounted) {
        setState(() => _isSending = false);
        _controller.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geri bildiriminiz alındı. Teşekkürler! 🙏'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
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
        title: const Text('Geri Bildirim', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_primaryBlue, _primaryBlue.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.feedback_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text('Görüşleriniz Bizim İçin Değerli', 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('Uygulamayı geliştirmemize yardımcı olun',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 20),

          // Türü Seç
          Text('Geri Bildirim Türü', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: subtextColor)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _types.map((t) {
              final isSelected = _selectedType == t['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedType = t['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? (t['color'] as Color).withValues(alpha: 0.15) : cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? t['color'] as Color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t['icon'] as IconData, color: t['color'] as Color, size: 20),
                      const SizedBox(width: 8),
                      Text(t['title'] as String, style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? t['color'] as Color : textColor,
                      )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),

          // Mesaj
          Text('Mesajınız', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: subtextColor)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
            child: TextField(
              controller: _controller,
              maxLines: 6,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Düşüncelerinizi paylaşın...',
                hintStyle: TextStyle(color: subtextColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),

          // Gönder Butonu
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSending
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded),
                        SizedBox(width: 8),
                        Text('Gönder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
