import 'dart:ui';
import 'package:flutter/material.dart';
import 'cocuklarim_screen.dart';
import 'utils/ates_takip_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedAgeGroup = '0-2';

  @override
  Widget build(BuildContext context) {
    final userName = 'Ebeveyn';
    final userRole = 'parent';
    final currentChildId = 'test_child_123';

    final childDocs = [
      {
        'id': 'test_child_123',
        'name': 'Minik AdÄ±mlar',
        'birthDate': DateTime.now().subtract(const Duration(days: 365)),
        'photoUrl': ''
      }
    ];
    final selectedChildId = 'test_child_123';

    return Scaffold(
      // Siyah ekranÄ± Ã¶nlemek iÃ§in resmi kaldÄ±rÄ±p yerine uygulamanÄ±n soft krem tonunu verdik
      backgroundColor: const Color(0xFFFDF7F2),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFBF6),
              Color(0xFFF9EFE8),
              Color(0xFFFFFDF9),
            ],
          ),
        ),
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _HomeTab(
              userName: userName,
              childDocs: childDocs,
              selectedChildId: selectedChildId,
              selectedAgeGroup: _selectedAgeGroup,
              onAgeGroupChanged: (group) {
                setState(() {
                  _selectedAgeGroup = group;
                });
              },
            ),
            _BabyTrackingTab(
              childDocs: childDocs,
              selectedChildId: selectedChildId,
              currentChildId: currentChildId,
            ),
            _ProfileTab(userName: userName, userRole: userRole),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      floatingActionButton: _selectedIndex == 1 ? const _TrackingFab() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// --- TABS (SEKMELER) ---

class _HomeTab extends StatelessWidget {
  final String userName;
  final List<Map<String, dynamic>> childDocs;
  final String? selectedChildId;
  final String selectedAgeGroup;
  final Function(String) onAgeGroupChanged;

  const _HomeTab({
    required this.userName,
    required this.childDocs,
    this.selectedChildId,
    required this.selectedAgeGroup,
    required this.onAgeGroupChanged,
  });

