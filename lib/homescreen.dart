import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'activity_log_screen.dart';
import 'aktivite_screen.dart';
import 'boy_kilo_screen.dart';
import 'caregiver_management_screen.dart';
import 'cocuklarim_screen.dart';
import 'edit_profile_screen.dart';
import 'ek_gida_screen.dart';
import 'gelisim_screen.dart';
import 'gunluk_screen.dart';
import 'help_support_screen.dart';
import 'notification_settings_screen.dart';
import 'providers/child_provider.dart';
import 'privacy_policy_screen.dart';
import 'utils/ates_takip_screen.dart';
import 'utils/daily_tips_data.dart';
import 'utils/image_upload.dart';
import 'vaccine_calendar.dart';

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
    final childProvider = context.watch<ChildProvider>();
    final currentUser = FirebaseAuth.instance.currentUser;
    final childDocs = childProvider.children.map(_childDocToMap).toList();
    final selectedChildId = childProvider.selectedChildId;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: currentUser == null
          ? null
          : FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() ?? {};
        final userName =
            (userData['name'] as String?)?.trim().isNotEmpty == true
            ? (userData['name'] as String).trim()
            : currentUser?.displayName ?? 'Ebeveyn';
        final userRole = (userData['role'] as String?) ?? 'parent';

        return Scaffold(
          backgroundColor: const Color(0xFFFDF7F2),
          extendBody: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset('assets/bg1.png', fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.white.withValues(alpha: 0.34)),
                ),
              ),
              IndexedStack(
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
                    currentChildId: selectedChildId,
                    userRole: userRole,
                  ),
                  _ProfileTab(userName: userName, userRole: userRole),
                ],
              ),
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
      },
    );
  }

  Map<String, dynamic> _childDocToMap(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final birthDate = data['birthDate'];
    return {
      'id': doc.id,
      'name': data['name'] ?? 'İsimsiz Çocuk',
      'birthDate': birthDate is Timestamp ? birthDate.toDate() : birthDate,
      'photoUrl': data['photoUrl'] ?? '',
      'gender': data['gender'],
    };
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
    if (childDocs.isEmpty) {
      return const _EmptyChildrenHomeTab();
    }

    final childData = childDocs.firstWhere(
      (child) => child['id'] == selectedChildId,
      orElse: () => childDocs.first,
    );
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
                  _AgeActivitySuggestions(
                    ageGroup: selectedAgeGroup,
                    childId: childData['id'] as String,
                    birthDate: childData['birthDate'] as DateTime,
                  ),
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
                      'Hoş geldin,\n$userName',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                      ),
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
                      BoxShadow(color: Colors.black12, blurRadius: 10),
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
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '1 yaşında',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.brown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _AgeGroupSelector(
                selectedGroup: selectedAgeGroup,
                onChanged: onAgeGroupChanged,
              ),
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

