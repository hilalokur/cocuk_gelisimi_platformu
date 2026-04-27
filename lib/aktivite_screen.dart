import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AktiviteScreen extends StatefulWidget {
  final String childId;
  final DateTime birthDate;

  const AktiviteScreen({
    super.key,
    required this.childId,
    required this.birthDate,
  });

  @override
  State<AktiviteScreen> createState() => _AktiviteScreenState();
}

class _AktiviteScreenState extends State<AktiviteScreen> {
  String _userRole = 'parent';

  String get _ageGroup {
    final ageInDays = DateTime.now().difference(widget.birthDate).inDays;
    final ageInYears = ageInDays / 365;
    if (ageInYears < 2) return '0-2';
    if (ageInYears < 4) return '2-4';
    return '4-6';
  }

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  void _getUserRole() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (mounted && doc.exists) {
          setState(() {
            _userRole = doc.data()?['role'] ?? 'parent';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentGroup = _ageGroup;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Oyun ve Etkinlik', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, fontFamily: 'serif')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF5D4037),
        actions: [
          if (_userRole != 'bakici')
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _initializeActivityData(),
              tooltip: 'Örnek Veri Yükle',
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/bg1.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Color(0xFF5D4037), size: 40),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$currentGroup Yaş Aktivite Önerileri',
                                    style: const TextStyle(
                                      color: Color(0xFF5D4037),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      fontFamily: 'serif',
                                    ),
                                  ),
                                  Text(
                                    'Gelişimi destekleyen eğlenceli aktiviteler.',
                                    style: TextStyle(
                                      color: Colors.brown.shade400,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.italic,
                                      fontFamily: 'serif',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Text(
                    'Bugünün Aktiviteleri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                      fontStyle: FontStyle.italic,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('activities')
                        .where('ageGroup', isEqualTo: currentGroup)
                        .orderBy('title', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        debugPrint('Aktivite Hatası: ${snapshot.error}');
                        return Center(child: Text('Veriler yüklenirken bir hata oluştu.', style: const TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic)));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF5D4037)));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Henüz aktivite önerisi yok.',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontFamily: 'serif'),
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF5D4037).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.play_circle_fill, color: Color(0xFF5D4037), size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              data['title'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF5D4037),
                                                fontStyle: FontStyle.italic,
                                                fontFamily: 'serif',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        data['description'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                          height: 1.5,
                                          fontWeight: FontWeight.w500,
                                          fontStyle: FontStyle.italic,
                                          fontFamily: 'serif',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeActivityData() async {
    final coll = FirebaseFirestore.instance.collection('activities');
    final existing = await coll.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final List<Map<String, dynamic>> initialData = [
      {'ageGroup': '0-2', 'title': 'Ce-e Oyunu', 'description': 'Bebeğinizin nesne sürekliliğini anlamasına ve sosyal etkileşimini geliştirmesine yardımcı olur.'},
      {'ageGroup': '0-2', 'title': 'Ayna Karşısında Vakit', 'description': 'Bebeğinizin kendisini tanımasına ve motor becerilerinin gelişmesine katkı sağlar.'},
      {'ageGroup': '0-2', 'title': 'Dokun-Hisset Kitapları', 'description': 'Farklı dokulara sahip kitaplar, bebeğinizin duyusal gelişimini ve merak duygusunu artırır.'},
      {'ageGroup': '2-4', 'title': 'Yapboz Tamamlama', 'description': 'Basit yapbozlar, çocuğunuzun problem çözme yeteneğini ve el-göz koordinasyonunu geliştirir.'},
      {'ageGroup': '2-4', 'title': 'Renkli Gruplama', 'description': 'Oyuncakları renklerine göre ayırmak, bilişsel sınıflandırma becerilerini güçlendirir.'},
      {'ageGroup': '2-4', 'title': 'Resimli Hikaye Anlatma', 'description': 'Kitaptaki resimlere bakarak hikaye oluşturmak, dil gelişimini ve hayal gücünü destekler.'},
      {'ageGroup': '4-6', 'title': 'Evcilik Oyunu', 'description': 'Rol yapma oyunları, sosyal ve duygusal gelişimi, aynı zamanda empati kurma yeteneğini artırır.'},
      {'ageGroup': '4-6', 'title': 'Basit Deneyler', 'description': 'Suda yüzen ve batan nesneleri test etmek gibi basit aktiviteler merak ve öğrenme isteğini tetikler.'},
      {'ageGroup': '4-6', 'title': 'Origami Başlangıcı', 'description': 'Kağıt katlama sanatına giriş, ince motor becerilerini ve sabrı geliştirir.'},
    ];

    final batch = FirebaseFirestore.instance.batch();
    for (var item in initialData) {
      batch.set(coll.doc(), item);
    }
    await batch.commit();
  }
}
