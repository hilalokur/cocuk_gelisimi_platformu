import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/activity_data.dart';

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
  String? _selectedCategory;

  static const _categories = [
    'Duyusal',
    'Zeka',
    'İnce Motor',
    'Hareket',
    'Dil',
    'Müzik',
    'Sosyal',
  ];

  String get _ageGroup {
    final ageInDays = DateTime.now().difference(widget.birthDate).inDays;
    final ageInYears = ageInDays / 365;
    if (ageInYears < 2) return '0-2';
    if (ageInYears < 3) return '2-3';
    if (ageInYears < 4) return '3-4';
    return '4-5';
  }

  @override
  Widget build(BuildContext context) {
    final ageGroup = _ageGroup;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Oyun ve Etkinlik',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF5D4037),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
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
                      .collection('activities')
                      .where('ageGroup', isEqualTo: ageGroup)
                      .snapshots(),
                  builder: (context, activitySnapshot) {
                    final activities = _activitiesFromSnapshot(
                      activitySnapshot,
                      ageGroup,
                    );
                    final visibleActivities = _selectedCategory == null
                        ? activities
                        : activities
                              .where(
                                (item) => item.category == _selectedCategory,
                              )
                              .toList();
                    final pool = visibleActivities.isNotEmpty
                        ? visibleActivities
                        : activities;
                    final ordered = _dailyOrder(pool);
                    final featured = ordered.first;
                    final suggestions = ordered.skip(1).take(4).toList();

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 118),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ActivityHero(childName: childName),
                                const SizedBox(height: 16),
                                _FeaturedActivityCard(
                                  activity: featured,
                                  onStart: () => _showActivitySheet(featured),
                                ),
                                const SizedBox(height: 18),
                                _CategoryChips(
                                  categories: _categories,
                                  selectedCategory: _selectedCategory,
                                  onSelected: (category) {
                                    setState(() {
                                      _selectedCategory =
                                          _selectedCategory == category
                                          ? null
                                          : category;
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                const _SectionTitle(
                                  title: 'Bugün Şunları da Deneyebilirsiniz',
                                ),
                                const SizedBox(height: 12),
                                _SuggestionGrid(
                                  activities: suggestions.isEmpty
                                      ? ordered.take(4).toList()
                                      : suggestions,
                                  onTap: _showActivitySheet,
                                ),
                                const SizedBox(height: 18),
                                const _ExpertTipCard(),
                                const SizedBox(height: 14),
                                const _WeeklyStatsCard(),
                              ],
                            ),
                          ),
                        ),
                      ],
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
      final data = doc.data();
      final name = (data?['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    return 'Minik';
  }

  List<_ActivityViewData> _activitiesFromSnapshot(
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
    String ageGroup,
  ) {
    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
      return snapshot.data!.docs
          .map((doc) => _ActivityViewData.fromMap(doc.data(), ageGroup))
          .where((item) => item.title.trim().isNotEmpty)
          .toList();
    }
    return _fallbackActivities(ageGroup);
  }

  List<_ActivityViewData> _dailyOrder(List<_ActivityViewData> items) {
    final copy = [...items];
    final seed = DateTime.now().difference(DateTime(2024)).inDays;
    copy.shuffle(math.Random(seed));
    return copy;
  }

  List<_ActivityViewData> _fallbackActivities(String ageGroup) {
    final base = ActivityData.activities
        .where((item) => item.ageGroup == ageGroup)
        .toList();
    final source = base.isNotEmpty ? base : ActivityData.activities;
    final categories = _categories;
    return List.generate(source.length, (index) {
      final item = source[index];
      final category = categories[index % categories.length];
      return _ActivityViewData(
        title: item.title,
        description: item.description,
        ageGroup: item.ageGroup,
        category: category,
        duration: '${8 + (index % 4) * 4} dk',
        developmentArea: _developmentAreaFor(category),
        icon: _iconForCategory(category),
        color: _colorForCategory(category),
      );
    });
  }

  void _showActivitySheet(_ActivityViewData activity) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFF8F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ActivityIconBadge(activity: activity, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        activity.title,
                        style: const TextStyle(
                          color: Color(0xFF3F312C),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  activity.description,
                  style: const TextStyle(
                    color: Color(0xFF6D5B52),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniMetaChip(label: activity.duration),
                    _MiniMetaChip(label: activity.ageGroup),
                    _MiniMetaChip(label: activity.developmentArea),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityViewData {
  final String title;
  final String description;
  final String ageGroup;
  final String category;
  final String duration;
  final String developmentArea;
  final IconData icon;
  final Color color;

  const _ActivityViewData({
    required this.title,
    required this.description,
    required this.ageGroup,
    required this.category,
    required this.duration,
    required this.developmentArea,
    required this.icon,
    required this.color,
  });

  factory _ActivityViewData.fromMap(
    Map<String, dynamic> data,
    String fallbackAge,
  ) {
    final category = _stringValue(data['category'], 'Duyusal');
    return _ActivityViewData(
      title: _stringValue(data['title'], ''),
      description: _stringValue(
        data['description'],
        'Kısa ve keyifli bir gelişim aktivitesi.',
      ),
      ageGroup: _stringValue(data['ageGroup'], fallbackAge),
      category: category,
      duration: _stringValue(data['duration'], '10 dk'),
      developmentArea: _stringValue(
        data['developmentArea'],
        _developmentAreaFor(category),
      ),
      icon: _iconFromValue(data['icon'], category),
      color: _colorFromValue(data['color'], category),
    );
  }
}

String _stringValue(dynamic value, String fallback) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

IconData _iconFromValue(dynamic value, String category) {
  final key = value?.toString().toLowerCase().trim();
  switch (key) {
    case 'music':
    case 'müzik':
      return Icons.music_note_rounded;
    case 'language':
    case 'dil':
      return Icons.record_voice_over_rounded;
    case 'movement':
    case 'hareket':
      return Icons.directions_run_rounded;
    case 'puzzle':
    case 'zeka':
      return Icons.extension_rounded;
    case 'sensory':
    case 'duyusal':
      return Icons.auto_awesome_rounded;
    case 'social':
    case 'sosyal':
      return Icons.groups_rounded;
    default:
      return _iconForCategory(category);
  }
}

IconData _iconForCategory(String category) {
  switch (category) {
    case 'Zeka':
      return Icons.psychology_alt_rounded;
    case 'İnce Motor':
      return Icons.gesture_rounded;
    case 'Hareket':
      return Icons.directions_run_rounded;
    case 'Dil':
      return Icons.record_voice_over_rounded;
    case 'Müzik':
      return Icons.music_note_rounded;
    case 'Sosyal':
      return Icons.groups_rounded;
    default:
      return Icons.auto_awesome_rounded;
  }
}

Color _colorFromValue(dynamic value, String category) {
  final text = value?.toString().trim();
  if (text != null && text.isNotEmpty) {
    final normalized = text.replaceAll('#', '');
    final parsed = int.tryParse('FF$normalized', radix: 16);
    if (parsed != null) return Color(parsed);
  }
  return _colorForCategory(category);
}

Color _colorForCategory(String category) {
  switch (category) {
    case 'Zeka':
      return const Color(0xFF8C7BC8);
    case 'İnce Motor':
      return const Color(0xFFD08A7B);
    case 'Hareket':
      return const Color(0xFF7EAD7D);
    case 'Dil':
      return const Color(0xFF7BA3C8);
    case 'Müzik':
      return const Color(0xFFC89364);
    case 'Sosyal':
      return const Color(0xFFC77D9B);
    default:
      return const Color(0xFF7CB89B);
  }
}

String _developmentAreaFor(String category) {
  switch (category) {
    case 'Zeka':
      return 'Bilişsel Gelişim';
    case 'İnce Motor':
      return 'İnce Motor';
    case 'Hareket':
      return 'Kaba Motor';
    case 'Dil':
      return 'Dil Gelişimi';
    case 'Müzik':
      return 'Ritim ve İşitsel';
    case 'Sosyal':
      return 'Sosyal Duygusal';
    default:
      return 'Duyusal Gelişim';
  }
}

class _ActivityHero extends StatelessWidget {
  final String childName;

  const _ActivityHero({required this.childName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A342B).withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF7ECE4),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'Günlük Seri',
              style: TextStyle(
                color: Color(0xFF7B5145),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$childName için Bugünkü Öneriler',
            style: const TextStyle(
              color: Color(0xFF3F312C),
              fontSize: 24,
              height: 1.08,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bugün yaşına uygun 3 aktivite önerildi.',
            style: TextStyle(
              color: Color(0xFF6D5B52),
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedActivityCard extends StatelessWidget {
  final _ActivityViewData activity;
  final VoidCallback onStart;

  const _FeaturedActivityCard({required this.activity, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: activity.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
        boxShadow: [
          BoxShadow(
            color: activity.color.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ActivityIconBadge(activity: activity, size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.category,
                      style: TextStyle(
                        color: activity.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF3F312C),
                        fontSize: 20,
                        height: 1.16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            activity.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF5D4D45),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniMetaChip(label: activity.ageGroup),
              _MiniMetaChip(label: activity.duration),
              _MiniMetaChip(label: activity.developmentArea),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D4037),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
              child: const Text(
                'Aktiviteyi Başlat →',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => onSelected(category),
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF6D5B52),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: const Color(0xFF5D4037),
            backgroundColor: Colors.white.withValues(alpha: 0.72),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF3F312C),
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SuggestionGrid extends StatelessWidget {
  final List<_ActivityViewData> activities;
  final ValueChanged<_ActivityViewData> onTap;

  const _SuggestionGrid({required this.activities, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: activities.take(4).map((activity) {
            return SizedBox(
              width: cardWidth,
              child: _SmallActivityCard(
                activity: activity,
                onTap: () => onTap(activity),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SmallActivityCard extends StatelessWidget {
  final _ActivityViewData activity;
  final VoidCallback onTap;

  const _SmallActivityCard({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 172,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A342B).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ActivityIconBadge(activity: activity, size: 38),
                const Spacer(),
                Text(
                  activity.duration,
                  style: const TextStyle(
                    color: Color(0xFF8D7D75),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              activity.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF3F312C),
                fontSize: 14,
                height: 1.18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                activity.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6D5B52),
                  fontSize: 11.2,
                  height: 1.28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityIconBadge extends StatelessWidget {
  final _ActivityViewData activity;
  final double size;

  const _ActivityIconBadge({required this.activity, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: activity.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(activity.icon, color: activity.color, size: size * 0.48),
    );
  }
}

class _MiniMetaChip extends StatelessWidget {
  final String label;

  const _MiniMetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6D5B52),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ExpertTipCard extends StatelessWidget {
  const _ExpertTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFE28A3A)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aktiviteleri kısa tutmak, çocuğun dikkat süresini korur.',
              style: TextStyle(
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

class _WeeklyStatsCard extends StatelessWidget {
  const _WeeklyStatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatPill(
              icon: Icons.check_circle_outline_rounded,
              title: 'Bu hafta',
              value: '4 aktivite tamamlandı',
              color: const Color(0xFF7EAD7D),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatPill(
              icon: Icons.local_fire_department_rounded,
              title: 'Seri',
              value: '3 günlük seri',
              color: const Color(0xFFE28A3A),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF8D7D75),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF3F312C),
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
