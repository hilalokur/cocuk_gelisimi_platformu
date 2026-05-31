import '../models/activity_model.dart';

class ActivityData {
  static List<ActivityModel> activities = [
    // ---------------- 0-2 YAŞ ----------------
    ActivityModel(
      ageGroup: '0-2',
      title: 'Baloncuk Patlatma',
      description:
          'Havada uçuşan baloncukları yakalamaya ve patlatmaya çalışmak bebeğinizin el-göz koordinasyonunu geliştirir.',
    ),
    ActivityModel(
      ageGroup: '0-2',
      title: 'Müzik Eşliğinde Dans',
      description:
          'Ritim duygusunu ve kaba motor becerilerini destekler. Not: Bu yaşta ekran önerilmez!',
    ),
    ActivityModel(
      ageGroup: '0-2',
      title: 'İt-Çek Oyunu',
      description:
          'Nesneleri itip çekerek sebep-sonuç ilişkisini kavramasına yardımcı olun.',
    ),

    // ---------------- 2-3 YAŞ ----------------
    ActivityModel(
      ageGroup: '2-3',
      title: 'Objeleri Devirme',
      description:
          'Üst üste konmuş objeleri yuvarlanarak veya dokunarak devirme oyunu.',
    ),
    ActivityModel(
      ageGroup: '2-3',
      title: 'Park ve Bahçe Oyunları',
      description:
          'Açık havada kısa mesafe yürüyüşler yaparak motor becerilerini destekleyin.',
    ),

    // ---------------- 3-4 YAŞ ----------------
    ActivityModel(
      ageGroup: '3-4',
      title: 'Su ve Kum Aktiviteleri',
      description: 'Duyusal gelişim için su içi ve kum oyunları çok etkilidir.',
    ),
    ActivityModel(
      ageGroup: '3-4',
      title: 'Top Oyunları',
      description:
          'Top atma ve yakalama gibi oyunlarla el-göz koordinasyonunu pekiştirin.',
    ),

    // ---------------- 4-5 YAŞ ----------------
    ActivityModel(
      ageGroup: '4-5',
      title: 'Hayvan Taklitleri',
      description:
          'Farklı hayvanların yürüyüş ve seslerini taklit ederek fiziksel aktiviteyi eğlenceli hale getirin.',
    ),
    ActivityModel(
      ageGroup: '4-5',
      title: 'Mendil Kapmaca',
      description:
          'Konsantrasyon, hız ve denge gerektiren geleneksel bir grup oyunu.',
    ),
  ];
}
