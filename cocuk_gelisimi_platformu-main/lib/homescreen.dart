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
        'name': 'Minik Adımlar',
        'birthDate': DateTime.now().subtract(const Duration(days: 365)),
        'photoUrl': ''
      }
    ];
    final selectedChildId = 'test_child_123';

    return Scaffold(
      // Siyah ekranı önlemek için resmi kaldırıp yerine uygulamanın soft krem tonunu verdik
      backgroundColor: const Color(0xFFFDF7F2),
      body: IndexedStack(
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
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
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
                      'Hoşgeldin,\n$userName',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D4037), fontFamily: 'serif', fontStyle: FontStyle.italic),
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
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Text(
                        childData['name'] as String,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D4037), fontFamily: 'serif', fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '1 yaşında',
                        style: TextStyle(fontSize: 15, color: Colors.brown, fontWeight: FontWeight.w600, fontFamily: 'serif', fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _AgeGroupSelector(selectedGroup: selectedAgeGroup, onChanged: onAgeGroupChanged),
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
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Text(
                    'Bebek Takibi',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF5D4037), fontFamily: 'serif', fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildListDelegate([
                _TrackingGridCard(
                  title: 'Çocuklarım',
                  icon: Icons.child_care,
                  onTap: () {},
                ),
                _TrackingGridCard(
                  title: 'Ateş Takip',
                  icon: Icons.thermostat,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AtesTakipScreen()),
                    );
                  },
                ),
                _TrackingGridCard(
                  title: 'Aktivite Günlüğü',
                  icon: Icons.history,
                  onTap: () {},
                ),
                _TrackingGridCard(
                  title: 'Gelişim Günlüğü',
                  icon: Icons.auto_stories,
                  onTap: () {},
                ),
                _TrackingGridCard(
                  title: 'Aşı Takvimi',
                  icon: Icons.vaccines,
                  onTap: () {},
                ),
                _TrackingGridCard(
                  title: 'Büyüme Grafiği',
                  icon: Icons.show_chart,
                  onTap: () {},
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
            const CircleAvatar(radius: 50, backgroundColor: Color(0xFF5D4037), child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 20),
            Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
            Text(userRole == 'parent' ? 'Ebeveyn Hesabı' : 'Bakıcı Hesabı', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// --- YARDIMCI BİLEŞENLER (WIDGETS) ---

class _TrackingGridCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color = const Color(0xFF5D4037);

  const _TrackingGridCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF5D4037).withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color.withOpacity(0.8), fontFamily: 'serif', fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeGroupSelector extends StatelessWidget {
  final String selectedGroup;
  final ValueChanged<String> onChanged;

  const _AgeGroupSelector({required this.selectedGroup, required this.onChanged});

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
                border: Border.all(color: const Color(0xFF5D4037).withOpacity(0.2)),
              ),
              child: Text(
                '$group Yaş',
                style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF5D4037), corners: null, fontWeight: FontWeight.bold),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Color(0xFF5D4037)),
              SizedBox(width: 10),
              Text('Günün İpucu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$ageGroup yaş grubu dönemi için çocuğunuzun bol sıvı tükettiğinden ve uyku düzeninin dengeli olduğundan emin olun.',
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
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
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF5D4037),
        unselectedItemColor: Colors.brown.shade300,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.child_care_rounded), label: 'Takip'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}