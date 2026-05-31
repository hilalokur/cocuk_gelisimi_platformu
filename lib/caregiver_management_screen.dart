import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CaregiverManagementScreen extends StatefulWidget {
  const CaregiverManagementScreen({super.key});

  @override
  State<CaregiverManagementScreen> createState() =>
      _CaregiverManagementScreenState();
}

class _CaregiverManagementScreenState extends State<CaregiverManagementScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _inviteCaregiver() async {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    if (phone.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen isim ve telefon numarası girin')),
      );
      return;
    }

    String formattedPhone = phone;
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+90$formattedPhone';
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check if already invited
        final existing = await FirebaseFirestore.instance
            .collection('caregivers')
            .where('phone', isEqualTo: formattedPhone)
            .where('parentId', isEqualTo: user.uid)
            .get();

        if (existing.docs.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bu bakıcı zaten ekli')),
            );
          }
          return;
        }

        await FirebaseFirestore.instance.collection('caregivers').add({
          'name': name,
          'phone': formattedPhone,
          'parentId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        _phoneController.clear();
        _nameController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bakıcı başarıyla eklendi')),
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

  Future<void> _removeCaregiver(String docId, String? caregiverUid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          title: const Text(
            'Bakıcıyı Kaldır',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          content: const Text(
            'Bu bakıcının erişimini iptal etmek istediğinize emin misiniz?',
            style: TextStyle(color: Colors.brown),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Kaldır',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('caregivers')
            .doc(docId)
            .delete();

        // If the caregiver has a user record, we might want to update their role or parentId,
        // but for simplicity, deleting the caregiver invitation is enough to block future logins/access.
        // However, if they are already logged in, we should ideally update their user doc too.
        if (caregiverUid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(caregiverUid)
              .update({'parentId': FieldValue.delete(), 'role': 'unassigned'});
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Bakıcı kaldırıldı')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Bakıcı Yönetimi',
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
              child: Container(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Glassmorphic Add Form
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Column(
                        children: [
                          const Text(
                            'Yeni Bakıcı Davet Et',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildModernField(
                            controller: _nameController,
                            label: 'Bakıcı Adı',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          _buildModernField(
                            controller: _phoneController,
                            label: 'Telefon Numarası (5xx...)',
                            icon: Icons.phone_android,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _inviteCaregiver,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5D4037),
                                foregroundColor: Colors.white,
                                elevation: 0,
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
                                      'Davet Gönder',
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
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('caregivers')
                        .where('parentId', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return const Center(child: Text('Hata oluştu'));
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 80,
                                color: const Color(
                                  0xFF5D4037,
                                ).withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Henüz bakıcı eklenmemiş.',
                                style: TextStyle(
                                  color: const Color(
                                    0xFF5D4037,
                                  ).withValues(alpha: 0.7),
                                  fontSize: 16,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final String status = data['status'] ?? 'pending';
                          final String? caregiverUid =
                              data['caregiverUid']; // Bakıcı kayıt olduğunda buraya UID yazılmalı

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        (status == 'active'
                                                ? Colors.green
                                                : Colors.orange)
                                            .withValues(alpha: 0.1),
                                    child: Icon(
                                      status == 'active'
                                          ? Icons.verified_user
                                          : Icons.person_search,
                                      color: status == 'active'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                  title: Text(
                                    data['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5D4037),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['phone'] ?? '',
                                        style: TextStyle(
                                          color: Colors.brown.shade600,

                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (status == 'active'
                                                      ? Colors.green
                                                      : Colors.orange)
                                                  .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color:
                                                (status == 'active'
                                                        ? Colors.green
                                                        : Colors.orange)
                                                    .withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: status == 'active'
                                                    ? Colors.green
                                                    : Colors.orange,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              status == 'active'
                                                  ? 'Aktif Bakıcı'
                                                  : 'Davet Bekleniyor',
                                              style: TextStyle(
                                                color: status == 'active'
                                                    ? Colors.green.shade800
                                                    : Colors.orange.shade800,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _removeCaregiver(
                                      docs[index].id,
                                      caregiverUid,
                                    ),
                                  ),
                                ),
                              ),
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

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF5D4037).withValues(alpha: 0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFF5D4037)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.brown.shade700, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF5D4037), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
