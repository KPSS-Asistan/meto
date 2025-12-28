import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/guest_prompt_service.dart';

/// Dashboard'da gösterilecek kayıt teşvik banner'ı
/// HTML tasarımına uygun: Turuncu/amber tema ile uyarı kartı
class RegistrationBanner extends StatefulWidget {
  const RegistrationBanner({super.key});

  @override
  State<RegistrationBanner> createState() => _RegistrationBannerState();
}

class _RegistrationBannerState extends State<RegistrationBanner> {
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    _checkVisibility();
  }

  Future<void> _checkVisibility() async {
    if (!GuestPromptService.isAnonymous()) return;
    
    final shouldShow = await GuestPromptService().shouldShowProgressPrompt();
    
    if (mounted) {
      setState(() {
        _shouldShow = shouldShow;
      });
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    context.push('/auth');
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Dashboard uyumlu minimal banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
              width: 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Cloud icon
              Icon(
                LucideIcons.cloudUpload,
                color: const Color(0xFFEF9608),
                size: 20,
              ),
              
              const SizedBox(width: 10),
              
              // Tek satır metin
              Expanded(
                child: Text(
                  'Verilerini kaydet',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                  ),
                ),
              ),
              
              const SizedBox(width: 10),
              
              // CTA Button - Dashboard uyumlu
              GestureDetector(
                onTap: _goToLogin,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E6EEA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Kayıt Ol',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Alt Divider
        const SizedBox(height: 14),
        Container(
          height: 1,
          color: isDark 
              ? const Color(0xFF475569)
              : const Color(0xFFCBD5E1),
        ),
        const SizedBox(height: 14),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

