import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/repositories/ai_repository.dart';
import '../../../../core/services/ai_coach_ad_service.dart';
import '../../../../core/services/premium_service.dart';
import '../models/chat_message.dart';

mixin AICoachLogicMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final AiRepository _aiRepository = AiRepository();
  
  bool isLoading = false;
  List<ChatMessage> messages = [];
  List<String> quickQuestions = [];
  int remainingQuestions = 10;
  int bonusQuestions = 0;
  bool isPremium = false;
  bool isCheater = false;
  bool isInitialized = false;

  // Constants
  static const int _dailyLimit = 10;
  static const String _keyRemaining = 'ai_coach_remaining';
  static const String _keyLastReset = 'ai_coach_last_reset';
  static const String _keyLastUsed = 'ai_coach_last_used';
  
  static final List<String> _allQuestions = [
    'Tarih\'te hangi dönemlere öncelik vermeliyim?',
    'Coğrafya\'da hangi haritalar mutlaka bilinmeli?',
    'Vatandaşlık ezberlerini nasıl yapmalıyım?',
    'Türkçe paragraf sorularında hız kazanmak istiyorum',
    'Matematik temel kavramları hatırlat',
    'Genel Kültür\'de en çok çıkan konular neler?',
    'Genel Yetenek mantık sorularında nasıl yaklaşmalıyım?',
    'Tarih kronolojisini ezberlemek için yöntem öner',
    'Coğrafya Türkiye haritasını nasıl çalışmalıyım?',
    'Vatandaşlık\'ta anayasa maddelerini nasıl ezberlerim?',
    'Türkçe\'de kelime bilgisi testleri nasıl yapılır?',
    'Matematik\'te oran-orantı problemleri çözümü',
    'Genel Kültür\'de güncel olayları nasıl takip etmeliyim?',
    'KPSS\'ye 6 ay kaldı, çalışma planı yap',
    'Haftada kaç saat KPSS çalışmalıyım?',
    'Son 1 ay sprint çalışması nasıl olmalı?',
    'Pazar gününü çalışma mı dinlenme mı yapmalıyım?',
    'Deneme sınavı sonrası analiz nasıl yapılır?',
    'Yanlışlarımı nasıl değerlendirmeliyim?',
    'Günde kaç soru çözmeliyim?',
    'KPSS puan hesaplama nasıl yapılır?',
    'Aktif tekrar tekniği nedir?',
    'Flashcard nasıl etkili kullanılır?',
    'Pomodoro tekniği KPSS\'ye uyarlanabilir mi?',
    'Not alma yöntemleri öner',
    'Sınav kaygısı nasıl yenilir?',
    'Çalışmaya başlayamıyorum ne yapmalıyım?',
    'Ortalama puanlar beni demoralize ediyor',
    'Sınav günü stratejisi nedir?',
    'KPSS için en iyi kaynaklar hangileri?',
    'Hangi yayınların denemelerini çözmeliyim?',
    'Video ders mi kitap mı öncelikli?',
    'Online kaynak önerisi var mı?',
    'Sabah mı akşam mı çalışmak daha iyi?',
    'Mola süreleri ne kadar olmalı?',
    'Uyku düzeni KPSS başarısını etkiler mi?',
    'Beslenme ve KPSS performansı ilişkisi',
  ];

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    if (!isInitialized) {
      initializeChat();
    }
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> initializeChat() async {
    isPremium = await PremiumService.isPremium();
    bonusQuestions = await AICoachAdService.getBonusQuestions();
    
    await checkAndResetDailyQuota();
    await loadSavedMessages();
    
    if (quickQuestions.isEmpty) {
      selectRandomQuestions();
    }
    
    // Mixin içinde setState çağırırken mounted kontrolü önemli
    if (mounted) {
      setState(() {
        isInitialized = true;
      });
    }
  }

  Future<void> checkAndResetDailyQuota() async {
    if (isPremium) {
      if (mounted) {
        setState(() {
          remainingQuestions = 999;
          isCheater = false;
        });
      }
      return;
    }
    
    final prefs = await _prefs;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    
    final lastResetStr = prefs.getString(_keyLastReset);
    final lastUsedMs = prefs.getInt(_keyLastUsed) ?? 0;
    final savedRemaining = prefs.getInt(_keyRemaining) ?? _dailyLimit;
    
    if (lastUsedMs > 0) {
      final lastUsed = DateTime.fromMillisecondsSinceEpoch(lastUsedMs);
      if (now.isBefore(lastUsed.subtract(const Duration(hours: 1)))) {
        if (mounted) {
          setState(() {
            isCheater = true;
            remainingQuestions = 0;
          });
        }
        return;
      }
    }
    
    if (lastResetStr != todayStr) {
      await prefs.setString(_keyLastReset, todayStr);
      await prefs.setInt(_keyRemaining, _dailyLimit);
      await prefs.setInt(_keyLastUsed, now.millisecondsSinceEpoch);
      
      if (mounted) {
        setState(() {
          remainingQuestions = _dailyLimit;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          remainingQuestions = savedRemaining;
        });
      }
    }
  }

  Future<bool> useQuota() async {
    if (isCheater) {
      showCheaterDialog();
      return false;
    }
    
    if (isPremium) return true;
    
    if (bonusQuestions > 0) {
      final used = await AICoachAdService.useBonusQuestion();
      if (used) {
        if (mounted) {
          setState(() {
            bonusQuestions--;
          });
        }
        return true;
      }
    }
    
    if (remainingQuestions <= 0) {
      showNoQuotaDialog();
      return false;
    }
    
    final prefs = await _prefs;
    final now = DateTime.now();
    
    if (mounted) {
      setState(() {
        remainingQuestions--;
      });
    }
    
    await prefs.setInt(_keyRemaining, remainingQuestions);
    await prefs.setInt(_keyLastUsed, now.millisecondsSinceEpoch);
    
    return true;
  }

  void showCheaterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Uyarı'),
          ],
        ),
        content: const Text(
          'Sistem saatinizde tutarsızlık tespit edildi. '
          'Lütfen cihazınızın tarih ve saat ayarlarını kontrol edin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void showNoQuotaDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_empty_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Günlük Limit'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bugünkü soru hakkınız bitti.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_filled_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Reklam izleyerek +1 soru hakkı kazan!',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              watchRewardedAd();
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Reklam İzle'),
          ),
        ],
      ),
    );
  }

  Future<void> watchRewardedAd() async {
    final canWatch = await AICoachAdService.canWatchAd();
    
    if (!canWatch) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bugünkü reklam limitine ulaştınız. Yarın tekrar deneyin! 🌙'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Reklam yükleniyor...', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              '(Demo: 2 saniye bekleyin)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    Navigator.pop(context);
    
    final success = await AICoachAdService.onAdWatched();
    
    if (success) {
      if (mounted) {
        setState(() {
          bonusQuestions++;
        });
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('+1 Soru hakkı kazandınız! 🎉'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void selectRandomQuestions() {
    final random = Random();
    final selected = <String>[];
    final available = List<String>.from(_allQuestions);
    
    for (int i = 0; i < 8 && available.isNotEmpty; i++) {
      final index = random.nextInt(available.length);
      selected.add(available[index]);
      available.removeAt(index);
    }
    
    if (mounted) {
      setState(() {
        quickQuestions = selected;
      });
    }
  }

  Future<void> loadSavedMessages() async {
    final prefs = await _prefs;
    final savedMessages = prefs.getStringList('ai_coach_messages') ?? [];
    final savedQuestions = prefs.getStringList('ai_coach_quick_questions');
    final savedRemaining = prefs.getInt('ai_coach_remaining_questions');
    
    if (mounted) {
      setState(() {
        if (savedMessages.isEmpty) {
          messages.add(ChatMessage(
            text: 'Merhaba! KPSS koçun benim. Soru sor, yardımcı olayım. Günde 10 soru hakkın var. 🎯',
            isUser: false,
          ));
        } else {
          messages.addAll(
            savedMessages.map((msg) {
              final json = jsonDecode(msg);
              return ChatMessage(
                text: json['text'],
                isUser: json['isUser'],
                isError: json['isError'] ?? false,
              );
            }),
          );
          if (savedQuestions != null && savedQuestions.isNotEmpty) {
            quickQuestions = savedQuestions;
          }
          if (savedRemaining != null) {
            remainingQuestions = savedRemaining;
          }
        }
      });
    }
  }

  Future<void> saveMessages() async {
    final prefs = await _prefs;
    final messagesToSave = messages.map((msg) {
      return jsonEncode({
        'text': msg.text,
        'isUser': msg.isUser,
        'isError': msg.isError,
      });
    }).toList();
    await prefs.setStringList('ai_coach_messages', messagesToSave);
    await prefs.setStringList('ai_coach_quick_questions', quickQuestions);
  }

  Future<void> sendMessage() async {
    if (textController.text.trim().isEmpty || isLoading) return;
    
    final canUse = await useQuota();
    if (!canUse) return;
    
    final userText = textController.text;
    textController.clear();
    
    if (mounted) {
      setState(() {
        messages.add(ChatMessage(text: userText, isUser: true));
        isLoading = true;
      });
    }
    
    scrollToBottom();
    
    try {
      final response = _aiRepository.getCoachingAdviceStreaming(userText, []);
      
      ChatMessage thinkingMessage = ChatMessage(text: 'AI KOÇ düşünüyor.', isUser: false);
      if (mounted) {
        setState(() {
          messages.add(thinkingMessage);
          isLoading = false;
        });
      }

      await Future.delayed(const Duration(milliseconds: 800));
      
      bool isFirstChunk = true;

      await for (final chunk in response) {
        if (mounted) {
          if (isFirstChunk) {
            setState(() {
              messages.removeLast();
              messages.add(ChatMessage(text: chunk, isUser: false));
            });
            isFirstChunk = false;
            scrollToBottom();
          } else {
            setState(() {
              messages[messages.length - 1] = ChatMessage(text: chunk, isUser: false);
            });
          }
          scrollToBottom();
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
      
      if (mounted) {
        setState(() {
          selectRandomQuestions();
        });
        saveMessages();
        scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final prefs = await _prefs;
        setState(() {
          isLoading = false;
          if (messages.isNotEmpty && !messages.last.isUser) {
            messages[messages.length - 1] = ChatMessage(
              text: 'AI Koç şu an meşgul, biraz sonra tekrar dene.',
              isUser: false,
              isError: true,
            );
          } else {
            messages.add(ChatMessage(
              text: 'AI Koç şu an meşgul, biraz sonra tekrar dene.',
              isUser: false,
              isError: true,
            ));
          }
          remainingQuestions++;
        });
        await prefs.setInt(_keyRemaining, remainingQuestions);
        saveMessages();
        scrollToBottom();
      }
    }
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> resetConversation() async {
    if (mounted) {
      setState(() {
        messages.clear();
      });
    }
    await saveMessages();
    await initializeChat(); // Reload welcome message
  }
}
