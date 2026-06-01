import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  int get _ageInMonths {
    final now = DateTime.now();
    var months =
        (now.year - widget.birthDate.year) * 12 +
        now.month -
        widget.birthDate.month;
    if (now.day < widget.birthDate.day) months--;
    return months.clamp(0, 72);
  }

  String get _ageText {
    final months = _ageInMonths;
    if (months < 12) return '$months Ay';
    final years = months ~/ 12;
    final rest = months % 12;
    if (rest == 0) return '$years Yaş';
    return '$years Yaş $rest Ay';
  }

  String get _ageGroup {
    final month = _ageInMonths;
    if (month <= 6) return '0-6 ay';
    if (month <= 12) return '7-12 ay';
    if (month <= 18) return '13-18 ay';
    if (month <= 24) return '19-24 ay';
    if (month <= 36) return '25-36 ay';
    if (month <= 48) return '3-4 yaş';
    if (month <= 60) return '4-5 yaş';
    return '5-6 yaş';
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  void _getUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _currentUserId = user.uid;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
          if (!mounted || !doc.exists) return;
          setState(() {
            _userRole = doc.data()?['role'] ?? 'parent';
            _userName =
                doc.data()?['name'] ??
                (_userRole == 'bakici' ? 'Bakıcı' : 'Ebeveyn');
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final ageGroup = _ageGroup;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Gelişim Kontrol Listesi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF5D4037),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg1.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.white.withValues(alpha: 0.36)),
            ),
          ),
          SafeArea(
            child: FutureBuilder<String>(
              future: _loadChildName(),
              builder: (context, childSnapshot) {
                final childName = childSnapshot.data ?? 'Minik';

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('development')
                      .where('ageGroup', isEqualTo: ageGroup)
                      .snapshots(),
                  builder: (context, devSnapshot) {
                    final indicators = _indicatorsFromSnapshot(
                      devSnapshot,
                      ageGroup,
                    );

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('completed_milestones')
                          .where('childId', isEqualTo: widget.childId)
                          .snapshots(),
                      builder: (context, completedSnapshot) {
                        final completedIds = completedSnapshot.hasData
                            ? completedSnapshot.data!.docs
                                  .map(
                                    (doc) =>
                                        doc.data()['milestoneId'] as String?,
                                  )
                                  .whereType<String>()
                                  .toSet()
                            : <String>{};

                        final total = indicators.length;
                        final completed = indicators
                            .where((item) => completedIds.contains(item.id))
                            .length;
                        final progress = total == 0 ? 0.0 : completed / total;
                        final grouped = _groupByArea(indicators);

                        return CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  14,
                                  18,
                                  118,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _DevelopmentHero(
                                      childName: childName,
                                      ageText: _ageText,
                                      progress: progress,
                                    ),
                                    const SizedBox(height: 16),
                                    _AreaSummaryGrid(
                                      grouped: grouped,
                                      completedIds: completedIds,
                                    ),
                                    const SizedBox(height: 18),
                                    ..._developmentAreas.map((area) {
                                      final items = grouped[area] ?? const [];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 14,
                                        ),
                                        child: _ChecklistAreaCard(
                                          area: area,
                                          indicators: items,
                                          completedIds: completedIds,
                                          canEdit: _userRole != 'bakici',
                                          onChanged: _toggleIndicator,
                                        ),
                                      );
                                    }),
                                    _AttentionCard(
                                      grouped: grouped,
                                      completedIds: completedIds,
                                    ),
                                    const SizedBox(height: 14),
                                    const _DevelopmentSourceCard(),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  Future<String> _loadChildName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('children')
          .doc(widget.childId)
          .get();
      final name = (doc.data()?['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    return 'Minik';
  }

  List<_DevelopmentIndicator> _indicatorsFromSnapshot(
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
    String ageGroup,
  ) {
    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
      return snapshot.data!.docs
          .map((doc) {
            final data = doc.data();
            return _DevelopmentIndicator(
              id: doc.id,
              area: _normalizeArea(data['area'] ?? data['category']),
              title: _stringValue(data['title'], ''),
              description: _stringValue(data['description'], ''),
              ageGroup: _stringValue(data['ageGroup'], ageGroup),
            );
          })
          .where((item) => item.title.isNotEmpty)
          .toList();
    }
    return _fallbackIndicators(ageGroup);
  }

  Map<String, List<_DevelopmentIndicator>> _groupByArea(
    List<_DevelopmentIndicator> indicators,
  ) {
    return {
      for (final area in _developmentAreas)
        area: indicators.where((item) => item.area == area).toList(),
    };
  }

  Future<void> _toggleIndicator(
    _DevelopmentIndicator indicator,
    bool completed,
  ) async {
    if (_userRole == 'bakici') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gelişim durumunu sadece ebeveynler değiştirebilir.'),
        ),
      );
      return;
    }

    final coll = FirebaseFirestore.instance.collection('completed_milestones');
    if (completed) {
      await coll.add({
        'childId': widget.childId,
        'milestoneId': indicator.id,
        'completedAt': FieldValue.serverTimestamp(),
        'authorId': _currentUserId,
        'authorName': _userName,
      });
      await FirebaseFirestore.instance.collection('activity_log').add({
        'childId': widget.childId,
        'authorId': _currentUserId,
        'authorName': _userName,
        'userRole': _userRole,
        'actionType': 'milestone_completed',
        'timestamp': FieldValue.serverTimestamp(),
        'details': indicator.title,
      });
      return;
    }

    final query = await coll
        .where('childId', isEqualTo: widget.childId)
        .where('milestoneId', isEqualTo: indicator.id)
        .get();
    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }
}

