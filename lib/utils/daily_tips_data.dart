import 'dart:math';

class DailyTip {
  final String title;
  final String content;

  DailyTip({required this.title, required this.content});
}

class DailyTipsData {
  static final Map<String, List<DailyTip>> tips = {
    '0-2': [
      DailyTip(
        title: 'Duyusal Keşif',
        content:
            'Farklı dokudaki nesneleri (yumuşak fırça, pürüzlü sünger) avucuna dokundurtursanız, dokunsal algısı ve beynindeki nöron bağlantıları hızla güçlenir.',
      ),
      DailyTip(
        title: 'Ayak Koordinasyonu',
        content:
            'Yatağın üzerine renkli balonlar asıp ayaklarıyla vurmasını sağlarsanız, bacak kasları ve göz-ayak koordinasyonu aktifleşir.',
      ),
      DailyTip(
        title: 'Gevşeme Ritüeli',
        content:
            'Yatmadan önce ayak tabanlarına hafif dairesel hareketlerle masaj yaparsanız, sinir sistemi gevşer ve derin uykuya geçişi kolaylaşır.',
      ),
      DailyTip(
        title: 'Hazine Avı',
        content:
            'Bir kabın içine pirinç ve gizli oyuncaklar koyup bulmasını isterseniz, ince motor becerisi ve odaklanma süresi artar.',
      ),
      DailyTip(
        title: 'Engel Parkuru',
        content:
            'Yere yumuşak yastıklardan düşük engeller koyup aşmasını sağlarsanız, kaba motor becerileri ve denge kontrolü gelişir.',
      ),
      DailyTip(
        title: 'Uyku Sinyali',
        content:
            'Uyku öncesi hep aynı beyaz gürültüyü veya ritmik melodiyi çalarsanız, beyni "dinlenme" moduna daha hızlı geçer.',
      ),
      DailyTip(
        title: 'Koku Hafızası',
        content:
            'Güvenli doğal nesneleri (limon kabuğu, taze nane) koklatıp isimlendirirseniz, koku hafızası ve duyusal farkındalığı uyanır.',
      ),
      DailyTip(
        title: 'El Değiştirme',
        content:
            'Oyuncağı bir elinden diğerine aktarması için onu teşvik ederseniz, beynin iki lobu arasındaki iletişim ve koordinasyon güçlenir.',
      ),
      DailyTip(
        title: 'Fısıltı Zamanı',
        content:
            'Loş ışıkta fısıltıyla gün içinde yaptıklarınızı anlatırsanız, işitsel dikkati artar ve ses tonunuzun ritmiyle sakinleşir.',
      ),
      DailyTip(
        title: 'Işık Takibi',
        content:
            'Renkli bir feneri karanlık odada duvarda yavaşça gezdirirseniz, göz kasları güçlenir ve görsel takip yeteneği keskinleşir.',
      ),
    ],
    '2-4': [
      DailyTip(
        title: 'Görsel Anlatım',
        content:
            'Kitaptaki resimleri "Burada ne oluyor?" diyerek ona anlattırırsanız, olay örgüsü kurma yeteneği ve kelime hazinesi hızla zenginleşir.',
      ),
      DailyTip(
        title: 'Karton Dünya',
        content:
            'Büyük bir karton kutuyu boyayıp içine girerek oyun kurarsanız, sembolik düşünme ve yaratıcı problem çözme yetisi parlar.',
      ),
      DailyTip(
        title: 'Sesli Rehber',
        content:
            'Mutfakta veya temizlik yaparken yaptıklarınızı adım adım sesli söylerseniz, dil bilgisi yapılarını doğal yolla kavrar.',
      ),
      DailyTip(
        title: 'Çay Partisi',
        content:
            'Oyuncakları bir sofraya oturtup aralarında diyaloglar kurarsanız, sosyal etkileşim kurallarını ve empatiyi pratik eder.',
      ),
      DailyTip(
        title: 'Renk Avcıları',
        content:
            '"Sarı olan nesneleri bul" gibi sıfat oyunları oynarsanız, görsel ayırt etme ve hızlı sınıflandırma becerisi artar.',
      ),
      DailyTip(
        title: 'Sihirli Halı',
        content:
            'Yere serdiğiniz bir çarşafı "uçak" yapıp odaları gezerseniz, mekan algısı ve kurgusal oyun kurma kabiliyeti gelişir.',
      ),
      DailyTip(
        title: 'Eksik Kelime',
        content:
            'Bildiği şarkıların son kelimelerini boş bırakıp onun tamamlamasını beklerseniz, işitsel dikkati ve hafızası güçlenir.',
      ),
      DailyTip(
        title: 'Gölge Tiyatrosu',
        content:
            'Parmaklarınızla duvarda gölge oyunları yaratırsanız, ışık-gölge algısı ve soyut düşünme yetisi uyanır.',
      ),
      DailyTip(
        title: 'Cümle Genişletme',
        content:
            'Onun kısa cümlelerini yeni kelimeler ekleyerek genişletip tekrar ederseniz, ifade yeteneği rafine olur.',
      ),
      DailyTip(
        title: 'Doğa Parası',
        content:
            'Parktan topladığınız taş ve yapraklarla alışverişçilik oynarsanız, miktar kavramı ve yaratıcı oyun kurma temelleri atılır.',
      ),
    ],
    '4-6': [
      DailyTip(
        title: 'Küçük Tamirci',
        content:
            'Evdeki basit bir eşyayı "Bunu nasıl düzeltebiliriz?" diye beraber incelerseniz, analitik düşünme ve çözüm üretme kası gelişir.',
      ),
      DailyTip(
        title: 'Hata Provası',
        content:
            'Kendi yaptığınız küçük bir hatayı ona gösterip çözüm sorarsanız, sosyal sorumluluk bilinci ve telafi etme becerisi gelişir.',
      ),
      DailyTip(
        title: 'Kendi Yapbozun',
        content:
            'Bir resmi kesip parçalara ayırarak tekrar birleştirmesini isterseniz, parça-bütün ilişkisi ve sabırlı odaklanma becerisi güçlenir.',
      ),
      DailyTip(
        title: 'İsteme Sanatı',
        content:
            'Birinden bir nesneyi nazikçe isteme provasını evde canlandırırsanız, sosyal girişkenlik ve iletişim yetisi artar.',
      ),
      DailyTip(
        title: 'Hava Durumu Şefi',
        content:
            'Kıyafetlerini hava durumuna göre seçme sorumluluğunu ona verirseniz, veri değerlendirme ve bağımsız karar verme yeteneği gelişir.',
      ),
      DailyTip(
        title: 'Duygu Yönetimi',
        content:
            'Oyun sonunda kazanma ve kaybetme duygularını isimlendirip konuşursanız, duygusal dayanıklılık ve sportmenlik kazanır.',
      ),
      DailyTip(
        title: 'Sofra Matematiği',
        content:
            'Sofra kurarken kişi sayısına göre tabak ve çatal saymasını isterseniz, pratik matematik ve organizasyon zekası gelişir.',
      ),
      DailyTip(
        title: 'Ortak Hikaye',
        content:
            'Bir cümle sizin bir cümle onun olduğu ortak hikayeler uydurursanız, dinleme becerisi ve grup uyumu pekişir.',
      ),
      DailyTip(
        title: 'Strateji Labirenti',
        content:
            'Labirent bulmacaları veya "farkı bul" oyunları çözerseniz, görsel dikkat ve stratejik ilerleme yetisi gelişir.',
      ),
      DailyTip(
        title: 'Hediye Dedektifi',
        content:
            'Birine hediye seçerken "Onun en sevdiği şey ne?" diye kafa yorarsanız, başkasının perspektifinden bakma yeteneği gelişir.',
      ),
    ],
  };

  static DailyTip getTipOfDay(String ageGroup) {
    final groupTips = tips[ageGroup] ?? tips['0-2']!;

    final now = DateTime.now();
    final dateSeed = now.year * 10000 + now.month * 100 + now.day;

    final random = Random(dateSeed);
    final index = random.nextInt(groupTips.length);

    return groupTips[index];
  }
}
