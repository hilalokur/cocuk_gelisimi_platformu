import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

// --- 1. EKRAN KISMI (Görünüm) ---
class EkGidaScreen extends StatelessWidget {
  final String childId;
  final DateTime birthDate;

  const EkGidaScreen(
      {super.key, required this.childId, required this.birthDate});

  void _openDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? "${data['month']}. Ay Rehberi",
                    style: const TextStyle(fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E)),
                  ),
                  const Divider(height: 30),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        data['foodInfo'],
                        style: const TextStyle(
                            fontSize: 18, height: 1.6), // Büyük ve ferah metin
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF574343),
                        padding: const EdgeInsets.all(15),
                      ),
                      child: const Text("Kapat",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
  Widget _buildCategoryIcon(int month) {
    if (month == -2) {
      // Anne Sütü için Kalp
      return const Icon(Icons.favorite, color: Color(0xFFD81B60), size: 20);
    } else if (month == -1) {
      // Genel Öneriler için Parlayan Yıldız
      return const Icon(Icons.auto_awesome, color: Color(0xFFFFA000), size: 20);
    } else if (month == 13) {
      // Okul Öncesi için Okul İkonu
      return const Icon(Icons.school, color: Color(0xFF1976D2), size: 20);
    } else {
      // Normal aylar (0, 6, 7, 8...) için mevcut sayı tasarımı
      return Text(
        "$month",
        style: const TextStyle(
            color: Color(0xFF4B2E2A),
            fontWeight: FontWeight.bold
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // 1. Arka Plan: Puslu Görsel Katmanı
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg1.png'), // Kendi görsel yolunu kontrol et
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),

          // 2. İçerik Katmanı
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF4B2E2A)),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Bebek Beslenme Rehberi',
                style: TextStyle(
                  color: Color(0xFF4B2E2A),
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            body: Column(
              children: [
                // Üstteki Öne Çıkan Kart (Yumuşak Krem Tonu)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: Color(0xFF4B2E2A), size: 28),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Text(
                            "Bakanlık Onaylı Güncel Bilgiler",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B2E2A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Aylara Göre Liste
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('foods').orderBy('month').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                          // 1. ADIM: Ay değerini bir değişkene atayalım
                          int monthVal = data['month'] ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF4B2E2A).withOpacity(0.1),
                                // 2. ADIM: Buradaki Text'i sildik ve fonksiyonu çağırdık
                                child: _buildCategoryIcon(monthVal),
                              ),
                              title: Text(
                                data['title'] ?? "${monthVal}. Ay Önerileri",
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4B2E2A)),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF4B2E2A)),
                              onTap: () => _openDetails(context, data),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // SİZİN İSTEDİĞİNİZ ÖZEL ALT BİLGİ NOTU
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // Arka plana uyum için opaklık eklendi
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Bu sayfadaki tüm veriler",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Text(
                        "T.C. Sağlık Bakanlığı",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3333), // İstediğiniz özel ton
                        ),
                      ),
                      const Text(
                        "resmi verileri kullanılarak hazırlanmıştır.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. VERİ SERVİSİ KISMI (Arka Plan) ---
class WebDataService {
  final List<String> _urls = [
    'https://hsgm.saglik.gov.tr/tr/beslenme/bebek-beslenmesi.html',
    'https://hsgm.saglik.gov.tr/tr/beslenme/okul-oncesi-beslenme.html'
  ];

  Future<void> syncMinistryData() async {
    try {
      var existingDocs = await FirebaseFirestore.instance.collection('foods').get();
      for (var doc in existingDocs.docs) { await doc.reference.delete(); }

      // Menü başlıklarını ve bitişik metinleri engellemek için liste
      final List<String> blackList = [
        "Ana Sayfa", "Başkanlığımız", "Daire Başkanı", "Görev Tanımı",
        "Dokümanlar", "Afişler", "Broşürler", "İngilizce Yayınlar",
        "Kitaplar", "Rehberler", "Programlar", "Sunumlar",
        "Videolar", "Haberler", "İletişim", "Yazdır", "Yeterli ve Dengeli Beslenme",
        "Temel Besin Grupları", "Yaş Dönemlerinde Beslenme", "Gebelik Döneminde Beslenme",
        "Emziklilik Döneminde Beslenme", "Bebek Beslenmesi", "Okul Öncesinde Sağlıklı Beslenme",
        "Okul Çağı Çocuklarında Beslenme", "Ergenlik Döneminde Beslenme", "Yaşlılıkta Beslenme",
        "Menopoz Döneminde Beslenme", "Özel Durumlarda Beslenme", "Hastalıklarda Beslenme",
        "Besin Güvenliği ve Hijyen", "BaşkanlığımızDaire BaşkanıGörev Tanımı",
        "DokümanlarAfişlerBroşürlerİngilizce YayınlarKitaplarRehberlerProgramlarSunumlarVideolar","Aylara Göre Verilmesi Önerilen Tamamlayıcı Besinler"
      ];

      for (String url in _urls) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          var document = parser.parse(response.body);
          var contentArea = document.querySelector('.content-area') ?? document.body;
          if (contentArea == null) continue;

          // --- OKUL ÖNCESİ BESLENME (Değiştirilmedi) ---
          if (url.contains('okul-oncesi')) {
            String fullContent = "";
            bool startCollecting = false;
            var allElements = contentArea.querySelectorAll('*');

            for (var element in allElements) {
              String text = element.text.trim();
              String tag = (element.localName ?? "").toLowerCase();

              if (text.toLowerCase().contains('öneriler aşağıda sıralanmıştır')) {
                startCollecting = true;
                continue;
              }

              if (startCollecting) {
                if (text.contains('Son Güncelleme')) break;
                bool isBadData = blackList.any((badWord) => text.contains(badWord));
                bool isJoinedMenu = text.length > 20 && !text.contains(' ');
                if (isBadData || isJoinedMenu || text.isEmpty) continue;

                if (tag == 'li' && text.length > 25) {
                  fullContent += "• $text\n\n";
                } else if (tag == 'p' && (text.length > 40 || text.contains('el yıkama'))) {
                  fullContent += "$text\n\n";
                }
              }
            }
            if (fullContent.isNotEmpty) {
              await _saveToFirebase(13, 'Okul Öncesi Sağlıklı Beslenme', fullContent.trim());
            }
          }

          // --- BEBEK BESLENMESİ (Sadece fazlalıklar silindi) ---
          else {
            String introContent = "";
            var allElements = contentArea.querySelectorAll('p, ul, strong');

            for (var element in allElements) {
              String text = element.text.trim();
              if (text.contains('. ay')) break;

              // --- SADECE BU KISIMDAKİ FAZLALIKLARI SİLEN FİLTRE ---
              bool isMenuText = blackList.any((badWord) => text == badWord);
              bool isLongJoinedText = text.length > 30 && !text.contains(' ');

              if (isMenuText || isLongJoinedText || text.isEmpty) continue;

              if (element.localName == 'p' && text.length > 25) {
                introContent += "$text\n\n";
              } else if (element.localName == 'ul') {
                var items = element.querySelectorAll('li')
                    .map((e) => e.text.trim())
                    .where((t) => t.length > 5 && !blackList.contains(t)); // Liste içindeki fazlalıkları siler
                if (items.isNotEmpty) {
                  introContent += "• ${items.join("\n• ")}\n\n";
                }
              }
            }
            if (introContent.isNotEmpty) {
              await _saveToFirebase(-2, 'Bebek Beslenmesi ve Anne Sütü', introContent.trim());
            }

            final headers = contentArea.querySelectorAll('strong, h3, h4');
            for (var header in headers) {
              String title = header.text.trim();
              bool isMonth = title.contains('. ay');
              bool isGeneral = title.toLowerCase().contains('öneri') ||
                  title.toLowerCase().contains('ilke') ||
                  title.toLowerCase().contains('emzirme');

              if (isMonth || isGeneral) {
                String details = "";
                var next = header.parent?.localName == 'p' ? header.parent?.nextElementSibling : header.nextElementSibling;

                int limit = 0;
                while (next != null && limit < 20) {
                  String nextTag = (next.localName ?? "").toLowerCase();
                  String nextText = next.text.trim();

                  if (nextText.contains('. ay') && (nextTag.startsWith('h') || next.querySelectorAll('strong').isNotEmpty)) break;

                  bool isRepeatInfo = nextText.contains('şeker ve şeker eklenmiş') ||
                      nextText.contains('6-12 aylık dönemde') ||
                      nextText.contains('Tuz: Tuz bebeği susatır') ||
                      nextText.contains('Tamamlayıcı besinler bebek açken')||
                      nextText.contains('Genel Öneriler');

                  if (isMonth && isRepeatInfo) {
                    next = next.nextElementSibling;
                    continue;
                  }

                  if (nextTag == 'ul') {
                    details += next.querySelectorAll('li').map((e) => "• ${e.text.trim()}").join("\n") + "\n";
                  } else if (nextTag == 'p' && nextText.length > 5) {
                    details += "$nextText\n\n";
                  }
                  next = next.nextElementSibling;
                  limit++;
                }

                if (details.isNotEmpty) {
                  int monthOrder = isMonth ? _calculateOrder(title) : -1;
                  await _saveToFirebase(monthOrder, title, details.trim());
                }
              }
            }
          }
        }
      }
      debugPrint("Senkronizasyon tamamlandı.");
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  Future<void> _saveToFirebase(int month, String title, String info) async {
    await FirebaseFirestore.instance.collection('foods').add({
      'month': month,
      'title': title,
      'foodInfo': info,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  int _calculateOrder(String text) {
    RegExp regExp = RegExp(r'(\d+)');
    var match = regExp.firstMatch(text);
    if (match != null) {
      int val = int.parse(match.group(0)!);
      return text.contains('yaş') ? val * 12 : val;
    }
    return 0;
  }
}

