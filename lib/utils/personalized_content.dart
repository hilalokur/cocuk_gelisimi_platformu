class ChildAgeProfile {
  final int months;
  final String ageText;
  final String broadGroup;
  final String developmentGroup;

  const ChildAgeProfile({
    required this.months,
    required this.ageText,
    required this.broadGroup,
    required this.developmentGroup,
  });
}

class PersonalizedItem {
  final String title;
  final String description;
  final String area;

  const PersonalizedItem({
    required this.title,
    required this.description,
    required this.area,
  });
}

class PersonalizedDailyBundle {
  final PersonalizedItem activity;
  final PersonalizedItem development;
  final PersonalizedItem nutrition;
  final String tip;

  const PersonalizedDailyBundle({
    required this.activity,
    required this.development,
    required this.nutrition,
    required this.tip,
  });
}

class PersonalizedContent {
  static ChildAgeProfile ageProfile(DateTime birthDate) {
    final now = DateTime.now();
    var months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    if (now.day < birthDate.day) months--;
    months = months.clamp(0, 72);

    final ageText = months < 12
        ? '$months aylık'
        : months % 12 == 0
        ? '${months ~/ 12} yaş'
        : '${months ~/ 12} yaş ${months % 12} ay';

    return ChildAgeProfile(
      months: months,
      ageText: ageText,
      broadGroup: broadAgeGroup(months),
      developmentGroup: developmentAgeGroup(months),
    );
  }

  static String broadAgeGroup(int months) {
    if (months < 24) return '0-2';
    if (months < 48) return '2-4';
    return '4-6';
  }

  static String broadAgeLabel(String group) {
    switch (group) {
      case '0-2':
        return '0-2 yaş';
      case '2-4':
        return '2-4 yaş';
      default:
        return 'Okul öncesi dönem';
    }
  }

  static String developmentAgeGroup(int months) {
    if (months <= 6) return '0-6 ay';
    if (months <= 12) return '7-12 ay';
    if (months <= 18) return '13-18 ay';
    if (months <= 24) return '19-24 ay';
    if (months <= 36) return '25-36 ay';
    if (months <= 48) return '3-4 yaş';
    if (months <= 60) return '4-5 yaş';
    return '5-6 yaş';
  }

  static PersonalizedDailyBundle dailyBundle(DateTime birthDate) {
    final profile = ageProfile(birthDate);
    return PersonalizedDailyBundle(
      activity: pickForToday(activities(profile.broadGroup)),
      development: pickForToday(
        developmentItems(profile.broadGroup),
        offset: 1,
      ),
      nutrition: pickForToday(nutritionItems(profile.broadGroup), offset: 2),
      tip: dailyTip(profile),
    );
  }

  static List<PersonalizedItem> activities(String group) {
    return _activityByGroup[group] ?? _activityByGroup['0-2']!;
  }

  static List<PersonalizedItem> developmentItems(String group) {
    return _developmentByGroup[group] ?? _developmentByGroup['0-2']!;
  }

  static List<PersonalizedItem> nutritionItems(String group) {
    return _nutritionByGroup[group] ?? _nutritionByGroup['0-2']!;
  }

  static PersonalizedItem pickForToday(
    List<PersonalizedItem> items, {
    int offset = 0,
  }) {
    if (items.isEmpty) {
      return const PersonalizedItem(
        title: 'Kısa oyun zamanı',
        description: 'Bugün sakin, kısa ve keyifli bir rutin deneyin.',
        area: 'Günlük',
      );
    }
    final now = DateTime.now();
    final seed = now.year * 366 + now.month * 31 + now.day + offset;
    return items[seed % items.length];
  }

  static String dailyTip(ChildAgeProfile profile) {
    final now = DateTime.now();
    final item = pickForToday(
      activities(profile.broadGroup),
      offset: nowSeed(),
    );
    final area = item.area.toLowerCase();
    final title = item.title.toLowerCase();
    final tips = [
      '${profile.ageText} çocuklarda $title, $area becerilerini günlük rutin içinde destekler.',
      'Bugün $title deneyerek ${profile.ageText} çocuğunuzun $area alanını sakin bir oyunla güçlendirebilirsiniz.',
      '${profile.ageText} dönemde kısa ve tekrarlı $title etkinlikleri öğrenmeyi daha kalıcı hale getirebilir.',
      '$title, ${profile.ageText} çocuklar için dikkat, iletişim ve $area gelişimini destekleyen pratik bir seçenektir.',
    ];
    return tips[(now.day + now.hour + now.minute ~/ 15) % tips.length];
  }

  static int nowSeed() {
    final now = DateTime.now();
    return now.hour + (now.minute ~/ 15);
  }
}

