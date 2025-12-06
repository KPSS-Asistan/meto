import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizHardcodedPage extends StatefulWidget {
  const QuizHardcodedPage({super.key});

  @override
  State<QuizHardcodedPage> createState() => _QuizHardcodedPageState();
}

class _QuizHardcodedPageState extends State<QuizHardcodedPage> {
  int _elapsedSeconds = 0;
  Timer? _timer;
  static const int _maxSeconds = 1200; // 20 dakika
  bool _isFavorite = false;
  
  // Hardcoded State
  int? _selectedOption;
  bool _isAnswered = false;
  final int _correctAnswerIndex = 3; // D şıkkı

  final String _questionText = "İslamiyet öncesi Türk toplumunda, göçebe yaşam tarzının şekillendirdiği gündelik hayat pratikleri içerisinde, temel geçim kaynağı olan hayvancılığın sosyal hayata yansımaları gözlemlenmektedir.\nAşağıdakilerden hangisi bu yansımalardan biri değildir?";

  final List<String> _options = [
    "Konutların kolayca sökülüp takılabilir ve taşınabilir olması",
    "Beslenme alışkanlıklarının et ve süt ürünlerine dayanması",
    "Giyim kuşamda deri ve yün ürünlerinin yaygın olarak kullanılması",
    "Ekonomik zenginliğin toprak mülkiyeti ile ölçülmesi",
    "Ailelerin geniş sürülere sahip olmasının sosyal statülerini yükseltmesi",
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_elapsedSeconds >= _maxSeconds) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _handleOptionSelect(int index) {
    if (_isAnswered) return;
    setState(() {
      _selectedOption = index;
    });
  }

  void _handleSubmit() {
    if (_selectedOption == null) return;
    setState(() {
      _isAnswered = true;
    });
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // Progress calculation (Hardcoded as 1/1 for this view)
    const double progress = 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 24),
                            onPressed: () => context.pop(),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF5F5F5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Flag Icon moved to header as requested
                          IconButton(
                            icon: const Icon(Icons.flag_outlined, size: 22),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Soru bildirildi')),
                              );
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF5F5F5),
                              foregroundColor: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 22,
                              color: _isFavorite ? const Color(0xFFEF4444) : null,
                            ),
                            onPressed: () {
                              setState(() {
                                _isFavorite = !_isFavorite;
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF5F5F5),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _elapsedSeconds >= _maxSeconds * 0.9
                              ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: _elapsedSeconds >= _maxSeconds * 0.9
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF6366F1),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatTime(_maxSeconds - _elapsedSeconds),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _elapsedSeconds >= _maxSeconds * 0.9
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Color(0xFFE8E8E8),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Soru - Fixed height
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.25, // Slightly increased for visibility
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          _questionText,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1B1F),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Şıklar
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: List.generate(5, (index) {
                            final option = _options[index];
                            final isSelected = _selectedOption == index;
                            final isCorrect = index == _correctAnswerIndex;
                            final showResult = _isAnswered;

                            Color backgroundColor;
                            Color borderColor;
                            Color textColor;

                            if (showResult) {
                              if (isCorrect) {
                                backgroundColor = const Color(0xFF10B981).withValues(alpha: 0.08);
                                borderColor = const Color(0xFF10B981);
                                textColor = const Color(0xFF065F46);
                              } else if (isSelected) {
                                backgroundColor = const Color(0xFFEF4444).withValues(alpha: 0.08);
                                borderColor = const Color(0xFFEF4444);
                                textColor = const Color(0xFF991B1B);
                              } else {
                                backgroundColor = const Color(0xFFFAFAFA);
                                borderColor = const Color(0xFFE5E7EB);
                                textColor = const Color(0xFF6B7280);
                              }
                            } else {
                              if (isSelected) {
                                backgroundColor = const Color(0xFF6366F1).withValues(alpha: 0.06);
                                borderColor = const Color(0xFF6366F1);
                                textColor = const Color(0xFF1C1B1F);
                              } else {
                                backgroundColor = Colors.white;
                                borderColor = const Color(0xFFE5E7EB);
                                textColor = const Color(0xFF1C1B1F);
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: _isAnswered ? null : () => _handleOptionSelect(index),
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderColor, width: 2),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (showResult && isCorrect
                                                  ? const Color(0xFF10B981)
                                                  : showResult && !isCorrect
                                                      ? const Color(0xFFEF4444)
                                                      : const Color(0xFF6366F1))
                                              : const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(11),
                                        ),
                                        child: Center(
                                          child: Text(
                                            String.fromCharCode(65 + index),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected ? Colors.white : const Color(0xFF6B7280),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            option,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: textColor,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // FIX: Always reserve space to prevent layout shift
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: showResult
                                            ? (isCorrect
                                                ? const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24)
                                                : (isSelected && !isCorrect
                                                    ? const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 24)
                                                    : null))
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _selectedOption == null
                          ? null
                          : () {
                              if (!_isAnswered) {
                                _handleSubmit();
                              } else {
                                // Reset for demo purposes or go back
                                setState(() {
                                  _isAnswered = false;
                                  _selectedOption = null;
                                  _elapsedSeconds = 0;
                                  _startTimer();
                                });
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        disabledBackgroundColor: const Color(0xFFE5E7EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Text(
                        _isAnswered ? 'Tekrar Dene' : 'Cevapla',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
