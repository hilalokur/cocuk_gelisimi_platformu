import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'utils/notification_service.dart';

class VaccineCalendarPage extends StatefulWidget {
  final String childId;
  final String childName;
  final DateTime birthDate;

  const VaccineCalendarPage({
    super.key,
    required this.childId,
    required this.childName,
    required this.birthDate,
  });

  @override
  State<VaccineCalendarPage> createState() => _VaccineCalendarPageState();
}

class _VaccineCalendarPageState extends State<VaccineCalendarPage> {
  late Stream<QuerySnapshot> _vaccinesStream;
  String _userRole = 'parent';
  String? _currentUserId;
  String _userName = 'Ebeveyn';

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _vaccinesStream = FirebaseFirestore.instance
        .collection('vaccines_records')
        .where('childId', isEqualTo: widget.childId)
        .orderBy('month', descending: false)
        .snapshots();

    // Ensure vaccines are initialized after first frame to avoid issues during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureVaccinesInitialized();
    });
  }

  void _getUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((userDoc) {
            if (mounted && userDoc.exists) {
              setState(() {
                final userData = userDoc.data() as Map<String, dynamic>?;
                _userRole = userData?['role'] ?? 'parent';
                _userName =
                    userData?['name'] ??
                    (_userRole == 'bakici' ? 'Bakıcı' : 'Ebeveyn');
              });
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '${widget.childName} - Aşı Takvimi',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF5D4037),
        actions: [
          if (_userRole != 'bakici')
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _initializeVaccines(),
              tooltip: 'Verileri Başlat',
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
            child: StreamBuilder<QuerySnapshot>(
              stream: _vaccinesStream,
              builder: (context, vaccineSnapshot) {
                if (vaccineSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Veriler yüklenirken bir hata oluştu.\nLütfen internet bağlantınızı kontrol edin veya dizinlerin oluşturulduğundan emin olun.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.brown.shade900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hata detayı: ${vaccineSnapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (vaccineSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5D4037)),
                  );
                }

                if (!vaccineSnapshot.hasData ||
                    vaccineSnapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final vaccines = vaccineSnapshot.data!.docs;
                Map<int, List<QueryDocumentSnapshot>> groupedVaccines = {};
                for (var doc in vaccines) {
                  final data = doc.data() as Map<String, dynamic>;
                  int month = data['month'] ?? 0;
                  groupedVaccines
                      .putIfAbsent(month, () => [])
                      .add(doc as QueryDocumentSnapshot);
                }

                final sortedMonths = groupedVaccines.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: sortedMonths.length,
                  itemBuilder: (context, index) {
                    final month = sortedMonths[index];
                    final vaccinesInMonth = groupedVaccines[month]!;
                    final vaccineDate = widget.birthDate.add(
                      Duration(days: month * 30),
                    );
                    // Eski hali: final bool isPast = vaccineDate.isBefore(DateTime.now());
                    // Yeni hali: Ayın son gününü bul ve o gün geçmediyse üstünü çizme
                    final lastDayOfMonth = DateTime(
                      vaccineDate.year,
                      vaccineDate.month + 1,
                      0,
                      23,
                      59,
                    );
                    final bool isPast = lastDayOfMonth.isBefore(DateTime.now());
                    return _TimelineSection(
                      month: month,
                      date: vaccineDate,
                      vaccines: vaccinesInMonth,
                      isPast: isPast, // Buraya yeni parametreyi ekledik
                      onToggle: (docId, isDone) {
                        if (_userRole == 'bakici') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Aşı durumunu sadece ebeveynler değiştirebilir.',
                              ),
                            ),
                          );
                          return;
                        }
                        final vDoc = vaccinesInMonth.firstWhere(
                          (d) => d.id == docId,
                        );
                        final vData = vDoc.data() as Map<String, dynamic>;
                        final vName = vData['name'] ?? 'Aşı';
                        _updateVaccinationStatus(docId, isDone, vName);
                      },
                      isLast: index == sortedMonths.length - 1,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateVaccinationStatus(
    String docId,
    bool isDone,
    String vaccineName,
  ) async {
    await FirebaseFirestore.instance
        .collection('vaccines_records')
        .doc(docId)
        .update({
          'done': isDone,
          'completedAt': isDone ? FieldValue.serverTimestamp() : null,
          'authorId': _currentUserId,
          'authorName': _userName,
        });

    if (isDone) {
      await FirebaseFirestore.instance.collection('activity_log').add({
        'childId': widget.childId,
        'authorId': _currentUserId,
        'authorName': _userName,
        'userRole': _userRole,
        'actionType': 'vaccine_completed',
        'timestamp': FieldValue.serverTimestamp(),
        'details': vaccineName,
      });
    }
  }

  Future<void> _ensureVaccinesInitialized() async {
    try {
      final coll = FirebaseFirestore.instance.collection('vaccines_records');
      final QuerySnapshot existing = await coll
          .where('childId', isEqualTo: widget.childId)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await _initializeVaccines();
      }
    } catch (e) {
      debugPrint('Aşılar başlatılırken hata: $e');
    }
  }

  Future<void> _initializeVaccines() async {
    try {
      final coll = FirebaseFirestore.instance.collection('vaccines_records');

      final List<Map<String, dynamic>> initialVaccines = [
        {
          'month': 0,
          'name': 'Hepatit B',
          'dose': '1. Doz',
          'description': 'Hepatit B virüsüne karşı koruma sağlar.',
        },
        {
          'month': 1,
          'name': 'Hepatit B',
          'dose': '2. Doz',
          'description': 'Hepatit B bağışıklığını güçlendirir.',
        },
        {
          'month': 2,
          'name': 'BCG (Verem)',
          'dose': '1. Doz',
          'description': 'Tüberküloza (verem) karşı koruma sağlar.',
        },
        {
          'month': 2,
          'name': 'DaBT-İPA-Hib',
          'dose': '1. Doz',
          'description':
              'Difteri, Boğmaca, Tetanos, Çocuk Felci ve Menenjit karma aşısı.',
        },
        {
          'month': 2,
          'name': 'KPA',
          'dose': '1. Doz',
          'description':
              'Zatürre, menenjit ve orta kulak iltihabına karşı korur.',
        },
        {
          'month': 4,
          'name': 'DaBT-İPA-Hib',
          'dose': '2. Doz',
          'description': 'Karma aşı ikinci doz.',
        },
        {
          'month': 4,
          'name': 'KPA',
          'dose': '2. Doz',
          'description': 'Zatürre aşısı ikinci doz.',
        },
        {
          'month': 6,
          'name': 'Hepatit B',
          'dose': '3. Doz',
          'description': 'Hepatit B serisi tamamlanır.',
        },
        {
          'month': 6,
          'name': 'DaBT-İPA-Hib',
          'dose': '3. Doz',
          'description': 'Karma aşı üçüncü doz.',
        },
        {
          'month': 6,
          'name': 'KPA',
          'dose': '3. Doz',
          'description': 'Zatürre aşısı üçüncü doz.',
        },
        {
          'month': 6,
          'name': 'OPA',
          'dose': '1. Doz',
          'description': 'Ağızdan yapılan çocuk felci aşısı.',
        },
        {
          'month': 12,
          'name': 'KKK',
          'dose': '1. Doz',
          'description': 'Kızamık, Kabakulak ve Kızamıkçık aşısı.',
        },
        {
          'month': 12,
          'name': 'KPA',
          'dose': 'Pekiştirme',
          'description': 'Zatürre aşısı pekiştirme dozu.',
        },
        {
          'month': 12,
          'name': 'Suçiçeği',
          'dose': '1. Doz',
          'description': 'Suçiçeği hastalığına karşı korur.',
        },
        {
          'month': 18,
          'name': 'DaBT-İPA-Hib',
          'dose': 'Pekiştirme',
          'description': 'Karma aşı pekiştirme dozu.',
        },
        {
          'month': 18,
          'name': 'OPA',
          'dose': '2. Doz',
          'description': 'Ağızdan çocuk felci ikinci doz.',
        },
        {
          'month': 18,
          'name': 'Hepatit A',
          'dose': '1. Doz',
          'description': 'Karaciğer iltihabına (Hepatit A) kaşı korur.',
        },
        {
          'month': 24,
          'name': 'Hepatit A',
          'dose': '2. Doz',
          'description': 'Hepatit A serisi tamamlanır.',
        },
      ];

      final batch = FirebaseFirestore.instance.batch();
      for (var v in initialVaccines) {
        final newDoc = coll.doc();
        batch.set(newDoc, {
          ...v,
          'childId': widget.childId,
          'done': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Bildirimleri planla
        final int month = v['month'] ?? 0;
        final vaccineDate = widget.birthDate.add(Duration(days: month * 30));
        if (vaccineDate.isAfter(DateTime.now())) {
          NotificationService().scheduleNotification(
            id: newDoc.id.hashCode,
            title: 'Aşı Hatırlatıcı',
            body:
                '${widget.childName} için ${v['name']} (${v['dose']}) aşısı yaklaşıyor.',
            scheduledDate: vaccineDate.subtract(const Duration(days: 1)),
          );
        }
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aşı takvimi başarıyla oluşturuldu.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aşılar oluşturulurken hata: $e')),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 80,
              color: Colors.brown.shade100,
            ),
            const SizedBox(height: 20),
            const Text(
              'Aşı verisi bulunamadı.',
              style: TextStyle(
                color: Color(0xFF5D4037),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Çocuğunuz için aşı takvimi henüz oluşturulmamış olabilir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.brown),
            ),
            if (_userRole != 'bakici') ...[
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => _initializeVaccines(),
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Aşı Takvimini Oluştur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D4037),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final int month;
  final DateTime date;
  final List<QueryDocumentSnapshot> vaccines;
  final Function(String, bool) onToggle;
  final bool isLast;
  final bool isPast;

  const _TimelineSection({
    required this.month,
    required this.date,
    required this.vaccines,
    required this.onToggle,
    required this.isLast,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line and Dot
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFF5D4037).withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      month == 0 ? 'Doğumda' : '$month. Ay',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('MMMM yyyy', 'tr_TR').format(date),
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...vaccines.map((v) {
                  final data = v.data() as Map<String, dynamic>;
                  final vId = v.id;
                  final isDone = data['done'] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDone
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDone
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${data['name']} (${data['dose']})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        // DEĞİŞİKLİK BURADA: Eğer aşı yapıldıysa (isDone) VEYA tarihi geçtiyse (isPast) gri yap
                                        color: (isDone || isPast)
                                            ? Colors.grey
                                            : (isDone
                                                  ? Colors.green.shade900
                                                  : const Color(0xFF5D4037)),

                                        // DEĞİŞİKLİK BURADA: Eğer yapıldıysa VEYA tarihi geçtiyse üstünü çiz
                                        decoration: (isDone || isPast)
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data['description'] ??
                                          'Açıklama bulunmuyor.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade900,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: isDone,
                                activeColor: Colors.green,
                                onChanged: (val) => onToggle(vId, val ?? false),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