  @override
  Widget build(BuildContext context) {
    final childData = childDocs.first;
    final childName = (childData['name'] as String?) ?? 'Minik';

    if (childName.isNotEmpty || childName.isEmpty) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFFFFF), Color(0xFFFFF6EF)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF4A342B,
                          ).withValues(alpha: 0.08),
                          blurRadius: 26,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF5D4037,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Text(
                                  'Bugünün Takibi',
                                  style: TextStyle(
                                    color: Color(0xFF5D4037),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Miniklerin Gelişim Rehberi',
                                style: TextStyle(
                                  color: Color(0xFF3F312C),
                                  fontSize: 29,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '$childName için gelişim, rutin ve sağlık notlarını düzenli takip edin.',
                                style: const TextStyle(
                                  color: Color(0xFF6D5B52),
                                  fontSize: 14,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 54,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D4037),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _HomeChildOverview(childName: childName),
                  const SizedBox(height: 18),
                  const Text(
                    'Yaş Dönemi',
                    style: TextStyle(
                      color: Color(0xFF3F312C),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AgeGroupSelector(
                    selectedGroup: selectedAgeGroup,
                    onChanged: onAgeGroupChanged,
                  ),
                  const SizedBox(height: 18),
                  _DailyTipCard(ageGroup: selectedAgeGroup),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Expanded(
                        child: _HomeQuickCard(
                          icon: Icons.favorite_rounded,
                          title: 'Sağlık',
                          value: 'Günlük kayıt',
                          color: Color(0xFFE58AA4),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _HomeQuickCard(
                          icon: Icons.timeline_rounded,
                          title: 'Gelişim',
                          value: 'Adım adım',
                          color: Color(0xFF679785),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HoÅŸgeldin,\n$userName',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                          fontFamily: 'serif',
                          fontStyle: FontStyle.italic),
                    ),
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF5D4037),
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        childData['name'] as String,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                            fontFamily: 'serif',
                            fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '1 yaÅŸÄ±nda',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.brown,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'serif',
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _AgeGroupSelector(
                  selectedGroup: selectedAgeGroup,
                  onChanged: onAgeGroupChanged),
              const SizedBox(height: 25),
              _DailyTipCard(ageGroup: selectedAgeGroup),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeChildOverview extends StatelessWidget {
  final String childName;

  const _HomeChildOverview({required this.childName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A342B).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF7EDEA),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              childName.isNotEmpty ? childName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFF5D4037),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3F312C),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Bugünkü gelişim akışına hazır',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF8D7D75),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF5D4037),
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _HomeQuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _HomeQuickCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3F312C),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8D7D75),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _BabyTrackingTab extends StatelessWidget {
  final List<Map<String, dynamic>> childDocs;
  final String? selectedChildId;
  final String? currentChildId;

  const _BabyTrackingTab({
    required this.childDocs,
    this.selectedChildId,
    this.currentChildId,
  });

  @override
  Widget build(BuildContext context) {
    final modules = _trackingModules(context);
    final childCount = childDocs.length;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Miniklerin Gelişim Rehberi',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                                color: Color(0xFF3F312C),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Ã‡ocuÄŸunun geliÅŸimini kolayca takip et â¤ï¸',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                                color: Color(0xFF6D5B52),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _HeaderIconButton(
                        icon: Icons.notifications_none_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Her adımında yanında olun; gelişim notları, aşı, beslenme ve etkinlikleri düzenli takip edin.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: Color(0xFF6D5B52),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TrackingSummaryStrip(childCount: childCount),
                  const SizedBox(height: 24),
                  if (childCount < 0)
                    _HeaderPillButton(
                      icon: Icons.add_rounded,
                      label: 'Ã‡ocuk Ekle',
                      onTap: () {},
                    ),
                  const SizedBox(height: 0),
                  _TrackingChildrenSection(
                    childDocs: childDocs,
                    selectedChildId: selectedChildId ?? currentChildId,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 172),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.84,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _TrackingGridCard(module: modules[index]),
                childCount: modules.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingModule {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TrackingModule({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

List<_TrackingModule> _trackingModules(BuildContext context) {
  return [
    _TrackingModule(
      title: 'Aktivite Günlüğü',
      description: 'Günlük aktiviteleri kaydet ve geçmişi görüntüle',
      icon: Icons.history_rounded,
      color: const Color(0xFFE6A15E),
      onTap: () {},
    ),
    _TrackingModule(
      title: 'Gelişim Günlüğü',
      description: 'Gelişim notlarını ekle ve ilerlemeyi izle',
      icon: Icons.auto_stories_rounded,
      color: const Color(0xFFE58AA4),
      onTap: () {},
    ),
    _TrackingModule(
      title: 'Aşı Takvimi',
      description: 'Aşı takvimini görüntüle ve hatırlatmaları kaçırma',
      icon: Icons.vaccines_rounded,
      color: const Color(0xFF6F9FE8),
      onTap: () {},
    ),
    _TrackingModule(
      title: 'Büyüme Grafiği',
      description: 'Boy, kilo ve baş çevresi grafiklerini incele',
      icon: Icons.show_chart_rounded,
      color: const Color(0xFF7CBF8C),
      onTap: () {},
    ),
    _TrackingModule(
      title: 'Gelişim Listesi',
      description: 'Gelişim basamaklarını takip et ve işaretle',
      icon: Icons.checklist_rounded,
      color: const Color(0xFFB984D8),
      onTap: () {},
    ),
    _TrackingModule(
      title: 'Ek Gıda Rehberi',
      description: 'Ek gıda önerileri ve tariflere ulaş',
      icon: Icons.restaurant_menu_rounded,
      color: const Color(0xFFE0B35D),
      onTap: () {},
    ),
    _TrackingModule(
      title: 'Ateş Takibi',
      description: 'Ateş ölçümlerini kaydet ve geçmişi görüntüle',
      icon: Icons.thermostat_rounded,
      color: const Color(0xFFE57373),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AtesTakipScreen()),
        );
      },
    ),
    _TrackingModule(
      title: 'Oyun ve Etkinlik',
      description: 'Yaşa uygun oyun ve etkinlik önerileri',
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFF708DAF),
      onTap: () {},
    ),
  ];
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5D4037).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF5D4037), size: 23),
        ),
      ),
    );
  }
}

