import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'alerjiler_screen.dart';
import 'providers/child_provider.dart';

class CocuklarimScreen extends StatefulWidget {
  const CocuklarimScreen({super.key});

  @override
  State<CocuklarimScreen> createState() => _CocuklarimScreenState();
}

class _CocuklarimScreenState extends State<CocuklarimScreen> {
  static const _bloodTypes = [
    'A Rh+',
    'A Rh-',
    'B Rh+',
    'B Rh-',
    'AB Rh+',
    'AB Rh-',
    '0 Rh+',
    '0 Rh-',
  ];
  static const _allergyOptions = [
    'Süt',
    'Yumurta',
    'Yer Fıstığı',
    'Gluten',
    'Deniz Ürünleri',
  ];
  static const _dietOptions = [
    'Glutensiz',
    'Laktozsuz',
    'Vejetaryen',
    'Diyabet Diyeti',
  ];

  final _nameController = TextEditingController();
  final _allergyOtherController = TextEditingController();
  final _dietOtherController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedBloodType;
  final Set<String> _selectedAllergies = {};
  final Set<String> _selectedDiets = {};
  bool _isLoading = false;

  Future<void> _addChild() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedDate == null || _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('children').add({
          'name': name,
          'birthDate': Timestamp.fromDate(_selectedDate!),
          'gender': _selectedGender,
          'bloodType': _selectedBloodType,
          'allergies': _selectedAllergies.toList(),
          'allergiesOther': _allergyOtherController.text.trim(),
          'specialDiets': _selectedDiets.toList(),
          'specialDietsOther': _dietOtherController.text.trim(),
          'notes': '',
          'parentId': user.uid,
          'photoUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        _nameController.clear();
        setState(() {
          _selectedDate = null;
          _selectedGender = null;
          _selectedBloodType = null;
          _selectedAllergies.clear();
          _selectedDiets.clear();
          _allergyOtherController.clear();
          _dietOtherController.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Çocuk başarıyla eklendi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteChild(String childId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Çocuğu Sil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bu çocuğu silmek istediğine emin misin? Bu işlem geri alınamaz.',
          style: TextStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Evet, Sil',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();

        // Ana çocuk dökümanı
        batch.delete(
          FirebaseFirestore.instance.collection('children').doc(childId),
        );

        // Büyüme kayıtlarını bul ve sil
        final QuerySnapshot growthRecords = await FirebaseFirestore.instance
            .collection('growth_records')
            .where('childId', isEqualTo: childId)
            .get();
        for (var doc in growthRecords.docs) {
          batch.delete(doc.reference);
        }

        // Günlük kayıtlarını bul ve sil
        final QuerySnapshot journalRecords = await FirebaseFirestore.instance
            .collection('journal')
            .where('childId', isEqualTo: childId)
            .get();
        for (var doc in journalRecords.docs) {
          batch.delete(doc.reference);
        }

        // Aşı kayıtlarını sil
        final QuerySnapshot vaccineRecords = await FirebaseFirestore.instance
            .collection('vaccines_records')
            .where('childId', isEqualTo: childId)
            .get();
        for (var doc in vaccineRecords.docs) {
          batch.delete(doc.reference);
        }

        // Gelişim kilometre taşlarını sil
        final QuerySnapshot milestoneRecords = await FirebaseFirestore.instance
            .collection('completed_milestones')
            .where('childId', isEqualTo: childId)
            .get();
        for (var doc in milestoneRecords.docs) {
          batch.delete(doc.reference);
        }

        // Ek gıda denemelerini sil
        final QuerySnapshot triedFoodRecords = await FirebaseFirestore.instance
            .collection('tried_foods')
            .where('childId', isEqualTo: childId)
            .get();
        for (var doc in triedFoodRecords.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Çocuk ve ilgili tüm veriler başarıyla silindi'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silme işlemi sırasında hata oluştu: $e')),
          );
        }
      }
    }
  }

  Future<void> _showEditChildDialog(
    String childId,
    Map<String, dynamic> data,
  ) async {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final notesController = TextEditingController(text: data['notes'] ?? '');
    DateTime selectedDate =
        (data['birthDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    String? selectedGender = data['gender'] as String?;
    String? selectedBloodType = data['bloodType'] as String?;
    final selectedAllergies =
        (data['allergies'] as List?)?.whereType<String>().toSet() ?? <String>{};
    final selectedDiets =
        (data['specialDiets'] as List?)?.whereType<String>().toSet() ??
        <String>{};
    final allergyOtherController = TextEditingController(
      text: data['allergiesOther'] ?? '',
    );
    final dietOtherController = TextEditingController(
      text: data['specialDietsOther'] ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Çocuk Bilgilerini Düzenle',
                        style: TextStyle(
                          color: Color(0xFF3F312C),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad',
                          prefixIcon: Icon(Icons.child_care_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2010),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setSheetState(() => selectedDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded),
                        label: Text(
                          DateFormat('dd.MM.yyyy').format(selectedDate),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'Cinsiyet',
                                border: OutlineInputBorder(),
                              ),
                              items: ['Kız', 'Erkek']
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setSheetState(() => selectedGender = value),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedBloodType,
                              decoration: const InputDecoration(
                                labelText: 'Kan Grubu',
                                border: OutlineInputBorder(),
                              ),
                              items: _bloodTypes
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setSheetState(
                                () => selectedBloodType = value,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _AllergyPageTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlerjilerScreen(
                                childId: childId,
                                childName: nameController.text.trim().isEmpty
                                    ? 'Çocuk'
                                    : nameController.text.trim(),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _HealthSection(
                        allergyOptions: _allergyOptions,
                        dietOptions: _dietOptions,
                        selectedAllergies: selectedAllergies,
                        selectedDiets: selectedDiets,
                        allergyOtherController: allergyOtherController,
                        dietOtherController: dietOtherController,
                        onAllergyToggle: (value) {
                          setSheetState(() {
                            selectedAllergies.contains(value)
                                ? selectedAllergies.remove(value)
                                : selectedAllergies.add(value);
                          });
                        },
                        onDietToggle: (value) {
                          setSheetState(() {
                            selectedDiets.contains(value)
                                ? selectedDiets.remove(value)
                                : selectedDiets.add(value);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Ek Bilgiler',
                          hintText: 'Alerji, doktor notu, özel bilgi...',
                          prefixIcon: Icon(Icons.notes_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty || selectedGender == null) {
                              return;
                            }
                            await FirebaseFirestore.instance
                                .collection('children')
                                .doc(childId)
                                .update({
                                  'name': name,
                                  'birthDate': Timestamp.fromDate(selectedDate),
                                  'gender': selectedGender,
                                  'bloodType': selectedBloodType,
                                  'allergies': selectedAllergies.toList(),
                                  'allergiesOther': allergyOtherController.text
                                      .trim(),
                                  'specialDiets': selectedDiets.toList(),
                                  'specialDietsOther': dietOtherController.text
                                      .trim(),
                                  'notes': notesController.text.trim(),
                                });
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF5D4037),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    notesController.dispose();
    allergyOtherController.dispose();
    dietOtherController.dispose();
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final days = difference.inDays;

    if (days < 7) return '$days günlük';
    if (days < 30) return '${(days / 7).floor()} haftalık';
    if (days < 365) return '${(days / 30).floor()} aylık';
    final years = (days / 365).floor();
    final remainingMonths = ((days % 365) / 30).floor();
    return remainingMonths > 0
        ? '$years yaş, $remainingMonths aylık'
        : '$years yaşında';
  }

  String _getAgeGroup(DateTime birthDate) {
    final ageInDays = DateTime.now().difference(birthDate).inDays;
    final ageInYears = ageInDays / 365;
    if (ageInYears < 2) return '0-2 Yaş Grubu';
    if (ageInYears < 4) return '2-4 Yaş Grubu';
    return '4-6 Yaş Grubu';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allergyOtherController.dispose();
    _dietOtherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, userDocSnapshot) {
        if (userDocSnapshot.hasError) {
          return const Center(child: Text('Hata oluştu'));
        }
        if (userDocSnapshot.connectionState == ConnectionState.waiting &&
            !userDocSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userDocSnapshot.data?.data() as Map<String, dynamic>?;
        final bool isCaregiver = userData?['role'] == 'bakici';
        final String? targetParentId = isCaregiver
            ? (userData?['parentId'] as String?)
            : user?.uid;

        if (isCaregiver) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Çocuklarım'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: const Color(0xFF5D4037),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Çocuk profilleri yalnızca ebeveyn hesabı tarafından düzenlenebilir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5D4037),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Çocuklarım',
              style: TextStyle(fontWeight: FontWeight.bold),
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
                  child: Container(color: Colors.white.withValues(alpha: 0.2)),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    // Çocuk Ekleme Formu
                    if (!isCaregiver)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.56,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(),
                                  decoration: const InputDecoration(
                                    labelText: 'Çocuğun Adı',
                                    labelStyle: TextStyle(),
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: Color(0xFF5D4037),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2010),
                                            lastDate: DateTime.now(),
                                            builder: (context, child) => Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme:
                                                    const ColorScheme.light(
                                                      primary: Color(
                                                        0xFF5D4037,
                                                      ),
                                                    ),
                                              ),
                                              child: child!,
                                            ),
                                          );
                                          if (date != null) {
                                            setState(
                                              () => _selectedDate = date,
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                        ),
                                        label: Text(
                                          _selectedDate == null
                                              ? 'Doğum Tarihi'
                                              : DateFormat(
                                                  'dd.MM.yyyy',
                                                ).format(_selectedDate!),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF5D4037,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _selectedGender,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                        ),
                                        hint: const Text(
                                          'Cinsiyet',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        items: ['Kız', 'Erkek']
                                            .map(
                                              (g) => DropdownMenuItem(
                                                value: g,
                                                child: Text(
                                                  g,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) => setState(
                                          () => _selectedGender = val,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedBloodType,
                                  decoration: InputDecoration(
                                    labelText: 'Kan Grubu',
                                    prefixIcon: const Icon(
                                      Icons.bloodtype_outlined,
                                      color: Color(0xFF5D4037),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  items: _bloodTypes
                                      .map(
                                        (type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(type),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedBloodType = val),
                                ),
                                const SizedBox(height: 15),
                                _HealthSection(
                                  allergyOptions: _allergyOptions,
                                  dietOptions: _dietOptions,
                                  selectedAllergies: _selectedAllergies,
                                  selectedDiets: _selectedDiets,
                                  allergyOtherController:
                                      _allergyOtherController,
                                  dietOtherController: _dietOtherController,
                                  onAllergyToggle: (value) {
                                    setState(() {
                                      _selectedAllergies.contains(value)
                                          ? _selectedAllergies.remove(value)
                                          : _selectedAllergies.add(value);
                                    });
                                  },
                                  onDietToggle: (value) {
                                    setState(() {
                                      _selectedDiets.contains(value)
                                          ? _selectedDiets.remove(value)
                                          : _selectedDiets.add(value);
                                    });
                                  },
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _addChild,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5D4037),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Çocuk Ekle',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Çocuk Listesi
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('children')
                            .where('parentId', isEqualTo: targetParentId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(child: Text('Bir hata oluştu'));
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'Henüz çocuk eklenmemiş',
                                style: TextStyle(),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: isCaregiver ? 20 : 0,
                            ),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;
                              final bDay = (data['birthDate'] as Timestamp)
                                  .toDate();
                              final photoUrl = data['photoUrl'] as String?;
                              final bloodType = data['bloodType'] as String?;
                              final allergies =
                                  (data['allergiesOfficial'] as List?)
                                      ?.whereType<String>()
                                      .toList() ??
                                  (data['allergies'] as List?)
                                      ?.whereType<String>()
                                      .toList() ??
                                  [];
                              final allergyOther =
                                  (data['allergiesCustom'] as String?)
                                      ?.trim() ??
                                  (data['allergiesOther'] as String?)?.trim() ??
                                  '';
                              final allergyNote =
                                  (data['allergyNote'] as String?)?.trim() ??
                                  '';
                              final allergyDoctorNote =
                                  (data['allergyDoctorNote'] as String?)
                                      ?.trim() ??
                                  '';
                              final allergyDiagnosedAt =
                                  data['allergyDiagnosedAt'] as Timestamp?;
                              final specialDiets =
                                  (data['specialDiets'] as List?)
                                      ?.whereType<String>()
                                      .toList() ??
                                  [];
                              final dietOther =
                                  (data['specialDietsOther'] as String?)
                                      ?.trim() ??
                                  '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(10),
                                  leading: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: const Color(
                                      0xFF5D4037,
                                    ).withValues(alpha: 0.1),
                                    backgroundImage:
                                        (photoUrl != null &&
                                            photoUrl.startsWith('http'))
                                        ? CachedNetworkImageProvider(photoUrl)
                                        : null,
                                    child:
                                        (photoUrl == null ||
                                            !photoUrl.startsWith('http'))
                                        ? const Icon(
                                            Icons.child_care,
                                            color: Color(0xFF5D4037),
                                            size: 30,
                                          )
                                        : null,
                                  ),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF5D4037,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          _getAgeGroup(bDay),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF5D4037),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color(0xFF5D4037),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        [
                                          _calculateAge(bDay),
                                          if (bloodType != null &&
                                              bloodType.isNotEmpty)
                                            'Kan: $bloodType',
                                        ].join('  •  '),
                                        style: TextStyle(
                                          color: Colors.brown.shade600,
                                        ),
                                      ),
                                      _HealthInfoPreview(
                                        allergies: allergies,
                                        allergiesOther: allergyOther,
                                        allergyNote: allergyNote,
                                        allergyDoctorNote: allergyDoctorNote,
                                        allergyDiagnosedAt: allergyDiagnosedAt
                                            ?.toDate(),
                                        specialDiets: specialDiets,
                                        specialDietsOther: dietOther,
                                      ),
                                      const SizedBox(height: 6),
                                      _AllergyPageLink(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AlerjilerScreen(
                                                childId: docs[index].id,
                                                childName: data['name'] ?? '',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isCaregiver)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () =>
                                              _deleteChild(docs[index].id),
                                        ),
                                      IconButton(
                                        tooltip: 'Bilgileri düzenle',
                                        icon: const Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF5D4037),
                                        ),
                                        onPressed: isCaregiver
                                            ? null
                                            : () => _showEditChildDialog(
                                                docs[index].id,
                                                data,
                                              ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    context
                                        .read<ChildProvider>()
                                        .setSelectedChild(docs[index].id);
                                    Navigator.pop(context);
                                  },
                                ),
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
      },
    );
  }
}

class _HealthSection extends StatelessWidget {
  final List<String> allergyOptions;
  final List<String> dietOptions;
  final Set<String> selectedAllergies;
  final Set<String> selectedDiets;
  final TextEditingController allergyOtherController;
  final TextEditingController dietOtherController;
  final ValueChanged<String> onAllergyToggle;
  final ValueChanged<String> onDietToggle;

  const _HealthSection({
    required this.allergyOptions,
    required this.dietOptions,
    required this.selectedAllergies,
    required this.selectedDiets,
    required this.allergyOtherController,
    required this.dietOtherController,
    required this.onAllergyToggle,
    required this.onDietToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EFE9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF5D4037).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_rounded, color: Color(0xFF5D4037)),
              SizedBox(width: 8),
              Text(
                'Sağlık Bilgileri',
                style: TextStyle(
                  color: Color(0xFF3F312C),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MultiSelectGroup(
            title: 'Alerjiler',
            options: allergyOptions,
            selectedValues: selectedAllergies,
            onToggle: onAllergyToggle,
          ),
          const SizedBox(height: 10),
          _OtherField(
            controller: allergyOtherController,
            label: 'Diğer alerji',
          ),
          const SizedBox(height: 14),
          _MultiSelectGroup(
            title: 'Özel Diyet Gereksinimleri',
            options: dietOptions,
            selectedValues: selectedDiets,
            onToggle: onDietToggle,
          ),
          const SizedBox(height: 10),
          _OtherField(
            controller: dietOtherController,
            label: 'Diğer diyet gereksinimi',
          ),
        ],
      ),
    );
  }
}

class _AllergyPageTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AllergyPageTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFAF6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(Icons.medical_information_rounded, color: Color(0xFF5D4037)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sağlık Bilgileri > Alerjiler',
                  style: TextStyle(
                    color: Color(0xFF3F312C),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF5D4037)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllergyPageLink extends StatelessWidget {
  final VoidCallback onTap;

  const _AllergyPageLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.medical_information_rounded, size: 16),
        label: const Text('Alerji detayları'),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF5D4037),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _MultiSelectGroup extends StatelessWidget {
  final String title;
  final List<String> options;
  final Set<String> selectedValues;
  final ValueChanged<String> onToggle;

  const _MultiSelectGroup({
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF5D4037),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final selected = selectedValues.contains(option);
            return FilterChip(
              label: Text(option),
              selected: selected,
              onSelected: (_) => onToggle(option),
              selectedColor: const Color(0xFF5D4037).withValues(alpha: 0.16),
              checkmarkColor: const Color(0xFF5D4037),
              backgroundColor: Colors.white.withValues(alpha: 0.82),
              labelStyle: TextStyle(
                color: selected
                    ? const Color(0xFF5D4037)
                    : const Color(0xFF6D5B52),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF5D4037).withValues(alpha: 0.3)
                      : Colors.white,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _OtherField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _OtherField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.82),
        prefixIcon: const Icon(
          Icons.edit_note_rounded,
          color: Color(0xFF5D4037),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _HealthInfoPreview extends StatelessWidget {
  final List<String> allergies;
  final String allergiesOther;
  final String allergyNote;
  final String allergyDoctorNote;
  final DateTime? allergyDiagnosedAt;
  final List<String> specialDiets;
  final String specialDietsOther;

  const _HealthInfoPreview({
    required this.allergies,
    required this.allergiesOther,
    required this.allergyNote,
    required this.allergyDoctorNote,
    required this.allergyDiagnosedAt,
    required this.specialDiets,
    required this.specialDietsOther,
  });

  @override
  Widget build(BuildContext context) {
    final allergyText = _joinValues(allergies, allergiesOther);
    final dietText = _joinValues(specialDiets, specialDietsOther);
    final dateText = allergyDiagnosedAt == null
        ? ''
        : '${allergyDiagnosedAt!.day}.${allergyDiagnosedAt!.month}.${allergyDiagnosedAt!.year}';
    if (allergyText.isEmpty &&
        dietText.isEmpty &&
        allergyNote.isEmpty &&
        allergyDoctorNote.isEmpty &&
        dateText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8EFE9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sağlık Bilgileri',
              style: TextStyle(
                color: Color(0xFF3F312C),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (allergyText.isNotEmpty)
              _HealthInfoLine(label: 'Alerjiler', value: allergyText),
            if (dateText.isNotEmpty)
              _HealthInfoLine(label: 'Teşhis', value: dateText),
            if (allergyNote.isNotEmpty)
              _HealthInfoLine(label: 'Alerji notu', value: allergyNote),
            if (allergyDoctorNote.isNotEmpty)
              _HealthInfoLine(label: 'Doktor notu', value: allergyDoctorNote),
            if (dietText.isNotEmpty)
              _HealthInfoLine(label: 'Diyet', value: dietText),
          ],
        ),
      ),
    );
  }

  String _joinValues(List<String> values, String other) {
    final all = [...values];
    if (other.trim().isNotEmpty) all.add(other.trim());
    return all.join(', ');
  }
}

class _HealthInfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _HealthInfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$label: $value',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF6D5B52),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}
