import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'providers/child_provider.dart';
import 'utils/daily_tips_data.dart';
import 'utils/image_upload.dart';
import 'utils/ates_takip_screen.dart';
import 'gunluk_screen.dart';
import 'boy_kilo_screen.dart';
import 'vaccine_calendar.dart';
import 'gelisim_screen.dart';
import 'cocuklarim_screen.dart';
import 'ek_gida_screen.dart';
import 'aktivite_screen.dart';
import 'activity_log_screen.dart';

import 'caregiver_management_screen.dart';
import 'edit_profile_screen.dart';

import 'notification_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_support_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedAgeGroup = '0-2';
  bool ageGroupManuallySelected = false;

  final Set<String> _uploadingIds = {};
  final Map<String, String> _tempUrls = {};

  Stream<DocumentSnapshot>? _userStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
      WebDataService().syncMinistryData();
    }
  }

  Future<void> _pickAndUploadPhoto(
    String collection,
    String docId,
    String fieldName,
  ) async {
    try {
      final url = await ImageUploadUtils.pickAndUploadImage();

      if (url == null) {
        return;
      }

      setState(() => _uploadingIds.add(docId));

      await FirebaseFirestore.instance.collection(collection).doc(docId).update(
        {fieldName: url},
      );

      setState(() {
        _tempUrls[docId] = url;
        _uploadingIds.remove(docId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto\u011fraf ba\u015far\u0131yla g\u00fcncellendi'),
          ),
        );
      }
    } catch (e) {
      setState(() => _uploadingIds.remove(docId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Foto\u011fraf g\u00fcncellenirken hata olu\u015ftu: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Hata: ${userSnapshot.error}')),
          );
        }

        if (userSnapshot.connectionState == ConnectionState.waiting &&
            !userSnapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF5D4037)),
            ),
          );
        }

        final userData =
            userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final userName = userData['name'] ?? 'Kullan\u0131c\u0131';
        final userRole = userData['role'] ?? 'parent';
        final profilePhotoUrl = userData['profilePhotoUrl'];
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        return Consumer<ChildProvider>(
          builder: (context, childProvider, child) {
            final childDocs = childProvider.children;
            final selectedChildId = childProvider.selectedChildId;

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset('assets/bg1.png', fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _HomeTab(
                        userName: userName,
                        profilePhotoUrl:
                            _tempUrls[currentUserId] ?? profilePhotoUrl,
                        childDocs: childDocs,
                        selectedChildId: selectedChildId,
                        selectedAgeGroup: _selectedAgeGroup,
                        ageGroupManuallySelected: ageGroupManuallySelected,
                        onAgeGroupChanged: (group, manual) {
                          setState(() {
                            _selectedAgeGroup = group;
                            ageGroupManuallySelected = manual;
                          });
                        },
                        onChildSelect: (childId) {
                          childProvider.setSelectedChild(childId);
                          setState(() {
                            ageGroupManuallySelected = false;
                          });
                        },
                        onChildPhotoTap: (childId) => _pickAndUploadPhoto(
                          'children',
                          childId,
                          'photoUrl',
                        ),
                        onParentPhotoTap: () => _pickAndUploadPhoto(
                          'users',
                          currentUserId!,
                          'profilePhotoUrl',
                        ),
                        uploadingIds: _uploadingIds,
                        tempUrls: _tempUrls,
                      ),
                      _BabyTrackingTab(
                        childDocs: childDocs,
                        selectedChildId: selectedChildId,
                        onChildSelect: (childId) {
                          childProvider.setSelectedChild(childId);
                          setState(() {
                            ageGroupManuallySelected = false;
                          });
                        },
                        onChildPhotoTap: (childId) => _pickAndUploadPhoto(
                          'children',
                          childId,
                          'photoUrl',
                        ),
                        uploadingIds: _uploadingIds,
                        tempUrls: _tempUrls,
                      ),
                      _ProfileTab(
                        userData: userData,
                        displayPhotoUrl:
                            _tempUrls[currentUserId] ?? profilePhotoUrl,
                        onPhotoTap: () => _pickAndUploadPhoto(
                          'users',
                          currentUserId!,
                          'profilePhotoUrl',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              bottomNavigationBar: _BottomNavBar(
                selectedIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
              ),
              floatingActionButton: _selectedIndex == 1 && userRole != 'bakici'
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 76),
                      child: FloatingActionButton(
                        onPressed: () => _showAddChildDialog(context),
                        elevation: 10,
                        backgroundColor: const Color(0xFF5D4037),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF765246), Color(0xFF4E342E)],
                            ),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  void _showAddChildDialog(BuildContext context) {
    final nameController = TextEditingController();
    DateTime? selectedDate;
    String? selectedGender;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Yeni \u00c7ocuk Ekle',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(),
                decoration: const InputDecoration(
                  labelText: '\u00c7ocu\u011fun Ad\u0131',
                  labelStyle: TextStyle(),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Cinsiyet',
                  labelStyle: TextStyle(),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc, color: Color(0xFF5D4037)),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'K\u0131z',
                    child: Text('K\u0131z', style: TextStyle()),
                  ),
                  DropdownMenuItem(
                    value: 'Erkek',
                    child: Text('Erkek', style: TextStyle()),
                  ),
                ],
                onChanged: (val) => setDialogState(() => selectedGender = val),
              ),
              const SizedBox(height: 15),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  selectedDate == null
                      ? 'Do\u011fum Tarihi Se\u00e7'
                      : DateFormat('dd.MM.yyyy').format(selectedDate!),
                  style: const TextStyle(),
                ),
                leading: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF5D4037),
                ),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF5D4037),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) setDialogState(() => selectedDate = date);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('\u0130ptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    selectedDate != null &&
                    selectedGender != null) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('children')
                        .add({
                          'name': nameController.text,
                          'birthDate': Timestamp.fromDate(selectedDate!),
                          'gender': selectedGender,
                          'parentId': user.uid,
                          'photoUrl': '',
                        });
                    if (context.mounted) Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D4037),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Kaydet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TABS ---