class _HeaderPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF5D4037),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingSummaryStrip extends StatelessWidget {
  final int childCount;

  const _TrackingSummaryStrip({required this.childCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A342B).withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _TrackingSummaryItem(
            icon: Icons.child_care_rounded,
            value: '$childCount',
            label: 'Çocuk',
          ),
          const SizedBox(width: 10),
          const _TrackingSummaryItem(
            icon: Icons.grid_view_rounded,
            value: '8',
            label: 'Takip',
          ),
          const SizedBox(width: 10),
          const _TrackingSummaryItem(
            icon: Icons.favorite_rounded,
            value: 'Bugün',
            label: 'Aktif',
          ),
        ],
      ),
    );
  }
}

class _TrackingSummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _TrackingSummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037).withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFF5D4037), size: 18),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3F312C),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF948780),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
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

class _TrackingChildrenSection extends StatelessWidget {
  final List<Map<String, dynamic>> childDocs;
  final String? selectedChildId;

  const _TrackingChildrenSection({
    required this.childDocs,
    required this.selectedChildId,
  });

  @override
  Widget build(BuildContext context) {
    if (childDocs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'Çocuklar',
            style: TextStyle(
              color: Color(0xFF3F312C),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: childDocs.length + 1,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == childDocs.length) {
                return const _AddChildCircle();
              }

              final child = childDocs[index];
              final id = child['id'] as String?;
              final name = (child['name'] as String?) ?? '?';
              final isActive = id == selectedChildId;

              return _TrackingChildBubble(name: name, isActive: isActive);
            },
          ),
        ),
      ],
    );
  }
}

class _TrackingChildBubble extends StatelessWidget {
  final String name;
  final bool isActive;

