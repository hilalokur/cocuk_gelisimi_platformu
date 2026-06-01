import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'data_seeder.dart';
import 'providers/child_provider.dart';
import 'utils/pdf_export_service.dart';

class BoyKiloScreen extends StatefulWidget {
  final String childId;
  const BoyKiloScreen({super.key, required this.childId});

  @override
  State<BoyKiloScreen> createState() => _BoyKiloScreenState();
}

class _BoyKiloScreenState extends State<BoyKiloScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final userRole = userData?['role'] ?? 'parent';
        final userName =
            userData?['name'] ?? (userRole == 'bakici' ? 'Bakıcı' : 'Ebeveyn');

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Boy & Kilo Takibi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: const Color(0xFF5D4037),

            /*******************
            // ---> İŞTE BUTONU BURAYA EKLİYORUZ (actions listesi içine) <---
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await GrowthDataSeeder.seedDataToFirebase();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veritabanı Kuruldu! Firebase\'e bak.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("DB Kur", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
            // ---> BUTON KODU BURADA BİTTİ <---
            */
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF5D4037),
              indicatorColor: const Color(0xFF5D4037),
              tabs: const [
                Tab(text: 'Geçmiş'),
                Tab(text: 'Grafik'),
              ],
            ),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset('assets/bg1.png', fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.white24),
                ),
              ),
              SafeArea(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('growth_records')
                      .where('childId', isEqualTo: widget.childId)
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                      return _buildEmptyState();

                    final records = snapshot.data!.docs;
                    final latestRecord =
                        records.first.data() as Map<String, dynamic>;

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        Column(
                          children: [
                            _buildLatestStats(latestRecord),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: records.length,
                                itemBuilder: (context, index) =>
                                    _buildRecordCard(
                                      records[index].data()
                                          as Map<String, dynamic>,
                                      records[index].id,
                                      userRole,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildChartCard(
                                'Boy (cm)',
                                records,
                                'height',
                                Colors.blue,
                              ),
                              const SizedBox(height: 20),
                              _buildChartCard(
                                'Kilo (kg)',
                                records,
                                'weight',
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: userRole == 'bakici'
              ? null
              : FloatingActionButton(
                  onPressed: () =>
                      _showAddRecordDialog(context, userName, userRole),
                  backgroundColor: const Color(0xFF5D4037),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
        );
      },
    );
  }

  Widget _buildLatestStats(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.height, '${data['height']}', 'cm', 'Boy'),
          _statItem(Icons.monitor_weight, '${data['weight']}', 'kg', 'Kilo'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String unit, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF5D4037)),
        Text(
          '$value $unit',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRecordCard(
    Map<String, dynamic> data,
    String docId,
    String userRole,
  ) {
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    // Veritabanından analizi çekiyoruz, eskiden eklenenlerde yoksa varsayılan metin gösteriyoruz
    final analiz = data['analiz'] ?? 'Analiz bekleniyor...';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white70,
      child: ListTile(
        title: Text(
          DateFormat('dd.MM.yyyy').format(date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // Alt başlıkta (subtitle) \n kullanarak analizi alt satıra yazdırıyoruz
        subtitle: Text(
          'Boy: ${data['height']} cm, Kilo: ${data['weight']} kg\nDurum: $analiz',
        ),
        trailing: userRole == 'bakici'
            ? null
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => FirebaseFirestore.instance
                    .collection('growth_records')
                    .doc(docId)
                    .delete(),
              ),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text('Kayıt bulunamadı.'));

  void _showAddRecordDialog(
    BuildContext context,
    String userName,
    String userRole,
  ) {
    final hController = TextEditingController();
    final wController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Ölçüm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Boy (cm)'),
            ),
            TextField(
              controller: wController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kilo (kg)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (hController.text.isNotEmpty && wController.text.isNotEmpty) {
                final height = double.tryParse(hController.text) ?? 0;
                final weight = double.tryParse(wController.text) ?? 0;

                // ÇÖZÜM BURADA: Değişkeni en üstte, dışarıda tanımlıyoruz!
                String analizMesaji = "Analiz yapılamadı.";

               try {
                  // 1. ADIM: Çocuğun profil bilgilerini çekiyoruz
                  DocumentSnapshot childDoc = await FirebaseFirestore.instance
                      .collection('children')
                      .doc(widget.childId)
                      .get();

                  if (childDoc.exists) {
                    // 2. ADIM: Kaç aylık olduğunu matematiksel olarak hesaplıyoruz
                    DateTime birthDate = (childDoc['birthDate'] as Timestamp).toDate();
                    DateTime now = DateTime.now();

                    int kacAylik = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
                    if (now.day < birthDate.day) {
                      kacAylik--;
                    }

                    // Sınırları belirliyoruz (0-72 ay)
                    if (kacAylik < 0) kacAylik = 0;
                    if (kacAylik > 72) kacAylik = 72;

                    // 12 aydan büyük ara ayları (13,14,16 vb.) tablodaki 3'er aylık dilimlere yuvarlar
                    if (kacAylik > 12 && kacAylik % 3 != 0) {
                      kacAylik = kacAylik - (kacAylik % 3);
                    }

                    // 3. ADIM: Cinsiyeti ayarlıyoruz
                    String cinsiyetStr = (childDoc['gender'] ?? '').toString().toLowerCase();
                    String dbCinsiyet = (cinsiyetStr == 'kız' || cinsiyetStr == 'kiz' || cinsiyetStr == 'female') ? 'kiz' : 'erkek';

                    // 4. ADIM: Doğru klasörden (boy_kilo) ve doğru isimle (sadece rakam) veriyi çekiyoruz!
                    DocumentSnapshot standardDoc = await FirebaseFirestore.instance
                        .collection('boy_kilo')
                        .doc('$kacAylik')
                        .get();

                    if (standardDoc.exists) {
                      // Hem kilo hem de boy verisini Firebase'den çekiyoruz
                      double idealKilo = (standardDoc['${dbCinsiyet}_kilo'] as num).toDouble();
                      double idealBoy = (standardDoc['${dbCinsiyet}_boy'] as num).toDouble();

                      // Kilo için %20 sapma (esneme payı)
                      double kiloAlt = idealKilo * 0.8;
                      double kiloUst = idealKilo * 1.2;

                      // Boy için %10 sapma (Boy daha az esneklik gösterir)
                      double boyAlt = idealBoy * 0.9;
                      double boyUst = idealBoy * 1.1;

                      // Kilo durumunu belirliyoruz
                      String kiloMesaji;
                      if (weight < kiloAlt) {
                        kiloMesaji = "Kilo düşük (İdeal: ${idealKilo.toStringAsFixed(1)} kg)";
                      } else if (weight > kiloUst) {
                        kiloMesaji = "Kilo yüksek (İdeal: ${idealKilo.toStringAsFixed(1)} kg)";
                      } else {
                        kiloMesaji = "Kilo ideal";
                      }

                      // Boy durumunu belirliyoruz
                      String boyMesaji;
                      if (height < boyAlt) {
                        boyMesaji = "Boy kısa (İdeal: ${idealBoy.toStringAsFixed(1)} cm)";
                      } else if (height > boyUst) {
                        boyMesaji = "Boy uzun (İdeal: ${idealBoy.toStringAsFixed(1)} cm)";
                      } else {
                        boyMesaji = "Boy ideal";
                      }

                      // İkisini birleştirip ekrana basılacak nihai mesajı oluşturuyoruz
                      analizMesaji = "$boyMesaji, $kiloMesaji.";
                    }
                  }
                } catch (e) {
                  debugPrint("Algoritma hatası: $e");
                }

                // ARTIK HATA VERMEYECEK: Çünkü analizMesaji'ni en üstte tanımladık.
                await FirebaseFirestore.instance
                    .collection('growth_records')
                    .add({
                      'childId': widget.childId,
                      'date': FieldValue.serverTimestamp(),
                      'height': height,
                      'weight': weight,
                      'analiz': analizMesaji, // Şimdi sorunsuz çalışır!
                    });

                Navigator.pop(context); // Dialog penceresini kapat
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    String title,
    List<QueryDocumentSnapshot> docs,
    String field,
    Color color,
  ) {
    final spots = docs.reversed.indexed
        .map(
          (e) => FlSpot(
            e.$1.toDouble(),
            (e.$2.data() as Map<String, dynamic>)[field]?.toDouble() ?? 0,
          ),
        )
        .toList();
    return Container(
      height: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white60,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(spots: spots, color: color, isCurved: true),
          ],
        ),
      ),
    );
  }
}
