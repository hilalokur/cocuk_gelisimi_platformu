import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'utils/who_growth_analyzer.dart';

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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

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
                              const SizedBox(height: 20),
                              _buildChartCard(
                                'Baş Çevresi (cm)',
                                records,
                                'head',
                                Colors.purple,
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
          _statItem(
            Icons.face_retouching_natural,
            _formatMeasurement(data['head']),
            'cm',
            'Baş',
          ),
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
    final analiz = _friendlyAnalysisText(data['analiz'] ?? 'Analiz bekleniyor...');
    final headText = data['head'] == null
        ? ''
        : ', Baş: ${_formatMeasurement(data['head'])} cm';

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
          'Boy: ${data['height']} cm, Kilo: ${data['weight']} kg$headText\nDurum: $analiz',
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
    final headController = TextEditingController();
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
            TextField(
              controller: headController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Baş çevresi (cm)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (hController.text.isNotEmpty && wController.text.isNotEmpty) {
                final height = _parseMeasurement(hController.text);
                final weight = _parseMeasurement(wController.text);
                final head = headController.text.trim().isEmpty
                    ? null
                    : _parseMeasurement(headController.text);

                // ÇÖZÜM BURADA: Değişkeni en üstte, dışarıda tanımlıyoruz!
                String analizMesaji = _fallbackAnalysis(height, weight, head);

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
                    final cinsiyetStr =
                        (childDoc['gender'] ?? '').toString();
                    final analysis = WhoGrowthAnalyzer.analyze(
                      ageMonths: kacAylik,
                      gender: cinsiyetStr,
                      heightCm: height,
                      weightKg: weight,
                      headCm: head,
                    );
                    analizMesaji = analysis.summary;
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
                      if (head != null) 'head': head,
                      'analiz': analizMesaji, // Şimdi sorunsuz çalışır!
                    });

                if (!context.mounted) return;
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
        .where((e) {
          final value = (e.$2.data() as Map<String, dynamic>)[field];
          return value is num;
        })
        .map((e) {
          final value = (e.$2.data() as Map<String, dynamic>)[field] as num;
          return FlSpot(e.$1.toDouble(), value.toDouble());
        })
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

  double _parseMeasurement(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  String _formatMeasurement(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
    }
    return '-';
  }

  String _friendlyAnalysisText(String text) {
    if (!text.contains('z=') && !text.contains('medyan')) return text;

    var friendly = text
        .replaceAll(RegExp(r'\s*\([^)]*(z=|medyan)[^)]*\)'), '')
        .replaceAll('WHO standardına göre', 'WHO büyüme standartlarına göre hazırlanmıştır.')
        .replaceAll('çok düşük', 'beklenen aralığın belirgin altında')
        .replaceAll('düşük', 'beklenen aralığın altında')
        .replaceAll('normal aralıkta', 'beklenen aralıkta')
        .replaceAll('çok yüksek', 'beklenen aralığın belirgin üzerinde')
        .replaceAll('yüksek', 'beklenen aralığın üzerinde')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (!friendly.endsWith('.')) friendly = '$friendly.';
    if (!friendly.contains('doktor')) {
      friendly = '$friendly Ölçüm beklenen aralığın dışındaysa çocuk doktorunuzla paylaşmanız önerilir.';
    }
    return friendly;
  }

  String _fallbackAnalysis(double height, double weight, double? head) {
    final parts = <String>[
      height > 0 ? 'Boy kaydedildi' : 'Boy ölçümü eksik',
      weight > 0 ? 'Kilo kaydedildi' : 'Kilo ölçümü eksik',
      if (head != null && head > 0) 'Baş çevresi kaydedildi',
    ];
    return '${parts.join(', ')}. Düzenli takip için yeni ölçümler ekleyin.';
  }
}
