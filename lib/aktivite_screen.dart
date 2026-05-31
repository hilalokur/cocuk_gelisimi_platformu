import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_model.dart';
import '../data/activity_data.dart';
import 'data_seeder.dart';

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
    if (ageInYears < 3) return '2-3';
    if (ageInYears < 4) return '3-4';

    // 4 yaş ve üzeri tüm çocuklar için (5, 6, 7 yaş olsa bile)
    // '4-5' yaş aktivitelerini göstersin ki ekran boş kalmasın.
    return '4-5';
  }

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  void _getUserRole() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
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
        title: const Text(
          'Oyun ve Etkinlik',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF5D4037),
        // AppBar içindeki actions kısmında:
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sayfayı Yenile',
            onPressed: () {
              // Bu kod sayfayı baştan çizer (yeniler)
              setState(() {});
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg1.png', fit: BoxFit.cover),
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
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF5D4037),
                              size: 40,
                            ),
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
                                    ),
                                  ),
                                  Text(
                                    'Gelişimi destekleyen eğlenceli aktiviteler.',
                                    style: TextStyle(
                                      color: Colors.brown.shade400,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
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
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('activities')
                        .where(
                          'ageGroup',
                          isEqualTo: currentGroup,
                        ) // Yaşa göre filtrele
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        debugPrint('Aktivite Hatası: ${snapshot.error}');
                        return Center(
                          child: Text(
                            'Veriler yüklenirken bir hata oluştu.',
                            style: const TextStyle(),
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF5D4037),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Henüz aktivite önerisi yok.',
                            style: TextStyle(color: Colors.grey),
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
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF5D4037,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.play_circle_fill,
                                              color: Color(0xFF5D4037),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              data['title'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF5D4037),
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

    // Zaten veri var mı diye kontrol et (gereksiz yazmayı önler)
    final existing = await coll.limit(1).get();
    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktiviteler zaten güncel!')),
      );
      return;
    }

    final batch = FirebaseFirestore.instance.batch();

    // Model içindeki listeyi kullanarak tertemiz bir döngü kuruyoruz
    for (var activity in ActivityData.activities) {
      batch.set(coll.doc(), activity.toMap());
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bakanlık verileri başarıyla yüklendi!')),
    );
  }
}
