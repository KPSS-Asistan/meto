import '../../domain/entities/quiz.dart';
import '../../domain/repositories/quiz_repository.dart';

/// Mock Quiz Repository with sample KPSS questions
class MockQuizRepository implements QuizRepository {
  @override
  Future<QuizSet> getQuizSet(String setId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final quizSets = {
      'quiz_1': QuizSet(
        id: 'quiz_1',
        title: 'KPSS Genel Kültür - Karma Sorular',
        category: 'Genel Kültür',
        duration: 60,
        questions: [
          QuizQuestion(
            id: 'q1',
            question: 'Osmanlı Devleti\'nde Tanzimat Fermanı\'nın ilanından sonra yapılan yeniliklerin temel amacı aşağıdakilerden hangisidir?',
            options: [
              'Devletin toprak bütünlüğünü korumak ve Batılı devletlerin iç işlerine karışmasını önlemek',
              'Padişahın yetkilerini artırarak merkeziyetçi yapıyı güçlendirmek',
              'Osmanlı toplumunu tamamen Batılılaştırarak İslami değerlerden uzaklaştırmak',
              'Sadece askeri alanda reform yaparak orduyu güçlendirmek',
              'Ekonomik kalkınmayı sağlamak için sanayileşmeye öncelik vermek'
            ],
            correctAnswerIndex: 0,
            explanation: 'Tanzimat Fermanı (1839), Osmanlı Devleti\'nin dağılmasını önlemek, toprak bütünlüğünü korumak ve Batılı devletlerin iç işlerine karışma bahanelerini ortadan kaldırmak amacıyla ilan edilmiştir.',
          ),
          QuizQuestion(
            id: 'q2',
            question: 'Aşağıdaki cümlelerin hangisinde "de" bağlacı yanlış kullanılmıştır?',
            options: [
              'Kitabı okudum, çok beğendim de.',
              'Ankara\'da yaşıyorum.',
              'Sen de gel.',
              'Evde kimse yok.',
              'O da bizimle gelecek.'
            ],
            correctAnswerIndex: 0,
            explanation: '"De" bağlacı cümle sonunda kullanılamaz. Doğrusu: "Kitabı okudum, çok beğendim." şeklinde olmalıdır.',
          ),
          QuizQuestion(
            id: 'q3',
            question: 'Türkiye Cumhuriyeti Anayasası\'na göre, Cumhurbaşkanı\'nın görev süresi kaç yıldır ve en fazla kaç dönem seçilebilir?',
            options: [
              '4 yıl - 2 dönem',
              '5 yıl - 2 dönem',
              '5 yıl - 3 dönem',
              '7 yıl - 1 dönem',
              '6 yıl - 2 dönem'
            ],
            correctAnswerIndex: 1,
            explanation: '2017 Anayasa değişikliği ile Cumhurbaşkanı\'nın görev süresi 5 yıl olarak belirlenmiş ve bir kişi en fazla iki defa Cumhurbaşkanı seçilebilir.',
          ),
          QuizQuestion(
            id: 'q4',
            question: 'Aşağıdakilerden hangisi Türkiye\'nin en uzun kıyı şeridine sahip olduğu denizdir?',
            options: [
              'Karadeniz',
              'Akdeniz',
              'Ege Denizi',
              'Marmara Denizi',
              'Hepsi eşit uzunluktadır'
            ],
            correctAnswerIndex: 1,
            explanation: 'Türkiye\'nin en uzun kıyı şeridine sahip olduğu deniz Akdeniz\'dir (yaklaşık 1577 km).',
          ),
          QuizQuestion(
            id: 'q5',
            question: 'I. Dünya Savaşı sonrasında imzalanan Mondros Ateşkes Antlaşması\'nın Türk Kurtuluş Savaşı\'nın başlamasındaki en önemli etkisi aşağıdakilerden hangisidir?',
            options: [
              'Osmanlı Devleti\'nin tamamen ortadan kalkması',
              'İtilaf Devletleri\'ne Anadolu\'yu işgal etme hakkı tanıması',
              'Padişahın tahttan indirilmesi',
              'TBMM\'nin açılması',
              'Lozan Antlaşması\'nın imzalanması'
            ],
            correctAnswerIndex: 1,
            explanation: 'Mondros Ateşkes Antlaşması (30 Ekim 1918), İtilaf Devletleri\'ne Anadolu\'yu işgal etme hakkı tanımış ve Milli Mücadele\'nin başlamasına neden olmuştur.',
          ),
          QuizQuestion(
            id: 'q6',
            question: 'Bir sayının %40\'ı 80 ise, bu sayının %65\'i kaçtır?',
            options: [
              '120',
              '130',
              '140',
              '150',
              '160'
            ],
            correctAnswerIndex: 1,
            explanation: 'Sayıyı x olarak alalım: 0.40x = 80, x = 200. 200\'ün %65\'i = 130.',
          ),
          QuizQuestion(
            id: 'q7',
            question: 'Aşağıdaki edebi akımlardan hangisi, toplumsal sorunlara değinmeyi ve halkın yaşamını yansıtmayı amaçlar?',
            options: [
              'Romantizm',
              'Realizm',
              'Sembolizm',
              'Natüralizm',
              'Empresyonizm'
            ],
            correctAnswerIndex: 1,
            explanation: 'Realizm (Gerçekçilik), toplumsal sorunları ve günlük yaşamı olduğu gibi yansıtmayı amaçlayan edebi akımdır.',
          ),
          QuizQuestion(
            id: 'q8',
            question: 'Türkiye\'de nüfusun en yoğun olduğu bölge aşağıdakilerden hangisidir?',
            options: [
              'İç Anadolu Bölgesi',
              'Karadeniz Bölgesi',
              'Marmara Bölgesi',
              'Ege Bölgesi',
              'Akdeniz Bölgesi'
            ],
            correctAnswerIndex: 2,
            explanation: 'Marmara Bölgesi, Türkiye\'nin en kalabalık bölgesidir. Türkiye nüfusunun yaklaşık %30\'u bu bölgede yaşamaktadır.',
          ),
          QuizQuestion(
            id: 'q9',
            question: 'Atatürk\'ün "Yurtta sulh, cihanda sulh" ilkesi aşağıdaki dış politika anlayışlarından hangisini yansıtır?',
            options: [
              'Emperyalist genişleme politikası',
              'Barışçı ve savunmacı dış politika',
              'Yayılmacı ve saldırgan politika',
              'İzolasyonist (dışa kapalı) politika',
              'Sömürgecilik politikası'
            ],
            correctAnswerIndex: 1,
            explanation: '"Yurtta sulh, cihanda sulh" ilkesi, Türkiye\'nin barışçı, savunmacı ve statükocu dış politika anlayışını yansıtır.',
          ),
          QuizQuestion(
            id: 'q10',
            question: 'Aşağıdaki cümlelerin hangisinde noktalama işareti yanlış kullanılmıştır?',
            options: [
              'Kitap, defter, kalem aldım.',
              'Atatürk şöyle demiştir: "Hayatta en hakiki mürşit ilimdir."',
              'Ankara\'ya gitti; ama dönmedi.',
              'Ne zaman geleceksin?',
              'Elma, armut; portakal aldım.'
            ],
            correctAnswerIndex: 4,
            explanation: 'Virgül aynı türden kelimeleri ayırmak için kullanılır. "Elma, armut, portakal" aynı türden olduğu için aralarında virgül kullanılmalıdır.',
          ),
        ],
      ),
    };

    return quizSets[setId] ?? quizSets['quiz_1']!;
  }
}