class _HomeTab extends StatelessWidget {
  final String userName;
  final String? profilePhotoUrl;
  final List<DocumentSnapshot> childDocs;
  final String? selectedChildId;
  final String selectedAgeGroup;
  final bool ageGroupManuallySelected;
  final Function(String, bool) onAgeGroupChanged;
  final Function(String) onChildSelect;
  final Function(String) onChildPhotoTap;
  final VoidCallback onParentPhotoTap;
  final Set<String> uploadingIds;
  final Map<String, String> tempUrls;

  const _HomeTab({
    required this.userName,
    this.profilePhotoUrl,
    required this.childDocs,
    this.selectedChildId,
    required this.selectedAgeGroup,
    required this.ageGroupManuallySelected,
    required this.onAgeGroupChanged,
    required this.onChildSelect,
    required this.onChildPhotoTap,
    required this.onParentPhotoTap,
    required this.uploadingIds,
    required this.tempUrls,
  });

  @override
  Widget build(BuildContext context) {
    final selectedChildDoc = childDocs.isNotEmpty
        ? (childDocs.any((doc) => doc.id == selectedChildId)
              ? childDocs.firstWhere((doc) => doc.id == selectedChildId)
              : childDocs.first)
        : null;

    final currentChildId = selectedChildDoc?.id;
    final childData = selectedChildDoc?.data() as Map<String, dynamic>?;
    final childBDay = (childData?['birthDate'] as Timestamp?)?.toDate();

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isParentUploading =
        currentUserId != null && uploadingIds.contains(currentUserId);

    if (childBDay != null && !ageGroupManuallySelected) {
      final ageInDays = DateTime.now().difference(childBDay).inDays;
      final ageInYears = ageInDays / 365;
      String newGroup = '0-2';
      if (ageInYears >= 2 && ageInYears < 4) newGroup = '2-4';
      if (ageInYears >= 4) newGroup = '4-6';

      if (selectedAgeGroup != newGroup) {
        Future.microtask(() => onAgeGroupChanged(newGroup, false));
      }
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              // \u00c7ocuk Se\u00e7ici (En \u00dcstte)
              if (childDocs.isNotEmpty)
                _ChildrenList(
                  childDocs: childDocs,
                  selectedChildId: selectedChildId,
                  onChildSelect: onChildSelect,
                  onPhotoTap: onChildPhotoTap,
                  uploadingIds: uploadingIds,
                  tempUrls: tempUrls,
                ),
              // Ho\u015fgeldin ve Profil B\u00f6l\u00fcm\u00fc
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ho\u015fgeldin,',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                    GestureDetector(
                      onTap: onParentPhotoTap,
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.5,
                                  ),
                                  backgroundImage:
                                      (profilePhotoUrl != null &&
                                          profilePhotoUrl!.startsWith('http'))
                                      ? CachedNetworkImageProvider(
                                          profilePhotoUrl!,
                                        )
                                      : null,
                                  child:
                                      (profilePhotoUrl == null ||
                                          !profilePhotoUrl!.startsWith('http'))
                                      ? const Icon(
                                          Icons.person_add_alt_1,
                                          color: Color(0xFF5D4037),
                                          size: 30,
                                        )
                                      : null,
                                ),
                              ),
                              if (isParentUploading)
                                const SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Color(0xFF5D4037),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5D4037),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (childDocs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          childData?['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                        if (childBDay != null)
                          Text(
                            _calculateAge(childBDay),
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.brown.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              _AgeGroupSelector(
                selectedGroup: selectedAgeGroup,
                onChanged: (val) => onAgeGroupChanged(val, true),
              ),
              const SizedBox(height: 25),
              _DailyTipCard(ageGroup: selectedAgeGroup),
              const SizedBox(height: 20),
              if (currentChildId != null && childBDay != null)
                _DynamicUpcomingVaccineCard(
                  childId: currentChildId,
                  birthDate: childBDay,
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final days = difference.inDays;

    if (days < 7) return '$days g\u00fcnl\u00fck';
    if (days < 30) return '${(days / 7).floor()} haftal\u0131k';
    if (days < 365) return '${(days / 30).floor()} ayl\u0131k';
    final years = (days / 365).floor();
    final remainingMonths = ((days % 365) / 30).floor();
    return remainingMonths > 0
        ? '$years ya\u015f, $remainingMonths ayl\u0131k'
        : '$years ya\u015f\u0131nda';
  }
}

class _BabyTrackingTab extends StatelessWidget {
  final List<DocumentSnapshot> childDocs;
  final String? selectedChildId;
  final Function(String) onChildSelect;
  final Function(String) onChildPhotoTap;
  final Set<String> uploadingIds;
  final Map<String, String> tempUrls;

  const _BabyTrackingTab({
    required this.childDocs,
    this.selectedChildId,
    required this.onChildSelect,
    required this.onChildPhotoTap,
    required this.uploadingIds,
    required this.tempUrls,
  });

  @override
  Widget build(BuildContext context) {
    final selectedChildDoc = childDocs.isNotEmpty
        ? (childDocs.any((doc) => doc.id == selectedChildId)
              ? childDocs.firstWhere((doc) => doc.id == selectedChildId)
              : childDocs.first)
        : null;

    final currentChildId = selectedChildDoc?.id;
    final childCount = childDocs.length;

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
                    'Miniklerin Gelişim Rehberi',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(25, 8, 25, 0),
                  child: Text(
                    'Her adımında yanında olun; gelişim notları, aşı, beslenme ve etkinlikleri düzenli takip edin.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: Color(0xFF6D5B52),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _TrackingSummaryStrip(childCount: childCount),
                const SizedBox(height: 8),
                if (childDocs.isNotEmpty)
                  _ChildrenList(
                    childDocs: childDocs,
                    selectedChildId: selectedChildId,
                    onChildSelect: onChildSelect,
                    onPhotoTap: onChildPhotoTap,
                    uploadingIds: uploadingIds,
                    tempUrls: tempUrls,
                  ),
                const SizedBox(height: 10),
              ],
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
              delegate: SliverChildListDelegate([
                _TrackingGridCard(
                  title: 'Aktivite G\u00fcnl\u00fc\u011f\u00fc',
                  description:
                      'G\u00fcnl\u00fck aktiviteleri kaydet ve ge\u00e7mi\u015fi g\u00f6r.',
                  icon: Icons.history,
                  color: const Color(0xFF8B83B8),
                  onTap: () {
                    if (currentChildId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ActivityLogScreen(childId: currentChildId),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'L\u00fctfen \u00f6nce bir \u00e7ocuk ekleyin.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                _TrackingGridCard(
                  title: 'Geli\u015fim G\u00fcnl\u00fc\u011f\u00fc',
                  description:
                      'Geli\u015fim notlar\u0131n\u0131 ekle, ilerlemeyi izle.',
                  icon: Icons.auto_stories,
                  color: const Color(0xFF679785),
                  onTap: () {
                    if (currentChildId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GunlukScreen(childId: currentChildId),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'L\u00fctfen \u00f6nce bir \u00e7ocuk ekleyin.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                _TrackingGridCard(
                  title: 'A\u015f\u0131 Takvimi',
                  description:
                      'A\u015f\u0131 takvimini ve hat\u0131rlatmalar\u0131 takip et.',
                  icon: Icons.vaccines,
                  color: const Color(0xFF8C83B5),
                  onTap: () {
                    if (selectedChildDoc != null) {
                      final data =
                          selectedChildDoc.data() as Map<String, dynamic>;
                      final birthDate = (data['birthDate'] as Timestamp)
                          .toDate();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VaccineCalendarPage(
                            childId: selectedChildDoc.id,
                            childName: data['name'] ?? 'Bebek',
                            birthDate: birthDate,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'L\u00fctfen \u00f6nce bir \u00e7ocuk ekleyin.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                _TrackingGridCard(
                  title: 'B\u00fcy\u00fcme Grafi\u011fi',
                  description:
                      'Boy, kilo ve ba\u015f \u00e7evresi grafiklerini incele.',
                  icon: Icons.show_chart,
                  color: const Color(0xFF638DA8),
                  onTap: () {
                    if (currentChildId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BoyKiloScreen(childId: currentChildId),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'L\u00fctfen \u00f6nce bir \u00e7ocuk ekleyin.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                _TrackingGridCard(
                  title: 'Geli\u015fim Listesi',
                  description:
                      'Geli\u015fim basamaklar\u0131n\u0131 takip edip i\u015faretle.',
                  icon: Icons.checklist_rtl,
                  color: const Color(0xFFB08B4F),
                  onTap: () {
                    if (selectedChildDoc != null) {
                      final data =
                          selectedChildDoc.data() as Map<String, dynamic>;
                      final birthDate = (data['birthDate'] as Timestamp)
                          .toDate();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GelisimScreen(
                            childId: selectedChildDoc.id,
                            birthDate: birthDate,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'L\u00fctfen \u00f6nce bir \u00e7ocuk ekleyin.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                _TrackingGridCard(
                  title: 'Ek G\u0131da Rehberi',
                  description:
                      'Ek g\u0131da \u00f6nerileri ve tariflere ula\u015f.',
                  icon: Icons.restaurant_menu,
                  color: const Color(0xFFB97E68),
                  onTap: () {
                    if (selectedChildDoc != null) {
                      final data =
                          selectedChildDoc.data() as Map<String, dynamic>;
                      final birthDate = (data['birthDate'] as Timestamp)
                          .toDate();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EkGidaScreen(
                            childId: selectedChildDoc.id,
                            birthDate: birthDate,
                          ),
                        ),
                      ); // Parantezlerin burada do\u011fru kapand\u0131\u011f\u0131ndan emin olun
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'L\u00fctfen \u00f6nce bir \u00e7ocuk se\u00e7in.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                _TrackingGridCard(
                  title: 'Ate\u015f Takibi',
                  description:
                      'Ate\u015f \u00f6l\u00e7\u00fcmlerini kaydet ve ge\u00e7mi\u015fi g\u00f6r.',
                  icon: Icons.thermostat,
                  color: const Color(0xFFB76B63),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AtesTakipScreen(),
                    ),
                  ),
                ),
                _TrackingGridCard(
                  title: 'Oyun ve Etkinlik',
                  description:
                      'Ya\u015fa uygun oyun ve etkinlik \u00f6nerileri.',
                  icon: Icons.auto_awesome,
                  color: const Color(0xFF708DAF),
                  onTap: () {
                    if (selectedChildDoc != null) {
                      final data =
                          selectedChildDoc.data() as Map<String, dynamic>;
                      final birthDate = (data['birthDate'] as Timestamp)
                          .toDate();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AktiviteScreen(
                            childId: selectedChildDoc.id,
                            birthDate: birthDate,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'L\u00fctfen \u00f6nce bir \u00e7ocuk ekleyin.',
                          ),
                        ),
                      );
                    }
                  },
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

class _TrackingSummaryStrip extends StatelessWidget {
  final int childCount;

  const _TrackingSummaryStrip({required this.childCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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

class _TrackingGridCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _TrackingGridCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF5D4037),
  });

  @override
  Widget build(BuildContext context) {
    const radius = 20.0;
    const inkColor = Color(0xFF3F312C);
    const mutedColor = Color(0xFF8B7F78);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
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
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: color, size: 25),
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
                      color: color,
                      size: 15,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  color: inkColor,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 34,
                height: 3,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.32),
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

class _ProfileTab extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String? displayPhotoUrl;
  final VoidCallback onPhotoTap;

  const _ProfileTab({
    required this.userData,
    this.displayPhotoUrl,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final isCaregiver = userData['role'] == 'bakici';
    final userRole = isCaregiver ? 'Bak\u0131c\u0131' : 'Ebeveyn';

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Profil Ba\u015fl\u0131\u011f\u0131
            const Text(
              'Profilim',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 30),

            // Profil Kart\u0131 (\u00dcst K\u0131s\u0131m - Glassmorphic)
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: onPhotoTap,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(
                                    0xFF5D4037,
                                  ).withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                                backgroundImage:
                                    (displayPhotoUrl != null &&
                                        displayPhotoUrl!.startsWith('http'))
                                    ? CachedNetworkImageProvider(
                                        displayPhotoUrl!,
                                      )
                                    : null,
                                child:
                                    (displayPhotoUrl == null ||
                                        !displayPhotoUrl!.startsWith('http'))
                                    ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Color(0xFF5D4037),
                                      )
                                    : null,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF5D4037),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        userData['name'] ?? 'Kullan\u0131c\u0131',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.brown.shade700,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D4037).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Text(
                          userRole,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Ayarlar Listesi (Glassmorphic Tiles)
            _ProfileMenuTile(
              icon: Icons.edit_outlined,
              title: 'Bilgilerimi D\u00fczenle',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(userData: userData),
                  ),
                );
              },
            ),
            _ProfileMenuTile(
              icon: Icons.child_care_rounded,
              title: isCaregiver
                  ? '\u00c7ocuk Bilgilerini G\u00f6r\u00fcnt\u00fcle'
                  : '\u00c7ocuklar\u0131m\u0131 Y\u00f6net',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CocuklarimScreen(),
                  ),
                );
              },
            ),
            if (!isCaregiver)
              _ProfileMenuTile(
                icon: Icons.people_outline_rounded,
                title: 'Bak\u0131c\u0131 Y\u00f6netimi',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CaregiverManagementScreen(),
                    ),
                  );
                },
              ),
            _ProfileMenuTile(
              icon: Icons.notifications_none_rounded,
              title: 'Bildirim Ayarlar\u0131',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
            _ProfileMenuTile(
              icon: Icons.security_outlined,
              title: 'Gizlilik ve G\u00fcvenlik',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            _ProfileMenuTile(
              icon: Icons.help_outline_rounded,
              title: 'Yard\u0131m ve Destek',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            // \u00c7\u0131k\u0131\u015f Yap Butonu (Glassmorphic Red)
            Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: InkWell(
                    onTap: () => FirebaseAuth.instance.signOut(),
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Oturumu Kapat',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ListTile(
            onTap: onTap,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5D4037).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF5D4037), size: 22),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5D4037),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF5D4037),
              size: 20,
            ),
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
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ['0-2', '2-4', '4-6'].map((group) {
          final isSelected = selectedGroup == group;
          return GestureDetector(
            onTap: () => onChanged(group),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 25),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF5D4037)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF5D4037).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '$group Ya\u015f',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF5D4037),
                    fontWeight: FontWeight.bold,
                  ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFF5D4037)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tip.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            tip.content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.brown.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicUpcomingVaccineCard extends StatelessWidget {
  final String childId;
  final DateTime birthDate;

  // Constructor (Yap\u0131c\u0131 Metot)
  const _DynamicUpcomingVaccineCard({
    required this.childId,
    required this.birthDate,
  });

  @override
  Widget build(BuildContext context) {
    // Bebe\u011fin ay\u0131n\u0131 hesapla
    final int currentMonthOfChild =
        DateTime.now().difference(birthDate).inDays ~/ 30;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vaccines_records')
          .where('childId', isEqualTo: childId)
          .where('done', isEqualTo: false)
          .where('month', isEqualTo: currentMonthOfChild)
          // limit(1) kald\u0131r\u0131ld\u0131, o ayki t\u00fcm a\u015f\u0131lar gelecek
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF7F2), // Arka plan yine yumu\u015fak krem
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5D4037).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // Sol tarafa uyar\u0131 \u00e7izgisi eklemek i\u00e7in ClipRRect ve Row kullan\u0131yoruz
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // D\u0130KKAT \u00c7EK\u0130C\u0130 \u00c7\u0130ZG\u0130: Sol tarafa ince bir uyar\u0131 bar\u0131
                Container(
                  width: 6,
                  decoration: const BoxDecoration(
                    color: Color(
                      0xFF8D6E63,
                    ), // Kahve tonunda ama belirgin bir \u015ferit
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // \u0130KON: Daha dikkat \u00e7ekici bir \u00fcnlem/takvim ikonu
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFF5D4037),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Bu Ay\u0131n A\u015f\u0131lar\u0131 ($currentMonthOfChild. Ay)",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5D4037),
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Color(0xFF574343),
                        ),
                        const SizedBox(height: 12),
                        ...docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_right_rounded,
                                  color: Color(0xFF8D6E63),
                                ),
                                Expanded(
                                  child: Text(
                                    "${data['name']} (${data['dose']})",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4E342E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF5D4037),
        unselectedItemColor: Colors.brown.shade300,
        type: BottomNavigationBarType.fixed,
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
    );
  }
}

