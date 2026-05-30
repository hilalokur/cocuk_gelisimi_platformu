import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CocuklarimScreen extends StatefulWidget {
  const CocuklarimScreen({super.key});

  @override
  State<CocuklarimScreen> createState() => _CocuklarimScreenState();
}


class _CocuklarimScreenState extends State<CocuklarimScreen> {
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
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
          'parentId': user.uid,
          'photoUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        _nameController.clear();
        setState(() {
          _selectedDate = null;
          _selectedGender = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Çocuk başarıyla eklendi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
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
        title: const Text('Çocuğu Sil', style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
        content: const Text('Bu çocuğu silmek istediğine emin misin? Bu işlem geri alınamaz.', style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Evet, Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        
        // Ana çocuk dökümanı
        batch.delete(FirebaseFirestore.instance.collection('children').doc(childId));
        
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
            const SnackBar(content: Text('Çocuk ve ilgili tüm veriler başarıyla silindi')),
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

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final days = difference.inDays;
    
    if (days < 7) return '$days günlük';
    if (days < 30) return '${(days / 7).floor()} haftalık';
    if (days < 365) return '${(days / 30).floor()} aylık';
    final years = (days / 365).floor();
    final remainingMonths = ((days % 365) / 30).floor();
    return remainingMonths > 0 ? '$years yaş, $remainingMonths aylık' : '$years yaşında';
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
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userDocSnapshot) {
        if (userDocSnapshot.hasError) return const Center(child: Text('Hata oluştu'));
        if (userDocSnapshot.connectionState == ConnectionState.waiting && !userDocSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userDocSnapshot.data?.data() as Map<String, dynamic>?;
        final bool isCaregiver = userData?['role'] == 'bakici';
        final String? targetParentId = isCaregiver ? (userData?['parentId'] as String?) : user?.uid;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Çocuklarım', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'serif', fontStyle: FontStyle.italic)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: const Color(0xFF5D4037),
          ),
          body: Stack(
            children: [
              Positioned.fill(child: Image.asset('assets/bg1.png', fit: BoxFit.cover)),
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
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic),
                              decoration: const InputDecoration(
                                labelText: 'Çocuğun Adı',
                                labelStyle: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic),
                                prefixIcon: Icon(Icons.person_outline, color: Color(0xFF5D4037)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
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
                                          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF5D4037))),
                                          child: child!,
                                        ),
                                      );
                                      if (date != null) setState(() => _selectedDate = date);
                                    },
                                    icon: const Icon(Icons.calendar_today, size: 18),
                                    label: Text(
                                      _selectedDate == null ? 'Doğum Tarihi' : DateFormat('dd.MM.yyyy').format(_selectedDate!),
                                      style: const TextStyle(fontSize: 12, fontFamily: 'serif', fontStyle: FontStyle.italic),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF5D4037),
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedGender,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                    hint: const Text('Cinsiyet', style: TextStyle(fontSize: 12, fontFamily: 'serif', fontStyle: FontStyle.italic)),
                                    items: ['Kız', 'Erkek'].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 14, fontFamily: 'serif', fontStyle: FontStyle.italic)))).toList(),
                                    onChanged: (val) => setState(() => _selectedGender = val),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _addChild,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5D4037),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                child: _isLoading 
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Çocuk Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'serif', fontStyle: FontStyle.italic)),
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
                          if (snapshot.hasError) return const Center(child: Text('Bir hata oluştu'));
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                          
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) return const Center(child: Text('Henüz çocuk eklenmemiş', style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic)));

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: isCaregiver ? 20 : 0),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final bDay = (data['birthDate'] as Timestamp).toDate();
                              final photoUrl = data['photoUrl'] as String?;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(10),
                                  leading: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: const Color(0xFF5D4037).withValues(alpha: 0.1),
                                    backgroundImage: (photoUrl != null && photoUrl.startsWith('http')) ? CachedNetworkImageProvider(photoUrl) : null,
                                    child: (photoUrl == null || !photoUrl.startsWith('http')) ? const Icon(Icons.child_care, color: Color(0xFF5D4037), size: 30) : null,
                                  ),
                                  title: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF5D4037).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _getAgeGroup(bDay),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF5D4037),
                                            fontStyle: FontStyle.italic,
                                            fontFamily: 'serif',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5D4037), fontFamily: 'serif', fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                  subtitle: Text(_calculateAge(bDay), style: TextStyle(color: Colors.brown.shade600, fontFamily: 'serif', fontStyle: FontStyle.italic)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isCaregiver)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () => _deleteChild(docs[index].id),
                                        ),
                                      const Icon(Icons.chevron_right, color: Color(0xFF5D4037)),
                                    ],
                                  ),
                                  onTap: () {
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
      }
    );
  }
}
