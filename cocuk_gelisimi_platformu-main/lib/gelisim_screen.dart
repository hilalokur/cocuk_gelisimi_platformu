import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GelisimScreen extends StatefulWidget {
  final String childId;
  final DateTime birthDate;

  const GelisimScreen({
    super.key,
    required this.childId,
    required this.birthDate,
  });

  @override
  State<GelisimScreen> createState() => _GelisimScreenState();
}

class _GelisimScreenState extends State<GelisimScreen> {
  String _userRole = 'parent';
  String? _currentUserId;
  String _userName = 'Ebeveyn';

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
    _getUserInfo();
  }

  void _getUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (mounted && doc.exists) {
          setState(() {
            _userRole = doc.data()?['role'] ?? 'parent';
            _userName = doc.data()?['name'] ?? (_userRole == 'bakici' ? 'Bakıcı' : 'Ebeveyn');
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
        title: const Text('Gelişim Takibi', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, fontFamily: 'serif')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF5D4037),
        actions: [
          if (_userRole != 'bakici')
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _initializeDevelopmentData(),
              tooltip: 'Verileri Yükle',
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
                        padding: const EdgeInsets.all(25),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$currentGroup Yaş Grubu',
                              style: const TextStyle(
                                color: Color(0xFF5D4037),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Bu yaş grubundaki çocukların genel gelişim özellikleri aşağıdadır.',
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
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Text(
                    'Gelişim Kontrol Listesi',
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
                        .collection('development')
                        .where('ageGroup', isEqualTo: currentGroup)
                        .orderBy('title', descending: false)
                        .snapshots(),
                    builder: (context, devSnapshot) {
                      if (devSnapshot.hasError) {
                        debugPrint('Gelişim Hatası: ${devSnapshot.error}');
                        return Center(child: Text('Veriler yüklenirken bir hata oluştu.', style: const TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic)));
                      }
                      if (devSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF5D4037)));
                      }

                      if (!devSnapshot.hasData || devSnapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Henüz gelişim verisi yok.',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontFamily: 'serif'),
                          ),
                        );
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('completed_milestones')
                            .where('childId', isEqualTo: widget.childId)
                            .orderBy('completedAt', descending: true)
                            .snapshots(),
                        builder: (context, completedSnapshot) {
                          if (completedSnapshot.hasError) {
                            debugPrint('Completed Milestones Hatası: ${completedSnapshot.error}');
                          }
                          final completedIds = completedSnapshot.hasData
                              ? completedSnapshot.data!.docs.map((d) => d['milestoneId'] as String).toSet()
                              : <String>{};

                          final docs = devSnapshot.data!.docs;

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final id = doc.id;
                              final isChecked = completedIds.contains(id);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: CheckboxListTile(
                                      value: isChecked,
                                      onChanged: _userRole == 'bakici'
                                          ? (val) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Gelişim durumunu sadece ebeveynler değiştirebilir.')),
                                              );
                                            }
                                          : (val) async {
                                              final coll = FirebaseFirestore.instance.collection('completed_milestones');
                                              if (val == true) {
                                                await coll.add({
                                                  'childId': widget.childId,
                                                  'milestoneId': id,
                                                  'completedAt': FieldValue.serverTimestamp(),
                                                  'authorId': _currentUserId,
                                                  'authorName': _userName,
                                                });

                                                // Activity Log
                                                await FirebaseFirestore.instance.collection('activity_log').add({
                                                  'childId': widget.childId,
                                                  'authorId': _currentUserId,
                                                  'authorName': _userName,
                                                  'userRole': _userRole,
                                                  'actionType': 'milestone_completed',
                                                  'timestamp': FieldValue.serverTimestamp(),
                                                  'details': data['title'] ?? '',
                                                });
                                              } else {
                                                final query = await coll
                                                    .where('childId', isEqualTo: widget.childId)
                                                    .where('milestoneId', isEqualTo: id)
                                                    .get();
                                                for (var d in query.docs) {
                                                  await d.reference.delete();
                                                }
                                              }
                                            },
                                      activeColor: const Color(0xFF5D4037),
                                      checkColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: Text(
                                        data['title'] ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isChecked ? Colors.grey : const Color(0xFF5D4037),
                                          decoration: isChecked ? TextDecoration.lineThrough : null,
                                          fontStyle: FontStyle.italic,
                                          fontFamily: 'serif',
                                        ),
                                      ),
                                      subtitle: Text(
                                        data['description'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                          fontStyle: FontStyle.italic,
                                          fontFamily: 'serif',
                                        ),
                                      ),
                                      controlAffinity: ListTileControlAffinity.leading,
                                    ),
                                  ),
                                ),
                              );
                            },
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

  Future<void> _initializeDevelopmentData() async {
    final coll = FirebaseFirestore.instance.collection('development');
    final existing = await coll.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final List<Map<String, dynamic>> initialData = [
      {'ageGroup': '0-2', 'title': 'Emekleme', 'description': 'Destek almadan emekleyebilir.'},
      {'ageGroup': '0-2', 'title': 'Basit Kelimeler', 'description': 'Anne, baba gibi basit kelimeleri söyleyebilir.'},
      {'ageGroup': '0-2', 'title': 'Nesneleri Tutma', 'description': 'Küçük nesneleri parmaklarıyla kavrayabilir.'},
      {'ageGroup': '0-2', 'title': 'Sosyal Gülümseme', 'description': 'Tanıdık yüzlere gülümseyerek tepki verir.'},
      {'ageGroup': '2-4', 'title': 'Zıplama', 'description': 'İki ayağıyla yerden yükselebilir.'},
      {'ageGroup': '2-4', 'title': 'Cümle Kurma', 'description': '3-4 kelimelik basit cümleler kurabilir.'},
      {'ageGroup': '2-4', 'title': 'Kendi Başına Yemek', 'description': 'Kaşık kullanarak dökmeden yemek yiyebilir.'},
      {'ageGroup': '2-4', 'title': 'Renkleri Tanıma', 'description': 'Temel renkleri birbirinden ayırt edebilir.'},
      {'ageGroup': '4-6', 'title': 'Hikaye Anlatma', 'description': 'Yaşadığı bir olayı sırasıyla anlatabilir.'},
      {'ageGroup': '4-6', 'title': 'Düğme İlikleme', 'description': 'Kendi kıyafetlerinin düğmelerini ilikleyebilir.'},
      {'ageGroup': '4-6', 'title': 'Sayı Sayma', 'description': '10\'a kadar ritmik bir şekilde sayabilir.'},
    ];

    final batch = FirebaseFirestore.instance.batch();
    for (var item in initialData) {
      batch.set(coll.doc(), item);
    }
    await batch.commit();
  }
}