class _ChildrenList extends StatelessWidget {
  final List<DocumentSnapshot> childDocs;
  final String? selectedChildId;
  final Function(String) onChildSelect;
  final Function(String) onPhotoTap;
  final Set<String> uploadingIds;
  final Map<String, String> tempUrls;

  const _ChildrenList({
    required this.childDocs,
    this.selectedChildId,
    required this.onChildSelect,
    required this.onPhotoTap,
    required this.uploadingIds,
    required this.tempUrls,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 6, 20, 10),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: childDocs.length + 1,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == childDocs.length) {
                return const _AddChildCircle();
              }

              final doc = childDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isSelected = doc.id == selectedChildId;
              final isUploading = uploadingIds.contains(doc.id);
              final photoUrl = tempUrls[doc.id] ?? data['photoUrl'];
              final name = (data['name'] as String?) ?? '';

              return GestureDetector(
                onTap: () => onChildSelect(doc.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 100,
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(color: Colors.transparent),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onLongPress: () => onPhotoTap(doc.id),
                                child: Container(
                                  width: 74,
                                  height: 74,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF5D4037)
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: const Color(0xFFF7F1EC),
                                    backgroundImage:
                                        (photoUrl != null &&
                                            photoUrl.startsWith('http'))
                                        ? CachedNetworkImageProvider(photoUrl)
                                        : null,
                                    child:
                                        (photoUrl == null ||
                                            !photoUrl.startsWith('http'))
                                        ? Text(
                                            name.isNotEmpty ? name[0] : '?',
                                            style: const TextStyle(
                                              color: Color(0xFF5D4037),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              if (isUploading)
                                const SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Color(0xFF5D4037),
                                  ),
                                ),
                              if (isSelected)
                                Positioned(
                                  right: -3,
                                  top: -3,
                                  child: Tooltip(
                                    message:
                                        '${name.isEmpty ? 'Çocuk' : name} bilgilerini düzenle',
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
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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

// --- TABS ---
