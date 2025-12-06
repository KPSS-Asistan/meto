import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kpss_2026/core/data/lessons_data.dart';
import 'package:kpss_2026/core/services/study_schedule_service.dart';

/// Ders Programı Sayfası
class StudySchedulePage extends StatefulWidget {
  const StudySchedulePage({super.key});

  @override
  State<StudySchedulePage> createState() => _StudySchedulePageState();
}

class _StudySchedulePageState extends State<StudySchedulePage> {
  bool _isLoading = true;
  WeeklySchedule? _savedSchedule;
  bool _showWizard = false;
  
  // Wizard State
  int _currentStep = 0;
  int _selectedHours = 2;
  final Set<int> _selectedDays = {0, 1, 2, 3, 4};
  int _startHour = 9;
  int _endHour = 17;
  final Set<String> _priorityLessons = {};

  // Renkler
  static const _primaryColor = Color(0xFF0EA5E9);
  static const _successColor = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _loadSavedSchedule();
  }

  Future<void> _loadSavedSchedule() async {
    final schedule = await StudyScheduleService.getSavedSchedule();
    if (mounted) {
      setState(() {
        _savedSchedule = schedule;
        _isLoading = false;
      });
    }
  }

  void _startWizard() {
    setState(() {
      _showWizard = true;
      _currentStep = 0;
    });
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _generateSchedule();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _generateSchedule() async {
    final prefs = StudyPreferences(
      dailyHours: _selectedHours,
      availableDays: _selectedDays.toList()..sort(),
      startHour: _startHour,
      endHour: _endHour,
      priorityLessons: _priorityLessons.toList(),
    );

    final schedule = StudyScheduleService.generateSchedule(prefs);
    await StudyScheduleService.saveSchedule(schedule);

    setState(() {
      _savedSchedule = schedule;
      _showWizard = false;
    });
  }

  Future<void> _toggleBlock(String blockId) async {
    if (_savedSchedule == null) return;
    await StudyScheduleService.toggleBlockCompletion(_savedSchedule!, blockId);
    setState(() {});
  }

  Future<void> _resetSchedule() async {
    final confirmed = await _showConfirmDialog();
    if (confirmed == true) {
      await StudyScheduleService.clearSchedule();
      setState(() => _savedSchedule = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Ders Programı', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        actions: [
          if (_savedSchedule != null && !_showWizard)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Yeniden Oluştur',
              onPressed: _startWizard,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showWizard
              ? _buildWizard(isDark)
              : _savedSchedule != null
                  ? _buildScheduleView(isDark)
                  : _buildEmptyState(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.calendar_month_rounded, size: 56, color: _primaryColor),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 28),
            Text(
              'Pomodoro Ders Programı',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 10),
            Text(
              '25 dakika çalışma + 5 dakika mola\nBilimsel olarak kanıtlanmış en etkili yöntem',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: _startWizard,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Programımı Oluştur', style: TextStyle(fontWeight: FontWeight.w600)),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildWizard(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: List.generate(4, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isActive ? _primaryColor : subtextColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),

        // Soru
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildQuestion(_currentStep, cardColor, textColor, subtextColor, isDark),
          ),
        ),

        // Butonlar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: subtextColor.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Geri', style: TextStyle(color: textColor)),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canProceed() ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _primaryColor.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentStep < 3 ? 'Devam' : 'Oluştur',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: return true;
      case 1: return _selectedDays.isNotEmpty;
      case 2: return _endHour > _startHour;
      case 3: return true;
      default: return false;
    }
  }

  Widget _buildQuestion(int step, Color cardColor, Color textColor, Color subtextColor, bool isDark) {
    switch (step) {
      case 0: return _buildHoursQuestion(cardColor, textColor, subtextColor, isDark);
      case 1: return _buildDaysQuestion(cardColor, textColor, subtextColor, isDark);
      case 2: return _buildTimeRangeQuestion(cardColor, textColor, subtextColor, isDark);
      case 3: return _buildPriorityQuestion(cardColor, textColor, subtextColor, isDark);
      default: return const SizedBox();
    }
  }

  /// Soru 1: Günlük saat
  Widget _buildHoursQuestion(Color cardColor, Color textColor, Color subtextColor, bool isDark) {
    final options = [
      {'value': 1, 'label': '1 saat', 'blocks': '2 pomodoro'},
      {'value': 2, 'label': '2 saat', 'blocks': '4 pomodoro'},
      {'value': 3, 'label': '3 saat', 'blocks': '6 pomodoro'},
      {'value': 4, 'label': '4 saat', 'blocks': '8 pomodoro'},
      {'value': 5, 'label': '5+ saat', 'blocks': '10+ pomodoro'},
    ];

    return ListView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(
          title: 'Günde kaç saat çalışabilirsiniz?',
          subtitle: 'Her pomodoro: 25dk çalışma + 5dk mola',
          textColor: textColor,
          subtextColor: subtextColor,
        ),
        const SizedBox(height: 20),
        ...options.map((opt) {
          final value = opt['value'] as int;
          final isSelected = _selectedHours == value;
          return _buildSimpleOption(
            label: opt['label'] as String,
            subtitle: opt['blocks'] as String,
            isSelected: isSelected,
            onTap: () => setState(() => _selectedHours = value),
            cardColor: cardColor,
            textColor: textColor,
            subtextColor: subtextColor,
            isDark: isDark,
          );
        }),
      ],
    );
  }

  /// Soru 2: Günler
  Widget _buildDaysQuestion(Color cardColor, Color textColor, Color subtextColor, bool isDark) {
    final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

    return ListView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(
          title: 'Hangi günler çalışabilirsiniz?',
          subtitle: 'Birden fazla seçebilirsiniz',
          textColor: textColor,
          subtextColor: subtextColor,
        ),
        const SizedBox(height: 12),
        // Hızlı seçim
        Wrap(
          spacing: 8,
          children: [
            _buildChip('Hafta İçi', {0, 1, 2, 3, 4}, isDark),
            _buildChip('Hafta Sonu', {5, 6}, isDark),
            _buildChip('Her Gün', {0, 1, 2, 3, 4, 5, 6}, isDark),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(7, (index) {
          final isSelected = _selectedDays.contains(index);
          return _buildCheckItem(
            label: days[index],
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedDays.remove(index);
                } else {
                  _selectedDays.add(index);
                }
              });
            },
            cardColor: cardColor,
            textColor: textColor,
            isDark: isDark,
          );
        }),
      ],
    );
  }

  /// Soru 3: Saat aralığı
  Widget _buildTimeRangeQuestion(Color cardColor, Color textColor, Color subtextColor, bool isDark) {
    return ListView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(
          title: 'Hangi saatler arasında çalışacaksınız?',
          subtitle: 'Başlangıç ve bitiş saatini seçin',
          textColor: textColor,
          subtextColor: subtextColor,
        ),
        const SizedBox(height: 24),
        
        // Saat seçiciler
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Başlangıç
              Row(
                children: [
                  Text('Başlangıç:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                  const Spacer(),
                  _buildHourPicker(_startHour, (h) => setState(() => _startHour = h), isDark),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: subtextColor.withValues(alpha: 0.2)),
              const SizedBox(height: 20),
              // Bitiş
              Row(
                children: [
                  Text('Bitiş:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                  const Spacer(),
                  _buildHourPicker(_endHour, (h) => setState(() => _endHour = h), isDark),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Özet
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _primaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Toplam ${_endHour - _startHour} saat aralığında çalışacaksınız',
                  style: TextStyle(fontSize: 14, color: _primaryColor, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHourPicker(int value, ValueChanged<int> onChanged, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded),
            onPressed: value > 5 ? () => onChanged(value - 1) : null,
            iconSize: 20,
          ),
          Container(
            width: 60,
            alignment: Alignment.center,
            child: Text(
              '${value.toString().padLeft(2, '0')}:00',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: value < 23 ? () => onChanged(value + 1) : null,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  /// Soru 4: Öncelikli dersler
  Widget _buildPriorityQuestion(Color cardColor, Color textColor, Color subtextColor, bool isDark) {
    return ListView(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(
          title: 'Öncelikli dersleriniz',
          subtitle: 'Bu derslere daha fazla zaman ayrılır (opsiyonel)',
          textColor: textColor,
          subtextColor: subtextColor,
        ),
        const SizedBox(height: 20),
        ...lessonsData.map((lesson) {
          final id = lesson['id'] as String;
          final name = lesson['name'] as String;
          final isSelected = _priorityLessons.contains(id);
          final color = Color(StudyScheduleService.getLessonColor(id));
          
          return _buildLessonOption(
            lessonName: name,
            color: color,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _priorityLessons.remove(id);
                } else {
                  _priorityLessons.add(id);
                }
              });
            },
            cardColor: cardColor,
            textColor: textColor,
            isDark: isDark,
          );
        }),
      ],
    );
  }

  Widget _buildHeader({
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(fontSize: 14, color: subtextColor)),
      ],
    );
  }

  Widget _buildSimpleOption({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withValues(alpha: 0.1) : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isSelected ? _primaryColor : textColor)),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: subtextColor)),
                ],
              ),
            ),
            _buildRadio(isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _successColor.withValues(alpha: 0.1) : cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _successColor : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _buildCheckbox(isSelected),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isSelected ? _successColor : textColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonOption({
    required String lessonName,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isSelected ? 1 : 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  lessonName[0],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(lessonName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isSelected ? color : textColor)),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Set<int> days, bool isDark) {
    final isSelected = _selectedDays.containsAll(days);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDays.removeAll(days);
          } else {
            _selectedDays.addAll(days);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _successColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? _successColor : (isDark ? Colors.white24 : Colors.grey.shade300)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700)),
        ),
      ),
    );
  }

  Widget _buildRadio(bool isSelected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? _primaryColor : Colors.transparent,
        border: Border.all(color: isSelected ? _primaryColor : Colors.grey, width: 2),
      ),
      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
    );
  }

  Widget _buildCheckbox(bool isSelected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: isSelected ? _successColor : Colors.transparent,
        border: Border.all(color: isSelected ? _successColor : Colors.grey, width: 2),
      ),
      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
    );
  }

  /// Program görünümü - TO-DO LIST
  Widget _buildScheduleView(bool isDark) {
    final schedule = _savedSchedule!;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    // Bugünün günü
    final today = DateTime.now().weekday - 1; // 0=Pazartesi

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      children: [
        // Pomodoro bilgi kartı
        _buildInfoCard(schedule, cardColor, textColor, subtextColor),
        const SizedBox(height: 16),

        // İlerleme
        _buildProgressCard(schedule, cardColor, textColor, subtextColor),
        const SizedBox(height: 20),

        // Haftalık mini görünüm
        _buildWeekMini(schedule, today, cardColor, textColor, subtextColor, isDark),
        const SizedBox(height: 20),

        // Günlük to-do listeler
        ...schedule.days.map((day) {
          if (day.blocks.isEmpty) return const SizedBox.shrink();
          return _buildDayTodoList(day, day.dayIndex == today, cardColor, textColor, subtextColor, isDark);
        }),

        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: _resetSchedule,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade400,
            side: BorderSide(color: Colors.red.shade400.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Programı Sıfırla'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInfoCard(WeeklySchedule schedule, Color cardColor, Color textColor, Color subtextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor.withValues(alpha: 0.1), _successColor.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.timer_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pomodoro Tekniği', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                Text('25 dk çalışma • 5 dk mola', style: TextStyle(fontSize: 13, color: subtextColor)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildProgressCard(WeeklySchedule schedule, Color cardColor, Color textColor, Color subtextColor) {
    final total = schedule.totalBlocks;
    final completed = schedule.completedBlocks;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Haftalık İlerleme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              const Spacer(),
              Text('$completed / $total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _successColor)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: subtextColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(_successColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${schedule.activeDaysCount} gün', style: TextStyle(fontSize: 13, color: subtextColor)),
              Text('${(progress * 100).toInt()}% tamamlandı', style: TextStyle(fontSize: 13, color: subtextColor)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildWeekMini(WeeklySchedule schedule, int today, Color cardColor, Color textColor, Color subtextColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final day = schedule.days[index];
          final isToday = index == today;
          final hasBlocks = day.blocks.isNotEmpty;
          final allDone = hasBlocks && day.completedCount == day.blocks.length;
          
          return Column(
            children: [
              Text(
                StudyScheduleService.getShortDayName(index),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday ? _primaryColor : subtextColor,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: allDone ? _successColor : (isToday ? _primaryColor : (hasBlocks ? _primaryColor.withValues(alpha: 0.15) : Colors.transparent)),
                  border: isToday && !allDone ? Border.all(color: _primaryColor, width: 2) : null,
                ),
                child: Center(
                  child: allDone
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : hasBlocks
                          ? Text('${day.blocks.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isToday ? Colors.white : _primaryColor))
                          : Icon(Icons.remove, size: 14, color: subtextColor.withValues(alpha: 0.5)),
                ),
              ),
            ],
          );
        }),
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildDayTodoList(DailySchedule day, bool isToday, Color cardColor, Color textColor, Color subtextColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: isToday ? Border.all(color: _primaryColor.withValues(alpha: 0.5), width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(6)),
                  child: const Text('BUGÜN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              Text(StudyScheduleService.getDayName(day.dayIndex), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              const Spacer(),
              Text('${day.completedCount}/${day.blocks.length}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _successColor)),
            ],
          ),
          const SizedBox(height: 12),
          ...day.blocks.map((block) => _buildBlockTodo(block, textColor, subtextColor, isDark)),
        ],
      ),
    ).animate().fadeIn(delay: (200 + day.dayIndex * 40).ms);
  }

  Widget _buildBlockTodo(StudyBlock block, Color textColor, Color subtextColor, bool isDark) {
    final color = Color(StudyScheduleService.getLessonColor(block.lessonId));
    
    return GestureDetector(
      onTap: () => _toggleBlock(block.id),
      onLongPress: () => _showBlockOptionsSheet(block, isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: block.isCompleted ? _successColor.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: block.isCompleted ? _successColor.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: block.isCompleted ? _successColor : Colors.transparent,
                border: Border.all(color: block.isCompleted ? _successColor : color, width: 2),
              ),
              child: block.isCompleted ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
            const SizedBox(width: 12),
            // Renk çizgi
            Container(width: 3, height: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.lessonName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: block.isCompleted ? _successColor : textColor,
                      decoration: block.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${block.timeRange} • ${block.activityName}',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),
            // Düzenle ikonu
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: subtextColor, size: 20),
              onPressed: () => _showBlockOptionsSheet(block, isDark),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            // Süre
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${block.durationMinutes}dk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  /// Blok seçenekleri bottom sheet
  void _showBlockOptionsSheet(StudyBlock block, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Blok başlığı
            Text(
              block.lessonName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            Text(
              block.timeRange,
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            
            // Seçenekler
            _buildOptionTile(
              icon: Icons.edit_rounded,
              label: 'Dersi Değiştir',
              color: _primaryColor,
              onTap: () {
                Navigator.pop(context);
                _showChangeLessonSheet(block, isDark);
              },
            ),
            const SizedBox(height: 8),
            _buildOptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Görevi Sil',
              color: Colors.red.shade400,
              onTap: () async {
                Navigator.pop(context);
                await _deleteBlock(block.id);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
          ],
        ),
      ),
    );
  }

  /// Ders değiştirme sheet
  void _showChangeLessonSheet(StudyBlock block, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'Ders Seç',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView(
                children: lessonsData.map((lesson) {
                  final id = lesson['id'] as String;
                  final name = lesson['name'] as String;
                  final color = Color(StudyScheduleService.getLessonColor(id));
                  final isSelected = block.lessonId == id;
                  
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _updateBlockLesson(block.id, id, name);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: isSelected ? 1 : 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                name[0],
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                          if (isSelected) ...[
                            const Spacer(),
                            Icon(Icons.check_circle_rounded, color: color),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBlockLesson(String blockId, String lessonId, String lessonName) async {
    if (_savedSchedule == null) return;
    await StudyScheduleService.updateBlock(_savedSchedule!, blockId, lessonId, lessonName);
    setState(() {});
  }

  Future<void> _deleteBlock(String blockId) async {
    if (_savedSchedule == null) return;
    await StudyScheduleService.deleteBlock(_savedSchedule!, blockId);
    setState(() {});
  }

  Future<bool?> _showConfirmDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 40),
              const SizedBox(height: 14),
              Text('Programı Sıfırla', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Text('Mevcut program silinecek.', style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade500, foregroundColor: Colors.white),
                      child: const Text('Sil'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