const _developmentAreas = [
  'Bilişsel Gelişim',
  'Dil Gelişimi',
  'Motor Gelişim',
  'Sosyal ve Duygusal Gelişim',
];

class _DevelopmentIndicator {
  final String id;
  final String area;
  final String title;
  final String description;
  final String ageGroup;

  const _DevelopmentIndicator({
    required this.id,
    required this.area,
    required this.title,
    required this.description,
    required this.ageGroup,
  });
}

String _stringValue(dynamic value, String fallback) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String _normalizeArea(dynamic value) {
  final text = value?.toString().toLowerCase() ?? '';
  if (text.contains('dil')) return 'Dil Gelişimi';
  if (text.contains('motor') || text.contains('hareket')) {
    return 'Motor Gelişim';
  }
  if (text.contains('sosyal') || text.contains('duygusal')) {
    return 'Sosyal ve Duygusal Gelişim';
  }
  return 'Bilişsel Gelişim';
}

List<_DevelopmentIndicator> _fallbackIndicators(String ageGroup) {
  final data = _fallbackByAge[ageGroup] ?? _fallbackByAge['5-6 yaş']!;
  return [
    for (final area in _developmentAreas)
      for (var i = 0; i < (data[area] ?? const <String>[]).length; i++)
        _DevelopmentIndicator(
          id: 'fallback_${ageGroup}_${area}_$i',
          area: area,
          title: data[area]![i],
          description: 'Yaş dönemine uygun gelişim göstergesi.',
          ageGroup: ageGroup,
        ),
  ];
}

