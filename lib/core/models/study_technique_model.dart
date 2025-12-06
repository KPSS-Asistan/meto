import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_technique_model.freezed.dart';

@freezed
class StudyTechnique with _$StudyTechnique {
  const factory StudyTechnique({
    required String id,
    required String title,
    required String category,
    required String shortDescription,
    required String fullDescription,
    required List<String> steps,
    required List<String> benefits,
    required List<String> tips,
    String? example,
  }) = _StudyTechnique;
}

enum TechniqueCategory {
  noteTaking,
  memory,
  reading,
  timeManagement,
  studyPlanning,
  concentration,
  motivation,
  stressManagement,
  examHacks,      // YENİ
  bioHacking,     // YENİ
  breakGuide,     // YENİ
}

extension TechniqueCategoryExtension on TechniqueCategory {
  String get displayName {
    switch (this) {
      case TechniqueCategory.noteTaking:
        return 'Not Alma Teknikleri';
      case TechniqueCategory.memory:
        return 'Hafıza ve Ezber Teknikleri';
      case TechniqueCategory.reading:
        return 'Okuma ve Anlama Stratejileri';
      case TechniqueCategory.timeManagement:
        return 'Zaman Yönetimi';
      case TechniqueCategory.studyPlanning:
        return 'Çalışma Planlama';
      case TechniqueCategory.concentration:
        return 'Odaklanma Egzersizleri';
      case TechniqueCategory.motivation:
        return 'Motivasyon ve Hedef';
      case TechniqueCategory.stressManagement:
        return 'Stres Yönetimi';
      case TechniqueCategory.examHacks:
        return 'Sınav Hackleri (Net Arttır)';
      case TechniqueCategory.bioHacking:
        return 'Bio-Performans (Uyku & Besin)';
      case TechniqueCategory.breakGuide:
        return 'Mola Rehberi';
    }
  }
}
