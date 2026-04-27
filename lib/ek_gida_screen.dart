import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EkGidaScreen extends StatefulWidget {
  final String childId;
  final DateTime birthDate;

  const EkGidaScreen({
    super.key,
    required this.childId,
    required this.birthDate,
  });

  @override
  State<EkGidaScreen> createState() => _EkGidaScreenState();
}

class _EkGidaScreenState extends State<EkGidaScreen> {
  String _userRole = 'parent';
  String _userName = 'Ebeveyn';
  String? _currentUserId;

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

  int get _childMonths {
    final now = DateTime.now();
    int months = (now.year - widget.birthDate.year) * 12 + now.month - widget.birthDate.month;
    if (now.day < widget.birthDate.day) months--;
    return months < 0 ? 0 : months;
  }

  void _showFoodDetails(BuildContext context, Map<String, dynamic> foodData, bool isTried, String foodId) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text(
            foodData['food'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tavsiye Edilen Ay: ${foodData['month']}. Ay',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontFamily: 'serif', fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              Text(
                foodData['note'] ?? '',
                style: const TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              if (isTried)
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Bu gıda denendi.',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontFamily: 'serif', fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat', style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic)),
            ),
            if (_userRole != 'bakici')
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _toggleFoodTried(foodId, foodData['food'] ?? '', isTried);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTried ? Colors.redAccent : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isTried ? 'Denenmedi Olarak İşaretle' : 'Denendi Olarak İşaretle',
                  style: const TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFoodTried(String foodId, String foodName, bool isTried) async {
    try {
      final coll = FirebaseFirestore.instance.collection('tried_foods');
      if (isTried) {
        final query = await coll
            .where('childId', isEqualTo: widget.childId)
            .where('foodId', isEqualTo: foodId)
            .get();
        for (var doc in query.docs) {
          await doc.reference.delete();
        }
      } else {
        await coll.add({
          'childId': widget.childId,
          'foodId': foodId,
          'triedAt': FieldValue.serverTimestamp(),
        });

        // Activity Log ekle
        await FirebaseFirestore.instance.collection('activity_log').add({
          'childId': widget.childId,
          'authorId': _currentUserId,
          'authorName': _userName,
          'userRole': _userRole,
          'actionType': 'food_tried',
          'timestamp': FieldValue.serverTimestamp(),
          'details': '$foodName denendi.',
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMonths = _childMonths;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Ek Gıda Rehberi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF5D4037),
        actions: [
          if (_userRole != 'bakici')
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _initializeFoods(),
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
                            const Text(
                              'Bebeğiniz Şu An',
                              style: TextStyle(
                                color: Color(0xFF5D4037),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'serif',
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$currentMonths Aylık',
                              style: const TextStyle(
                                color: Color(0xFF5D4037),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'serif',
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5D4037).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Ayına uygun beslenme listesi',
                                style: TextStyle(
                                  color: Color(0xFF5D4037),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'serif',
                                  fontStyle: FontStyle.italic,
                                ),
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
                    'Önerilen Gıdalar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('foods')
                        .where('month', isLessThanOrEqualTo: currentMonths)
                        .orderBy('month', descending: true)
                        .snapshots(),
                    builder: (context, foodSnapshot) {
                      if (foodSnapshot.hasError) {
                        debugPrint('Gıda Hatası: ${foodSnapshot.error}');
                        return Center(child: Text('Veriler yüklenirken bir hata oluştu.', style: const TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic)));
                      }
                      if (foodSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF5D4037)));
                      }

                      if (!foodSnapshot.hasData || foodSnapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('tried_foods')
                            .where('childId', isEqualTo: widget.childId)
                            .orderBy('triedAt', descending: true)
                            .snapshots(),
                        builder: (context, triedSnapshot) {
                          if (triedSnapshot.hasError) {
                            debugPrint('Tried Foods Hatası: ${triedSnapshot.error}');
                          }
                          final triedFoodIds = triedSnapshot.hasData
                              ? triedSnapshot.data!.docs.map((d) => d['foodId'] as String).toSet()
                              : <String>{};

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: foodSnapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final doc = foodSnapshot.data!.docs[index];
                              final foodData = doc.data() as Map<String, dynamic>;
                              final foodId = doc.id;
                              final isTried = triedFoodIds.contains(foodId);

                              return InkWell(
                                onTap: () => _showFoodDetails(context, foodData, isTried, foodId),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
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
                                      child: Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isTried ? Colors.green.shade100 : const Color(0xFF5D4037).withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isTried ? Icons.check_circle : Icons.restaurant_menu,
                                                color: isTried ? Colors.green.shade800 : const Color(0xFF5D4037),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    foodData['food'] ?? '',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: const Color(0xFF5D4037),
                                                      fontFamily: 'serif',
                                                      fontStyle: FontStyle.italic,
                                                      decoration: isTried ? TextDecoration.lineThrough : null,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    foodData['note'] ?? '',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.brown.shade400,
                                                      fontFamily: 'serif',
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: BorderRadius.circular(6)),
                                                    child: Text(
                                                      '${foodData['month']}. Ay itibariyle',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.brown.shade700,
                                                        fontWeight: FontWeight.bold,
                                                        fontFamily: 'serif',
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (_userRole != 'bakici')
                                              _TriedToggleButton(
                                                childId: widget.childId,
                                                foodId: foodId,
                                                foodName: foodData['food'] ?? '',
                                                isTried: isTried,
                                                userRole: _userRole,
                                                userId: _currentUserId ?? '',
                                                userName: _userName,
                                                onToggle: (newStatus) => _toggleFoodTried(foodId, foodData['food'] ?? '', !newStatus),
                                              ),
                                          ],
                                        ),
                                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: const Color(0xFF5D4037).withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          const Text(
            'Henüz uygun gıda bulunamadı.',
            style: TextStyle(
              color: Colors.grey,
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeFoods() async {
    final coll = FirebaseFirestore.instance.collection('foods');
    final existing = await coll.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final List<Map<String, dynamic>> initialFoods = [
      {'month': 6, 'food': 'Yoğurt', 'note': 'Ev yapımı, günlük taze yoğurt.'},
      {'month': 6, 'food': 'Elma Püresi', 'note': 'Cam rendede rendelenmiş elma.'},
      {'month': 6, 'food': 'Havuç Püresi', 'note': 'Haşlanmış ve ezilmiş havuç.'},
      {'month': 6, 'food': 'Pirinç Unu Muhallebi', 'note': 'Anne sütü veya formül mama ile.'},
      {'month': 7, 'food': 'Yumurta Sarısı', 'note': '1/8 oranında başlayarak, tam pişmiş.'},
      {'month': 7, 'food': 'Sebze Çorbası', 'note': 'Mevsim sebzeleri ile tuzsuz.'},
      {'month': 8, 'food': 'Kıyma', 'note': 'Çift çekilmiş kuzu kıyma, sebze yemeklerine.'},
      {'month': 8, 'food': 'Peynir', 'note': 'Tuzu alınmış lor veya beyaz peynir.'},
      {'month': 9, 'food': 'Balık', 'note': 'Kılçıksız, buğulama veya haşlama.'},
      {'month': 9, 'food': 'Baklagiller', 'note': 'İyi haşlanmış mercimek, kuru fasulye.'},
      {'month': 12, 'food': 'Bal', 'note': '1 yaşından önce kesinlikle verilmemelidir.'},
      {'month': 12, 'food': 'İnek Sütü', 'note': 'Doğrudan içecek olarak 1 yaşından sonra.'},
    ];

    final batch = FirebaseFirestore.instance.batch();
    for (var f in initialFoods) {
      batch.set(coll.doc(), f);
    }
    await batch.commit();
  }
}

class _TriedToggleButton extends StatefulWidget {
  final String childId;
  final String foodId;
  final String foodName;
  final bool isTried;
  final String userRole;
  final String userId;
  final String userName;
  final Function(bool) onToggle;

  const _TriedToggleButton({
    required this.childId,
    required this.foodId,
    required this.foodName,
    required this.isTried,
    required this.userRole,
    required this.userId,
    required this.userName,
    required this.onToggle,
  });

  @override
  State<_TriedToggleButton> createState() => _TriedToggleButtonState();
}

class _TriedToggleButtonState extends State<_TriedToggleButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const SizedBox(width: 48, height: 48, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)))
        : IconButton(
            icon: Icon(
              widget.isTried ? Icons.check_circle : Icons.add_circle_outline,
              color: widget.isTried ? Colors.green : Colors.grey.shade400,
              size: 28,
            ),
            onPressed: () async {
              if (widget.userRole == 'bakici') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sadece ebeveynler gıdaları işaretleyebilir.'))
                );
                return;
              }
              setState(() => _isLoading = true);
              await widget.onToggle(widget.isTried);
              if (mounted) setState(() => _isLoading = false);
            },
          );
  }
}