class _EmptyChildrenHomeTab extends StatelessWidget {
  const _EmptyChildrenHomeTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 120),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
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
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7EDEA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.child_care_rounded,
                      color: Color(0xFF5D4037),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Çocuk profili ekleyin',
                    style: TextStyle(
                      color: Color(0xFF3F312C),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Eklediğiniz çocuklar ana sayfa ve takip ekranında otomatik görünecek.',
                    style: TextStyle(
                      color: Color(0xFF6D5B52),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CocuklarimScreen(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5D4037),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Çocuk Ekle',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
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

class _AgeActivitySuggestions extends StatelessWidget {
  final String ageGroup;
  final String childId;
  final DateTime birthDate;

  const _AgeActivitySuggestions({
    required this.ageGroup,
    required this.childId,
    required this.birthDate,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestionsFor(ageGroup);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A342B).withValues(alpha: 0.06),
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
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF4F9E86),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yaşa Göre Aktivite',
                      style: TextStyle(
                        color: Color(0xFF3F312C),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Bugün için gelişimi destekleyen öneriler',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF8D7D75),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tüm aktiviteler',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AktiviteScreen(
                        childId: childId,
                        birthDate: birthDate,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.north_east_rounded,
                  color: Color(0xFF5D4037),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...suggestions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item.text,
                      style: const TextStyle(
                        color: Color(0xFF5F504A),
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_ActivitySuggestion> _suggestionsFor(String group) {
    switch (group) {
      case '2-4':
        return const [
          _ActivitySuggestion(
            'Renk eşleştirme oyunu ile dikkat ve dil gelişimini destekleyin.',
            Color(0xFF8D7AE6),
          ),
          _ActivitySuggestion(
            'Kısa hikaye tamamlama oyunu ile kelime hazinesini güçlendirin.',
            Color(0xFFE28A3A),
          ),
          _ActivitySuggestion(
            'Yumuşak engel parkuru kurarak denge ve koordinasyonu çalıştırın.',
            Color(0xFF4F9E86),
          ),
        ];
      case '4-6':
        return const [
          _ActivitySuggestion(
            'Sıralama ve gruplama oyunlarıyla problem çözmeyi destekleyin.',
            Color(0xFF8D7AE6),
          ),
          _ActivitySuggestion(
            'Birlikte hikaye üretip resmini çizerek yaratıcılığı artırın.',
            Color(0xFFE28A3A),
          ),
          _ActivitySuggestion(
            'Basit görev listesi hazırlayıp sorumluluk duygusunu pekiştirin.',
            Color(0xFF4F9E86),
          ),
        ];
      default:
        return const [
          _ActivitySuggestion(
            'Dokulu oyuncaklarla kısa keşif oyunları duyusal gelişimi destekler.',
            Color(0xFF8D7AE6),
          ),
          _ActivitySuggestion(
            'Ninni veya ritim eşliğinde el-ayak hareketleri koordinasyonu artırır.',
            Color(0xFFE28A3A),
          ),
          _ActivitySuggestion(
            'Yüz yüze konuşma ve taklit oyunları sosyal bağı güçlendirir.',
            Color(0xFF4F9E86),
          ),
        ];
    }
  }
}

class _ActivitySuggestion {
  final String text;
  final Color color;

  const _ActivitySuggestion(this.text, this.color);
}

class _BabyTrackingTab extends StatelessWidget {
  final List<Map<String, dynamic>> childDocs;
  final String? selectedChildId;
  final String? currentChildId;
  final String userRole;

  const _BabyTrackingTab({
    required this.childDocs,
    this.selectedChildId,
    this.currentChildId,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final childCount = childDocs.length;
    final activeChild = _selectedChildData;
    final activeChildId = (activeChild?['id'] as String?) ?? currentChildId;
    final activeChildName = (activeChild?['name'] as String?) ?? 'Minik';
    final activeBirthDate =
        _asDateTime(activeChild?['birthDate']) ??
        DateTime.now().subtract(const Duration(days: 365));
    final modules = _trackingModules(
      context,
      childId: activeChildId,
      childName: activeChildName,
      birthDate: activeBirthDate,
      userRole: userRole,
    );

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Miniklerin Gelişim Rehberi',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                            height: 1.05,
                            color: Color(0xFF3F312C),
                          ),
                        ),
                      ),
                      _TrackingNotificationButton(
                        onTap: () => _showTrackingAlerts(
                          context,
                          activeChildId: activeChildId,
                          activeChildName: activeChildName,
                          birthDate: activeBirthDate,
                          userRole: userRole,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Her adımında yanında olun; gelişim notları, aşı, beslenme ve etkinlikleri düzenli takip edin.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: Color(0xFF6D5B52),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _TrackingSummaryStrip(
                    childId: activeChildId,
                    childName: activeChildName,
                    birthDate: activeBirthDate,
                    userRole: userRole,
                  ),
                  const SizedBox(height: 20),
                  if (childCount < 0)
                    _HeaderPillButton(
                      icon: Icons.add_rounded,
                      label: 'Çocuk Ekle',
                      onTap: () {},
                    ),
                  const SizedBox(height: 0),
                  _TrackingChildrenSection(
                    childDocs: childDocs,
                    selectedChildId: selectedChildId ?? currentChildId,
                    userRole: userRole,
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

  Map<String, dynamic>? get _selectedChildData {
    if (childDocs.isEmpty) return null;
    final targetId = selectedChildId ?? currentChildId;
    for (final child in childDocs) {
      if (child['id'] == targetId) return child;
    }
    return childDocs.first;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
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

List<_TrackingModule> _trackingModules(
  BuildContext context, {
  required String? childId,
  required String childName,
  required DateTime birthDate,
  required String userRole,
}) {
  void openForChild(Widget Function(String id) builder) {
    if (childId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce bir çocuk ekleyin veya seçin.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => builder(childId)),
    );
  }

  return [
    if (userRole != 'bakici')
      _TrackingModule(
        title: 'Aktivite Günlüğü',
        description: 'Kaydedilen işlemleri ve değişiklikleri topluca gör',
        icon: Icons.history_rounded,
        color: const Color(0xFFE6A15E),
        onTap: () => openForChild((id) => ActivityLogScreen(childId: id)),
      ),
    if (userRole != 'bakici')
      _TrackingModule(
        title: 'Gelişim Günlüğü',
        description: 'Gelişim notlarını ekle ve ilerlemeyi izle',
        icon: Icons.auto_stories_rounded,
        color: const Color(0xFFE58AA4),
        onTap: () => openForChild((id) => GunlukScreen(childId: id)),
      ),
    _TrackingModule(
      title: 'Aşı Takvimi',
      description: 'Aşı takvimini görüntüle ve hatırlatmaları kaçırma',
      icon: Icons.vaccines_rounded,
      color: const Color(0xFF6F9FE8),
      onTap: () => openForChild(
        (id) => VaccineCalendarPage(
          childId: id,
          childName: childName,
          birthDate: birthDate,
        ),
      ),
    ),
    _TrackingModule(
      title: 'Büyüme Grafiği',
      description: 'Boy, kilo ve baş çevresi grafiklerini incele',
      icon: Icons.show_chart_rounded,
      color: const Color(0xFF7CBF8C),
      onTap: () => openForChild((id) => BoyKiloScreen(childId: id)),
    ),
    _TrackingModule(
      title: 'Gelişim Listesi',
      description: 'Gelişim basamaklarını takip et ve işaretle',
      icon: Icons.checklist_rounded,
      color: const Color(0xFFB984D8),
      onTap: () => openForChild(
        (id) => GelisimScreen(childId: id, birthDate: birthDate),
      ),
    ),
    _TrackingModule(
      title: 'Ek Gıda Rehberi',
      description: 'Ek gıda önerileri ve tariflere ulaş',
      icon: Icons.restaurant_menu_rounded,
      color: const Color(0xFFE0B35D),
      onTap: () =>
          openForChild((id) => EkGidaScreen(childId: id, birthDate: birthDate)),
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
      onTap: () => openForChild(
        (id) => AktiviteScreen(childId: id, birthDate: birthDate),
      ),
    ),
  ];
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

class _TrackingNotificationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TrackingNotificationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Bildirimler',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF5D4037),
                size: 22,
              ),
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC46A47),
                    shape: BoxShape.circle,
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

class _TrackingAlert {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String route;

  const _TrackingAlert({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

void _showTrackingAlerts(
  BuildContext context, {
  required String? activeChildId,
  required String activeChildName,
  required DateTime birthDate,
  required String userRole,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18 + MediaQuery.of(sheetContext).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFAF6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8CCC4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              '$activeChildName için bildirimler',
              style: const TextStyle(
                color: Color(0xFF3F312C),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Takipte eksik kalan alanlara buradan hızlıca geçebilirsiniz.',
              style: TextStyle(
                color: Color(0xFF8D7D75),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            if (activeChildId == null)
              const _TrackingAlertTile(
                alert: _TrackingAlert(
                  icon: Icons.child_care_rounded,
                  color: Color(0xFF8D7AE6),
                  title: 'Önce çocuk ekleyin',
                  subtitle:
                      'Takip uyarılarını görmek için çocuk profili oluşturun.',
                  route: 'children',
                ),
              )
            else
              FutureBuilder<List<_TrackingAlert>>(
                future: _loadTrackingAlerts(
                  activeChildId,
                  birthDate,
                  userRole: userRole,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    );
                  }

                  final alerts = snapshot.data ?? const <_TrackingAlert>[];
                  if (alerts.isEmpty) {
                    return const _TrackingAlertTile(
                      alert: _TrackingAlert(
                        icon: Icons.check_circle_rounded,
                        color: Color(0xFF5AA380),
                        title: 'Her şey yolunda',
                        subtitle:
                            'Bugünkü takip alanlarında acil bir eksik görünmüyor.',
                        route: 'none',
                      ),
                    );
                  }

                  return Column(
                    children: alerts
                        .map(
                          (alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TrackingAlertTile(
                              alert: alert,
                              childId: activeChildId,
                              childName: activeChildName,
                              birthDate: birthDate,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}

Future<List<_TrackingAlert>> _loadTrackingAlerts(
  String childId,
  DateTime birthDate, {
  required String userRole,
}) async {
  final alerts = <_TrackingAlert>[];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final firestore = FirebaseFirestore.instance;

  final vaccineSnapshot = await firestore
      .collection('vaccines_records')
      .where('childId', isEqualTo: childId)
      .orderBy('month')
      .get();
  QueryDocumentSnapshot? nearestVaccine;
  DateTime? nearestDate;
  for (final doc in vaccineSnapshot.docs) {
    final data = doc.data();
    if (data['done'] == true) continue;
    final month = (data['month'] as num?)?.toInt() ?? 0;
    final date = DateTime(
      birthDate.year,
      birthDate.month + month,
      birthDate.day,
    );
    if (nearestDate == null ||
        date.difference(today).inDays.abs() <
            nearestDate.difference(today).inDays.abs()) {
      nearestDate = date;
      nearestVaccine = doc;
    }
  }
  if (nearestVaccine != null && nearestDate != null) {
    final data = nearestVaccine.data() as Map<String, dynamic>;
    final days = nearestDate.difference(today).inDays;
    alerts.add(
      _TrackingAlert(
        icon: Icons.vaccines_rounded,
        color: const Color(0xFF8D7AE6),
        title: days < 0 ? 'Aşı takibi gecikmiş' : 'Aşınız yaklaşıyor',
        subtitle:
            '${data['name'] ?? 'Aşı'} ${days < 0 ? '${days.abs()} gün önceydi' : _formatShortDate(nearestDate)}. Takvimi kontrol edin.',
        route: 'vaccine',
      ),
    );
  }

  final growthSnapshot = await firestore
      .collection('growth_records')
      .where('childId', isEqualTo: childId)
      .orderBy('date', descending: true)
      .limit(1)
      .get();
  final growthDate = growthSnapshot.docs.isEmpty
      ? null
      : _trackingDateFromValue(growthSnapshot.docs.first.data()['date']);
  if (growthDate == null) {
    alerts.add(
      const _TrackingAlert(
        icon: Icons.show_chart_rounded,
        color: Color(0xFF6F9FE8),
        title: 'Ölçüm girin',
        subtitle: 'Büyüme grafiği için henüz boy-kilo ölçümü eklenmemiş.',
        route: 'growth',
      ),
    );
  } else if (today
          .difference(
            DateTime(growthDate.year, growthDate.month, growthDate.day),
          )
          .inDays >=
      30) {
    alerts.add(
      _TrackingAlert(
        icon: Icons.show_chart_rounded,
        color: const Color(0xFF6F9FE8),
        title: 'Yeni ölçüm zamanı',
        subtitle:
            'Son ölçüm ${_relativeAddedText(growthDate, suffix: '')}. Grafiği güncelleyin.',
        route: 'growth',
      ),
    );
  }

  if (userRole != 'bakici') {
    final journalSnapshot = await firestore
        .collection('journal')
        .where('childId', isEqualTo: childId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    final journalDate = journalSnapshot.docs.isEmpty
        ? null
        : _trackingDateFromValue(journalSnapshot.docs.first.data()['date']);
    if (journalDate == null) {
      alerts.add(
        const _TrackingAlert(
          icon: Icons.edit_note_rounded,
          color: Color(0xFFE28A3A),
          title: 'Günlük notu ekleyin',
          subtitle: 'Bugüne ait gelişim veya aktivite notu henüz yok.',
          route: 'journal',
        ),
      );
    } else if (today
            .difference(
              DateTime(journalDate.year, journalDate.month, journalDate.day),
            )
            .inDays >=
        3) {
      alerts.add(
        _TrackingAlert(
          icon: Icons.edit_note_rounded,
          color: const Color(0xFFE28A3A),
          title: 'Günlük uzun süredir boş',
          subtitle:
              'Son not ${_relativeAddedText(journalDate)}. Yeni bir not ekleyin.',
          route: 'journal',
        ),
      );
    }
  }

  return alerts.take(4).toList();
}

DateTime? _trackingDateFromValue(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  return null;
}

class _TrackingAlertTile extends StatelessWidget {
  final _TrackingAlert alert;
  final String? childId;
  final String? childName;
  final DateTime? birthDate;

  const _TrackingAlertTile({
    required this.alert,
    this.childId,
    this.childName,
    this.birthDate,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: alert.route == 'none'
            ? null
            : () {
                Navigator.pop(context);
                _openTrackingAlertRoute(context);
              },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: alert.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(alert.icon, color: alert.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF3F312C),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8D7D75),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (alert.route != 'none')
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8D7D75),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTrackingAlertRoute(BuildContext context) {
    final id = childId;
    switch (alert.route) {
      case 'vaccine':
        if (id == null || childName == null || birthDate == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VaccineCalendarPage(
              childId: id,
              childName: childName!,
              birthDate: birthDate!,
            ),
          ),
        );
        break;
      case 'growth':
        if (id == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BoyKiloScreen(childId: id)),
        );
        break;
      case 'journal':
        if (id == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GunlukScreen(childId: id)),
        );
        break;
      case 'children':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CocuklarimScreen()),
        );
        break;
    }
  }
}

class _TrackingSummaryStrip extends StatelessWidget {
  final String? childId;
  final String childName;
  final DateTime birthDate;
  final String userRole;

  const _TrackingSummaryStrip({
    required this.childId,
    required this.childName,
    required this.birthDate,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    if (childId == null) {
      return Row(
        children: [
          const Expanded(
            child: _TrackingSummaryCard(
              icon: Icons.vaccines_rounded,
              title: 'Yaklaşan Aşı',
              value: 'Çocuk seç',
              color: Color(0xFF8D7AE6),
              tint: Color(0xFFF2EEFF),
            ),
          ),
          const SizedBox(width: 7),
          const Expanded(
            child: _TrackingSummaryCard(
              icon: Icons.monitor_heart_outlined,
              title: 'Son Ölçüm',
              value: 'Çocuk seç',
              color: Color(0xFF4F9E86),
              tint: Color(0xFFEAF7F2),
            ),
          ),
          if (userRole != 'bakici') ...[
            const SizedBox(width: 7),
            const Expanded(
              child: _TrackingSummaryCard(
                icon: Icons.edit_note_rounded,
                title: 'Son Not',
                value: 'Çocuk seç',
                color: Color(0xFFE28A3A),
                tint: Color(0xFFFFF0E3),
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _UpcomingVaccineCard(
            childId: childId!,
            childName: childName,
            birthDate: birthDate,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(child: _LatestGrowthCard(childId: childId!)),
        if (userRole != 'bakici') ...[
          const SizedBox(width: 7),
          Expanded(child: _LatestJournalCard(childId: childId!)),
        ],
      ],
    );
  }
}

class _TrackingSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color tint;
  final VoidCallback? onTap;

  const _TrackingSummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          height: 88,
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A342B).withValues(alpha: 0.055),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF3F312C),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10.2,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingVaccineCard extends StatelessWidget {
  final String childId;
  final String childName;
  final DateTime birthDate;

  const _UpcomingVaccineCard({
    required this.childId,
    required this.childName,
    required this.birthDate,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vaccines_records')
          .where('childId', isEqualTo: childId)
          .orderBy('month')
          .snapshots(),
      builder: (context, snapshot) {
        var value = _DailyStatusText.pick('Aşı planı hazır', [
          'Takvimi kontrol et',
          'Bugün aşıya bak',
          'Aşı planını aç',
        ]);

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          value = _upcomingVaccineText(snapshot.data!.docs, birthDate);
        } else if (snapshot.hasData) {
          value = _DailyStatusText.pick('Takvimi oluştur', [
            'Plan eklemek için aç',
            'Aşıları başlat',
            'İlk takvimi kur',
          ]);
        }

        return _TrackingSummaryCard(
          icon: Icons.vaccines_rounded,
          title: 'Yaklaşan Aşı',
          value: value,
          color: const Color(0xFF8D7AE6),
          tint: const Color(0xFFF2EEFF),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VaccineCalendarPage(
                  childId: childId,
                  childName: childName,
                  birthDate: birthDate,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _upcomingVaccineText(
    List<QueryDocumentSnapshot> docs,
    DateTime birthDate,
  ) {
    final now = DateTime.now();
    QueryDocumentSnapshot? fallback;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['done'] == true) continue;
      final month = (data['month'] as num?)?.toInt() ?? 0;
      final date = DateTime(
        birthDate.year,
        birthDate.month + month,
        birthDate.day,
      );
      if (!date.isBefore(DateTime(now.year, now.month, now.day))) {
        return _formatShortDate(date);
      }
      fallback ??= doc;
    }

    if (fallback != null) {
      final data = fallback.data() as Map<String, dynamic>;
      final month = (data['month'] as num?)?.toInt() ?? 0;
      return '${_formatShortDate(DateTime(birthDate.year, birthDate.month + month, birthDate.day))} geçmiş';
    }

    return 'Aşılar tamam';
  }
}

class _LatestGrowthCard extends StatelessWidget {
  final String childId;

  const _LatestGrowthCard({required this.childId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('growth_records')
          .where('childId', isEqualTo: childId)
          .orderBy('date', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        var value = _DailyStatusText.pick('Ölçüm bekleniyor', [
          'Bugün ölçüm ekle',
          'Grafiği güncelle',
          'İlk ölçümü gir',
        ]);

        if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
          value = 'Henüz girilmedi';
        } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final date = (data['date'] as Timestamp?)?.toDate();
          value = date == null
              ? 'Yeni ölçüm var'
              : _relativeAddedText(date, suffix: '');
        }

        return _TrackingSummaryCard(
          icon: Icons.monitor_heart_outlined,
          title: 'Son Ölçüm',
          value: value,
          color: const Color(0xFF4F9E86),
          tint: const Color(0xFFEAF7F2),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BoyKiloScreen(childId: childId),
              ),
            );
          },
        );
      },
    );
  }
}

class _LatestJournalCard extends StatelessWidget {
  final String childId;

  const _LatestJournalCard({required this.childId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('journal')
          .where('childId', isEqualTo: childId)
          .orderBy('date', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        var value = _DailyStatusText.pick('Not bekleniyor', [
          'Bugün not ekle',
          'Anı yazmaya hazır',
          'İlk notu oluştur',
        ]);

        if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
          value = _DailyStatusText.pick('Henüz not yok', [
            'Bugün not ekle',
            'İlk anıyı yaz',
            'Günlüğü başlat',
          ]);
        } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final date = (data['date'] as Timestamp?)?.toDate();
          value = date == null ? 'Yeni eklendi' : _relativeAddedText(date);
        }

        return _TrackingSummaryCard(
          icon: Icons.edit_note_rounded,
          title: 'Son Not',
          value: value,
          color: const Color(0xFFE28A3A),
          tint: const Color(0xFFFFF0E3),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GunlukScreen(childId: childId),
              ),
            );
          },
        );
      },
    );
  }
}

class _DailyStatusText {
  static String pick(String fallback, List<String> values) {
    if (values.isEmpty) return fallback;
    final now = DateTime.now();
    final index = (now.year * 366 + now.month * 31 + now.day) % values.length;
    return values[index];
  }
}

String _relativeAddedText(DateTime date, {String suffix = ' eklendi'}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final days = today.difference(target).inDays;

  if (days <= 0) return 'Bugün$suffix';
  if (days == 1) return 'Dün$suffix';
  if (days < 7) return '$days gün önce$suffix';
  return _formatShortDate(date);
}

String _formatShortDate(DateTime date) {
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

class _TrackingChildrenSection extends StatelessWidget {
  final List<Map<String, dynamic>> childDocs;
  final String? selectedChildId;
  final String userRole;

  const _TrackingChildrenSection({
    required this.childDocs,
    required this.selectedChildId,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    if (childDocs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Çocuklarım',
                  style: TextStyle(
                    color: Color(0xFF3F312C),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (userRole != 'bakici')
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CocuklarimScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'Tümünü Gör',
                          style: TextStyle(
                            color: Color(0xFF5D4037),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF5D4037),
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 92,
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
              final birthDate = child['birthDate'];
              final photoUrl = child['photoUrl'] as String?;
              final isActive = id == selectedChildId;

              return _TrackingChildBubble(
                childId: id,
                name: name,
                ageText: _formatChildAge(birthDate),
                photoUrl: photoUrl,
                isActive: isActive,
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatChildAge(dynamic birthDate) {
    if (birthDate is! DateTime) return '';

    final now = DateTime.now();
    final days = now.difference(birthDate).inDays;
    if (days < 30) return '$days günlük';
    if (days < 365) {
      final months = (days / 30).floor();
      final extraDays = days - (months * 30);
      return extraDays > 0 ? '$months ay $extraDays gün' : '$months aylık';
    }

    final years = (days / 365).floor();
    final months = ((days - (years * 365)) / 30).floor();
    return months > 0 ? '$years yaş $months ay' : '$years yaşında';
  }
}

class _TrackingChildBubble extends StatelessWidget {
  final String? childId;
  final String name;
  final String ageText;
  final String? photoUrl;
  final bool isActive;

  const _TrackingChildBubble({
    required this.childId,
    required this.name,
    required this.ageText,
    required this.photoUrl,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return InkWell(
      onTap: childId == null
          ? null
          : () => context.read<ChildProvider>().setSelectedChild(childId!),
      borderRadius: BorderRadius.circular(36),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.9),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF5D4037)
                          : const Color(0xFFE5DAD4),
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A342B).withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFF7EDEA),
                    backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                    child: hasPhoto
                        ? null
                        : Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Color(0xFF5D4037),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                if (isActive)
                  Positioned(
                    right: 0,
                    top: -1,
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
                            width: 20,
                            height: 20,
                            child: Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 11,
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
                color: Color(0xFF3F312C),
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ageText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6D5B52),
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
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
        width: 64,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
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
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Çocuk Ekle',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF8D6E63),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                height: 1,
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
            color: const Color(
              0xFF4A342B,
            ).withValues(alpha: isActive ? 0.08 : 0.045),
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
    final childCount = context.watch<ChildProvider>().children.length;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFFFFF), Color(0xFFFFF5EE)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.88),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _ProfileAvatar(),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _ProfileUserName(fallbackName: userName),
                                  const SizedBox(height: 6),
                                  Text(
                                    userRole == 'parent'
                                        ? 'Ebeveyn Hesabı'
                                        : 'Bakıcı Hesabı',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF8D7D75),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _PremiumProfileStat(
                                value: '$childCount',
                                label: 'Çocuk',
                              ),
                            ),
                            const SizedBox(width: 9),
                            const Expanded(
                              child: _PremiumProfileStat(
                                value: 'Günlük',
                                label: 'Anılar',
                              ),
                            ),
                            const SizedBox(width: 9),
                            const Expanded(
                              child: _PremiumProfileStat(
                                value: 'Aile',
                                label: 'Profil',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  userRole == 'bakici'
                      ? const _LockedFamilyPhotosCard()
                      : const _FamilyPhotosCard(),
                  const SizedBox(height: 18),
                  const Text(
                    'Hesap',
                    style: TextStyle(
                      color: Color(0xFF3F312C),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (userRole != 'bakici')
                    _ProfileActionTile(
                      icon: Icons.edit_rounded,
                      title: 'Profili Düzenle',
                      subtitle: 'Kişisel bilgiler ve hesap ayarları',
                      color: const Color(0xFF8D7AE6),
                      onTap: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        final userDoc = user == null
                            ? null
                            : await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .get();
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              userData:
                                  userDoc?.data() ??
                                  {'name': userName, 'role': userRole},
                            ),
                          ),
                        );
                      },
                    ),
                  if (userRole != 'bakici')
                    _ProfileActionTile(
                      icon: Icons.child_care_rounded,
                      title: 'Çocuklarım',
                      subtitle: 'Çocuk profillerini ekle ve düzenle',
                      color: const Color(0xFFE58AA4),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CocuklarimScreen(),
                          ),
                        );
                      },
                    ),
                  if (userRole != 'bakici')
                    _ProfileActionTile(
                      icon: Icons.group_rounded,
                      title: 'Bakıcı Yönetimi',
                      subtitle: 'Bakıcı davetleri ve erişim izinleri',
                      color: const Color(0xFF4F9E86),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CaregiverManagementScreen(),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Destek',
                    style: TextStyle(
                      color: Color(0xFF3F312C),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ProfileActionTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'Bildirim Ayarları',
                    subtitle: 'Aşı, gelişim ve günlük hatırlatmalar',
                    color: const Color(0xFFE28A3A),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _ProfileActionTile(
                    icon: Icons.help_rounded,
                    title: 'Yardım ve Destek',
                    subtitle: 'Sık sorulan sorular ve iletişim',
                    color: const Color(0xFF6F9FE8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  _ProfileActionTile(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Gizlilik ve Güvenlik',
                    subtitle: 'Veri gizliliği ve kullanım bilgileri',
                    color: const Color(0xFF8B7F78),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileUserName extends StatelessWidget {
  final String fallbackName;

  const _ProfileUserName({required this.fallbackName});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _nameText(fallbackName);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = (data?['name'] as String?)?.trim();
        return _nameText(name == null || name.isEmpty ? fallbackName : name);
      },
    );
  }

  Widget _nameText(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 22,
        height: 1.05,
        fontWeight: FontWeight.w900,
        color: Color(0xFF3F312C),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _avatarShell(null);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final photoUrl = (data?['profilePhotoUrl'] as String?)?.trim();
        return _avatarShell(
          photoUrl == null || photoUrl.isEmpty ? null : photoUrl,
        );
      },
    );
  }

  Widget _avatarShell(String? photoUrl) {
    return Container(
      width: 66,
      height: 66,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: Color(0xFF5D4037),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: photoUrl == null
            ? Container(
                color: const Color(0xFF5D4037),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              )
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF5D4037),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }
}

class _FamilyPhotosCard extends StatelessWidget {
  const _FamilyPhotosCard();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Aile Fotoğrafları',
                  style: TextStyle(
                    color: Color(0xFF3F312C),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fotoğraf ekle',
                onPressed: user == null
                    ? null
                    : () async {
                        final url = await ImageUploadUtils.pickAndUploadImage();
                        if (url == null) return;
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .set({
                              'familyPhotos': FieldValue.arrayUnion([url]),
                            }, SetOptions(merge: true));
                      },
                icon: const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<DocumentSnapshot>(
            stream: user == null
                ? null
                : FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final photos =
                  (data?['familyPhotos'] as List?)
                      ?.whereType<String>()
                      .toList() ??
                  [];

              if (photos.isEmpty) {
                return const Text(
                  'Aile fotoğraflarınızı buraya ekleyebilirsiniz.',
                  style: TextStyle(
                    color: Color(0xFF8D7D75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }

              return SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        photos[index],
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LockedFamilyPhotosCard extends StatelessWidget {
  const _LockedFamilyPhotosCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Color(0xFF5D4037),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aile Fotoğrafları',
                  style: TextStyle(
                    color: Color(0xFF3F312C),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bu alan yalnızca ebeveyn hesabına açıktır.',
                  style: TextStyle(
                    color: Color(0xFF8D7D75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _PremiumProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _PremiumProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EFE9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF3F312C),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8D7D75),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A342B).withValues(alpha: 0.045),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF3F312C),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8D7D75),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB6A9A2),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- YARDIMCI BİLEŞENLER (WIDGETS) ---

class _TrackingGridCard extends StatelessWidget {
  final _TrackingModule module;

  const _TrackingGridCard({required this.module});

  @override
  Widget build(BuildContext context) {
    const radius = 20.0;
    const inkColor = Color(0xFF3F312C);
    const mutedColor = Color(0xFF8B7F78);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: module.onTap,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFFFFAF5)],
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

  const _AgeGroupSelector({
    required this.selectedGroup,
    required this.onChanged,
  });

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
                '$group Yaş',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF5D4037),
                  fontWeight: FontWeight.bold,
                ),
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
    final tip = DailyTipsData.getTipOfDay(ageGroup);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFF4EC)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A342B).withValues(alpha: 0.08),
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
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7D6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFE28A3A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bugün böyle yapabilirsiniz',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8D7D75),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tip.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3F312C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            tip.content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5D514B),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF7ECE4),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$ageGroup yaş grubuna göre günlük öneri',
              style: const TextStyle(
                color: Color(0xFF6D5B52),
                fontSize: 11,
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