  const _TrackingChildBubble({required this.name, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 74,
                height: 74,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.86),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF5D4037)
                        : Colors.white.withValues(alpha: 0.9),
                    width: isActive ? 2 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A342B).withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFF7EDEA),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF5D4037),
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (isActive)
                Positioned(
                  right: 6,
                  top: 2,
                  child: Tooltip(
                    message: '$name bilgilerini düzenle',
                    child: Material(
                      color: const Color(0xFF5D4037),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CocuklarimScreen(),
                            ),
                          );
                        },
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF3F312C),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddChildCircle extends StatelessWidget {
  const _AddChildCircle();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CocuklarimScreen()),
        );
      },
      borderRadius: BorderRadius.circular(52),
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.46),
                border: Border.all(
                  color: const Color(0xFF8D7D75).withValues(alpha: 0.45),
                  width: 1.4,
                ),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF5D4037),
                size: 26,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Çocuk Ekle',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF8D6E63),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _TrackingChildAvatar extends StatelessWidget {
  final String name;
  final bool isActive;

  const _TrackingChildAvatar({required this.name, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 138,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? const Color(0xFF5D4037).withValues(alpha: 0.36)
              : Colors.white.withValues(alpha: 0.78),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A342B).withValues(
              alpha: isActive ? 0.08 : 0.045,
            ),
            blurRadius: isActive ? 20 : 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF5D4037)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: isActive
                          ? const Color(0xFF5D4037).withValues(alpha: 0.12)
                          : const Color(0xFFF7F1EC),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Color(0xFF5D4037),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Tooltip(
                        message: '$name bilgilerini düzenle',
                        child: Material(
                          color: const Color(0xFF5D4037),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CocuklarimScreen(),
                                ),
                              );
                            },
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 22,
                              height: 22,
                              child: Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Icon(
                isActive ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isActive
                    ? const Color(0xFF5D4037)
                    : const Color(0xFFD7CCC4),
                size: 20,
              ),
            ],
          ),
          const Spacer(),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF3F312C),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF5D4037).withValues(alpha: 0.09)
                  : const Color(0xFFF7F1EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? 'Seçili çocuk' : 'Kaydır',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF5D4037)
                    : const Color(0xFFB6A9A2),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
              if (isActive)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Tooltip(
                    message: '$name bilgilerini düzenle',
                    child: Material(
                      color: const Color(0xFF5D4037),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CocuklarimScreen(),
                            ),
                          );
                        },
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4B403B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isActive ? 'Aktif' : 'Pasif',
            style: TextStyle(
              color:
                  isActive ? const Color(0xFF5D4037) : const Color(0xFFB6A9A2),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

*/
class _ProfileTab extends StatelessWidget {
  final String userName;
  final String userRole;

  const _ProfileTab({required this.userName, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF5D4037),
                child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 20),
            Text(userName,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037))),
            Text(userRole == 'parent' ? 'Ebeveyn HesabÄ±' : 'BakÄ±cÄ± HesabÄ±',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// --- YARDIMCI BÄ°LEÅENLER (WIDGETS) ---

class _TrackingGridCard extends StatelessWidget {
  final _TrackingModule module;

  const _TrackingGridCard({required this.module});

  @override
  Widget build(BuildContext context) {
    const radius = 20.0;
    const inkColor = Color(0xFF3F312C);
    const mutedColor = Color(0xFF8B7F78);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: module.onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFFFFAF5),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.82),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A342B).withValues(alpha: 0.075),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: module.color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(module.icon, color: module.color, size: 25),
                  ),
                  const Spacer(),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EEE9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.north_east_rounded,
                      color: module.color,
                      size: 15,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                module.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: inkColor,
                  fontSize: 15,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                module.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: mutedColor,
                  fontSize: 11,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 34,
                height: 3,
                decoration: BoxDecoration(
                  color: module.color.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeGroupSelector extends StatelessWidget {
  final String selectedGroup;
  final ValueChanged<String> onChanged;

  const _AgeGroupSelector(
      {required this.selectedGroup, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['0-2', '2-4', '4-6'].map((group) {
          final isSelected = selectedGroup == group;
          return GestureDetector(
            onTap: () => onChanged(group),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF5D4037) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFF5D4037).withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '$group YaÅŸ',
                style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF5D4037),
                    fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DailyTipCard extends StatelessWidget {
  final String ageGroup;
  const _DailyTipCard({required this.ageGroup});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Color(0xFF5D4037)),
              SizedBox(width: 10),
              Text('GÃ¼nÃ¼n Ä°pucu',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$ageGroup yaÅŸ grubu dÃ¶nemi iÃ§in Ã§ocuÄŸunuzun bol sÄ±vÄ± tÃ¼kettiÄŸinden ve uyku dÃ¼zeninin dengeli olduÄŸundan emin olun.',
            style: const TextStyle(
                fontSize: 14, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _TrackingFab extends StatelessWidget {
  const _TrackingFab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 76),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {},
            elevation: 10,
            backgroundColor: const Color(0xFF5D4037),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF765246),
                    Color(0xFF4E342E),
                  ],
                ),
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5D4037).withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text(
              'Yeni Kayıt',
              style: TextStyle(
                color: Color(0xFF5D4037),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5D4037).withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: onTap,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF5D4037),
              unselectedItemColor: const Color(0xFFB6A9A2),
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Ana Sayfa',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.child_care_rounded),
                  label: 'Takip',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