const _activityByGroup = {
  '0-2': [
    PersonalizedItem(
      title: 'Yumuşak Blokları Üst Üste Koyma',
      description:
          'İki üç yumuşak bloğu birlikte üst üste koyup devirmesine izin verin.',
      area: 'İnce Motor',
    ),
    PersonalizedItem(
      title: 'Saklanan Oyuncağı Bulma',
      description:
          'Sevdiği oyuncağı yarı görünür saklayıp aramasını destekleyin.',
      area: 'Bilişsel',
    ),
    PersonalizedItem(
      title: 'Ses Taklit Oyunu',
      description:
          'Kısa hayvan veya araç sesleri çıkarıp tekrar etmesini bekleyin.',
      area: 'Dil',
    ),
  ],
  '2-4': [
    PersonalizedItem(
      title: 'Renk Eşleştirme',
      description:
          'Aynı renkteki oyuncakları küçük gruplar halinde birlikte ayırın.',
      area: 'Bilişsel',
    ),
    PersonalizedItem(
      title: 'Hayali Market',
      description:
          'Oyuncak yiyeceklerle alışveriş oyunu kurup sıra alma pratiği yapın.',
      area: 'Sosyal',
    ),
    PersonalizedItem(
      title: 'Çizgi Takibi',
      description:
          'Kalın çizgileri parmağıyla veya boya kalemiyle takip etsin.',
      area: 'İnce Motor',
    ),
  ],
  '4-6': [
    PersonalizedItem(
      title: 'Hikaye Tamamlama',
      description:
          'Başladığınız kısa hikayeyi kendi cümlesiyle tamamlamasını isteyin.',
      area: 'Dil',
    ),
    PersonalizedItem(
      title: 'Basit Örüntü Kurma',
      description: 'Boncuk, lego veya kağıtlarla iki renkli örüntü oluşturun.',
      area: 'Bilişsel',
    ),
    PersonalizedItem(
      title: 'Denge Parkuru',
      description:
          'Yastık ve çizgilerle güvenli bir mini denge parkuru hazırlayın.',
      area: 'Motor',
    ),
  ],
};

const _developmentByGroup = {
  '0-2': [
    PersonalizedItem(
      title: 'Nesneyi amacına uygun kullanır',
      description:
          'Kaşığı, bardağı veya oyuncağı işlevine uygun denemesini izleyin.',
      area: 'Bilişsel',
    ),
    PersonalizedItem(
      title: 'Basit yönergeyi takip eder',
      description:
          '"Topu ver" gibi tek adımlı yönergeleri oyun içinde deneyin.',
      area: 'Dil',
    ),
  ],
  '2-4': [
    PersonalizedItem(
      title: 'Renk ve şekilleri ayırt eder',
      description:
          'Günlük nesnelerde renk ve şekil isimlendirmesini destekleyin.',
      area: 'Bilişsel',
    ),
    PersonalizedItem(
      title: 'Kısa cümlelerle anlatır',
      description:
          'Gördüğü bir olayı iki üç cümleyle anlatması için zaman tanıyın.',
      area: 'Dil',
    ),
  ],
  '4-6': [
    PersonalizedItem(
      title: 'Olayları sırasıyla anlatır',
      description:
          'Önce, sonra, en son gibi sıralama kelimelerini kullanmasını isteyin.',
      area: 'Dil',
    ),
    PersonalizedItem(
      title: 'Kurallı oyuna katılır',
      description:
          'Basit kurallı oyunlarda bekleme ve sıra alma davranışını izleyin.',
      area: 'Sosyal',
    ),
  ],
};

const _nutritionByGroup = {
  '0-2': [
    PersonalizedItem(
      title: 'Yeni besini tek tek deneme',
      description:
          'Ek gıdaya uygunsa yeni besinleri küçük miktarla ve ayrı ayrı deneyin.',
      area: 'Beslenme',
    ),
    PersonalizedItem(
      title: 'Su yudumları',
      description:
          'Ek gıda döneminde öğünlerle küçük su yudumlarını destekleyin.',
      area: 'Beslenme',
    ),
  ],
  '2-4': [
    PersonalizedItem(
      title: 'Renkli tabak',
      description:
          'Tabağa farklı renkte sebze ve meyvelerden küçük porsiyonlar ekleyin.',
      area: 'Beslenme',
    ),
    PersonalizedItem(
      title: 'Düzenli ara öğün',
      description:
          'Şekerli atıştırmalık yerine yoğurt, meyve veya kuruyemiş alternatifi sunun.',
      area: 'Beslenme',
    ),
  ],
  '4-6': [
    PersonalizedItem(
      title: 'Sofra sorumluluğu',
      description:
          'Peçete koyma veya tabak sayma gibi küçük sofra görevleri verin.',
      area: 'Beslenme',
    ),
    PersonalizedItem(
      title: 'Dengeli tabak konuşması',
      description:
          'Protein, sebze ve tahıl gruplarını tabakta birlikte adlandırın.',
      area: 'Beslenme',
    ),
  ],
};