final Map<String, Map<String, List<String>>> _fallbackByAge = {
  '0-6 ay': {
    'Bilişsel Gelişim': [
      'Yüzleri ve parlak nesneleri kısa süre izler',
      'Sesin geldiği yöne dikkatini yöneltir',
      'Tanıdık bakım veren kişiyi ayırt etmeye başlar',
    ],
    'Dil Gelişimi': [
      'Ağlama dışında sesler çıkarır',
      'Konuşan kişiye bakarak tepki verir',
      'Ses tonundaki değişiklikleri fark eder',
    ],
    'Motor Gelişim': [
      'Başını kısa süre dik tutar',
      'Ellerini ağzına götürür',
      'Yüzüstü yatarken başını kaldırmaya çalışır',
    ],
    'Sosyal ve Duygusal Gelişim': [
      'Tanıdık sese sakinleşerek tepki verir',
      'Sosyal gülümseme gösterir',
      'Kucağa alınca rahatlar',
    ],
  },
  '7-12 ay': {
    'Bilişsel Gelişim': [
      'Saklanan nesneyi aramaya çalışır',
      'Nesneleri elden ele geçirir',
      'Basit neden-sonuç oyunlarına ilgi gösterir',
    ],
    'Dil Gelişimi': [
      'İsmini duyunca tepki verir',
      'Hece tekrarları yapar',
      'Basit yönergelere dikkat eder',
    ],
    'Motor Gelişim': [
      'Desteksiz oturur',
      'Emekleme ya da yer değiştirme girişimleri yapar',
      'Küçük nesneleri parmaklarıyla kavrar',
    ],
    'Sosyal ve Duygusal Gelişim': [
      'Tanıdık kişilerle etkileşim kurar',
      'Ayrılık durumunda tepki gösterebilir',
      'Basit oyunlara katılır',
    ],
  },
  '13-18 ay': {
    'Bilişsel Gelişim': [
      'Nesneleri amacına uygun kullanmaya başlar',
      'Basit problem çözme denemeleri yapar',
      'Resimli kitaplara kısa süre ilgi gösterir',
    ],
    'Dil Gelişimi': [
      'Birkaç anlamlı kelime kullanır',
      'Basit sözel yönergeleri anlar',
      'İstediği şeyi işaret ederek anlatır',
    ],
    'Motor Gelişim': [
      'Destekle ya da bağımsız yürür',
      'Kule yapmak için blokları üst üste koyar',
      'Kaşık kullanmayı dener',
    ],
    'Sosyal ve Duygusal Gelişim': [
      'Bakım veren kişiye yakın olmak ister',
      'Basit taklit oyunları yapar',
      'Duygularını mimik ve sesle ifade eder',
    ],
  },
  '19-24 ay': {
    'Bilişsel Gelişim': [
      'Benzer nesneleri eşleştirir',
      'Basit yapboz parçalarını dener',
      'Günlük rutinleri hatırlar',
    ],
    'Dil Gelişimi': [
      'İki kelimeli ifadeler kullanır',
      'Tanıdık nesnelerin adını söyler',
      'Kısa yönergeleri yerine getirir',
    ],
    'Motor Gelişim': [
      'Topu atar veya yuvarlar',
      'Karalama yapar',
      'Merdiven çıkmayı dener',
    ],
    'Sosyal ve Duygusal Gelişim': [
      'Kendi başına yapmak ister',
      'Basit sıra alma oyunlarına katılır',
      'Duygusal tepkileri daha belirginleşir',
    ],
  },
  '25-36 ay': {
    'Bilişsel Gelişim': [
      'Renk ve şekilleri ayırt etmeye başlar',
      'Hayali oyunlar kurar',
      'Basit sınıflandırmalar yapar',
    ],
    'Dil Gelişimi': [
      '3-4 kelimelik cümleler kurar',
      'Kısa hikaye veya olayı anlatmaya çalışır',
      'Sorulara basit cevaplar verir',
    ],
    'Motor Gelişim': [
      'Koşar ve zıplamayı dener',
      'Boncuk dizme gibi ince motor etkinlikleri yapar',
      'Basit çizgiler çizer',
    ],
    'Sosyal ve Duygusal Gelişim': [
      'Akranlarıyla kısa süreli oyun oynar',
      'Duygularını sözcüklerle ifade etmeye başlar',
      'Basit kurallara uyum göstermeye çalışır',
    ],
  },
  '3-4 yaş': {
    'Bilişsel Gelişim': [
      'Nesneleri renk veya şekline göre gruplar',
      'Basit neden-sonuç ilişkileri kurar',
      'Kısa süreli dikkatini etkinliğe verir',
    ],
    'Dil Gelişimi': [
      'Kendini kısa cümlelerle anlatır',
      'Basit hikayeleri dinler ve cevap verir',
      'Yeni kelimeleri günlük konuşmada kullanır',
    ],
    'Motor Gelişim': [
      'Tek ayak üzerinde kısa süre durur',
      'Makas kullanmayı dener',
      'Topu hedefe doğru atar',
    ],
    'Sosyal ve Duygusal Gelişim': [
      'Arkadaşlarıyla oyun başlatır',
      'Beklemeyi ve sıra almayı öğrenir',
      'Duygularını ifade etmek için sözcük kullanır',
    ],
  },
  '4-5 yaş': {
    'Bilişsel Gelişim': [
      'Sayı ve miktar kavramlarına ilgi gösterir',
      'Örüntüleri fark eder ve devam ettirir',
      'Problem durumlarına çözüm önerir',
    ],
    'Dil Gelişimi': [
      'Olayları sırasıyla anlatır',
      'Neden-sonuç içeren cümleler kurar',
      'Sorular sorarak bilgi edinir',
    ],
    'Motor Gelişim': [
      'Kalemi daha kontrollü kullanır',
      'Denge gerektiren hareketleri yapar',
      'Kendi kıyafetlerini giymeye yardım eder',
    ],
    'Sosyal ve Duygusal Gelişim': [
      'Grup oyunlarında kurallara uyar',
      'Duygularını daha uygun yollarla ifade eder',
      'Sorumluluk almaya istek gösterir',
    ],
  },
  '5-6 yaş': {
    'Bilişsel Gelişim': [
      'Basit plan yapar ve uygular',
      'Sayı, harf ve sembollere ilgi gösterir',
      'Karşılaştırma ve sınıflama yapar',
    ],
    'Dil Gelişimi': [
      'Duygu ve düşüncelerini ayrıntılı anlatır',
      'Hikaye oluşturur ve tamamlar',
      'Dinlediği metinle ilgili soruları yanıtlar',
    ],
    'Motor Gelişim': [
      'Çizgi ve şekilleri kontrollü çizer',
      'Koordinasyon gerektiren hareketleri yapar',
      'İnce motor gerektiren etkinlikleri tamamlar',
    ],
    'Sosyal ve Duygusal Gelişim': [
      'Akranlarıyla iş birliği yapar',
      'Kurallı oyunlara katılır',
      'Duygularını tanır ve ifade eder',
    ],
  },
};

class _DevelopmentHero extends StatelessWidget {
  final String childName;
  final String ageText;
  final double progress;

