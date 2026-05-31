import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
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

  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedBloodType;
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
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
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
                                                  primary: Color(0xFF5D4037),
                                                ),
                                          ),
                                          child: child!,
                                        ),
                                      );
                                      if (date != null) {
                                        setState(() => _selectedDate = date);
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
                                      foregroundColor: const Color(0xFF5D4037),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
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
                                        borderRadius: BorderRadius.circular(15),
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
                                    onChanged: (val) =>
                                        setState(() => _selectedGender = val),
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
                                  subtitle: Text(
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
