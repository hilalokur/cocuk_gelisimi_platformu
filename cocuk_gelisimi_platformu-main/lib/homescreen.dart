import 'dart:ui';
import 'package:flutter/material.dart';
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
                              'Bebek Takibi',
                              style: TextStyle(
                                fontSize: 32,
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
                                color: Color(0xFF8D7D75),
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
                  const SizedBox(height: 18),
                  _HeaderPillButton(
                    icon: Icons.add_rounded,
                    label: 'Ã‡ocuk Ekle',
                    onTap: () {},
                  ),
                  const SizedBox(height: 22),
                  _TrackingChildrenSection(
                    childDocs: childDocs,
                    selectedChildId: selectedChildId ?? currentChildId,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 150),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 230,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.86,
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
      title: 'Çocuklarım',
      description: 'Çocuğunu yönet ve bilgilerini görüntüle',
      icon: Icons.child_care_rounded,
      color: const Color(0xFF8E7CC3),
      onTap: () {},
    ),
    _TrackingModule(
      title: 'Bakıcı Yönetimi',
      description: 'Bakıcılarını ekle, düzenle ve takip et',
      icon: Icons.people_alt_rounded,
      color: const Color(0xFF5BA7A7),
      onTap: () {},
    ),
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
      title: 'Uyku Takibi',
      description: 'Uyku düzenini kaydet ve analiz et',
      icon: Icons.bedtime_rounded,
      color: const Color(0xFF6C7FD8),
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

    return SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: childDocs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final child = childDocs[index];
          final id = child['id'] as String?;
          final name = (child['name'] as String?) ?? '?';
          final isActive = id == selectedChildId;

          return _TrackingChildAvatar(name: name, isActive: isActive);
        },
      ),
    );
  }
}

class _TrackingChildAvatar extends StatelessWidget {
  final String name;
  final bool isActive;

  const _TrackingChildAvatar({required this.name, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? const Color(0xFF5D4037) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: isActive
                  ? const Color(0xFF5D4037).withValues(alpha: 0.12)
                  : Colors.white,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFF5D4037),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
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
    const radius = 22.0;

    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: module.onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5D4037).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: module.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(module.icon, color: module.color, size: 26),
              ),
              const Spacer(),
              Text(
                module.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF3F312C),
                  fontSize: 15,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                module.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF948780),
                  fontSize: 11,
                  height: 1.22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F1EC),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF5D4037),
                    size: 18,
                  ),
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
      padding: const EdgeInsets.only(bottom: 88),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {},
            elevation: 8,
            backgroundColor: const Color(0xFF5D4037),
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
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