  const _DevelopmentHero({
    required this.childName,
    required this.ageText,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A342B).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👶 $childName • $ageText',
            style: const TextStyle(
              color: Color(0xFF7B5145),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gelişim Kontrol Listesi',
            style: TextStyle(
              color: Color(0xFF3F312C),
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu ay gelişim göstergelerinin %$percent’si tamamlandı.',
            style: const TextStyle(
              color: Color(0xFF6D5B52),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF0DED3),
              color: const Color(0xFF7EAD7D),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaSummaryGrid extends StatelessWidget {
  final Map<String, List<_DevelopmentIndicator>> grouped;
  final Set<String> completedIds;

  const _AreaSummaryGrid({required this.grouped, required this.completedIds});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _developmentAreas.map((area) {
            final items = grouped[area] ?? const <_DevelopmentIndicator>[];
            final done = items
                .where((item) => completedIds.contains(item.id))
                .length;
            return SizedBox(
              width: width,
              child: _AreaSummaryCard(
                area: area,
                completed: done,
                total: items.length,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _AreaSummaryCard extends StatelessWidget {
  final String area;
  final int completed;
  final int total;

  const _AreaSummaryCard({
    required this.area,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _areaVisual(area);
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      height: 142,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(visual.icon, color: visual.color, size: 20),
          ),
          const Spacer(),
          Text(
            area,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF3F312C),
              fontSize: 13,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed/$total tamamlandı',
            style: const TextStyle(
              color: Color(0xFF8D7D75),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF0DED3),
              color: visual.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistAreaCard extends StatelessWidget {
  final String area;
  final List<_DevelopmentIndicator> indicators;
  final Set<String> completedIds;
  final bool canEdit;
  final Future<void> Function(_DevelopmentIndicator indicator, bool completed)
  onChanged;

  const _ChecklistAreaCard({
    required this.area,
    required this.indicators,
    required this.completedIds,
    required this.canEdit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _areaVisual(area);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(visual.icon, color: visual.color, size: 22),
          ),
          title: Text(
            area,
            style: const TextStyle(
              color: Color(0xFF3F312C),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            '${indicators.where((item) => completedIds.contains(item.id)).length}/${indicators.length} gösterge tamamlandı',
            style: const TextStyle(
              color: Color(0xFF8D7D75),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: indicators.map((indicator) {
            final checked = completedIds.contains(indicator.id);
            return CheckboxListTile(
              value: checked,
              onChanged: canEdit
                  ? (value) => onChanged(indicator, value ?? false)
                  : null,
              activeColor: const Color(0xFF5D4037),
              checkColor: Colors.white,
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                indicator.title,
                style: TextStyle(
                  color: checked
                      ? const Color(0xFF9A8E88)
                      : const Color(0xFF4A342B),
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final Map<String, List<_DevelopmentIndicator>> grouped;
  final Set<String> completedIds;

  const _AttentionCard({required this.grouped, required this.completedIds});

  @override
  Widget build(BuildContext context) {
    var weakestArea = _developmentAreas.first;
    var weakestRatio = 1.0;
    for (final area in _developmentAreas) {
      final items = grouped[area] ?? const <_DevelopmentIndicator>[];
      if (items.isEmpty) continue;
      final done = items.where((item) => completedIds.contains(item.id)).length;
      final ratio = done / items.length;
      if (ratio < weakestRatio) {
        weakestRatio = ratio;
        weakestArea = area;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.84)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFE28A3A)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$weakestArea alanında bazı göstergeler henüz tamamlanmadı.',
              style: const TextStyle(
                color: Color(0xFF5D4037),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevelopmentSourceCard extends StatelessWidget {
  const _DevelopmentSourceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      ),
      child: const Text(
        'Bu gelişim göstergeleri 0-3 yaş için MEB 0-36 Ay Eğitim Programı referans alınarak, 3-6 yaş için okul öncesi gelişim alanlarıyla uyumlu olacak şekilde hazırlanmıştır.',
        style: TextStyle(
          color: Color(0xFF6D5B52),
          fontSize: 12,
          height: 1.38,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

({IconData icon, Color color}) _areaVisual(String area) {
  switch (area) {
    case 'Dil Gelişimi':
      return (
        icon: Icons.record_voice_over_rounded,
        color: const Color(0xFF7BA3C8),
      );
    case 'Motor Gelişim':
      return (
        icon: Icons.directions_run_rounded,
        color: const Color(0xFF7EAD7D),
      );
    case 'Sosyal ve Duygusal Gelişim':
      return (
        icon: Icons.favorite_border_rounded,
        color: const Color(0xFFC77D9B),
      );
    default:
      return (
        icon: Icons.psychology_alt_rounded,
        color: const Color(0xFF8C7BC8),
      );
  }
}
