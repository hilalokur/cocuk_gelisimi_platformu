import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'utils/image_upload.dart';
import 'utils/pdf_export_service.dart';

class GunlukScreen extends StatefulWidget {
  final String childId;
  const GunlukScreen({super.key, required this.childId});

  @override
  State<GunlukScreen> createState() => _GunlukScreenState();
}

class _GunlukScreenState extends State<GunlukScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final userRole = userData?['role'] ?? 'parent';
        final userName =
            userData?['name'] ?? (userRole == 'bakici' ? 'Bakıcı' : 'Ebeveyn');
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        if (userRole == 'bakici') {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Gelişim Günlüğü'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: const Color(0xFF5D4037),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Bu alan sadece ebeveyn hesabı tarafından görüntülenebilir.',
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
            title: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('children')
                  .doc(widget.childId)
                  .snapshots(),
              builder: (context, snapshot) {
                String name = 'Günlük';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  name = data?['name'] ?? 'Günlük';
                }
                return Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                );
              },
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: const Color(0xFF5D4037),
            actions: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('journal')
                    .where('childId', isEqualTo: widget.childId)
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final docs = userRole == 'bakici'
                      ? snapshot.data!.docs
                            .where(
                              (doc) =>
                                  (doc.data()
                                      as Map<String, dynamic>)['isPrivate'] !=
                                  true,
                            )
                            .toList()
                      : snapshot.data!.docs;

                  if (docs.isEmpty) return const SizedBox.shrink();

                  return IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    tooltip: 'PDF Olarak Dışa Aktar',
                    onPressed: () async {
                      final childDoc = await FirebaseFirestore.instance
                          .collection('children')
                          .doc(widget.childId)
                          .get();
                      final childName = childDoc.data()?['name'] ?? 'Bebek';
                      await PdfExportService.exportJournal(
                        childName: childName,
                        entries: docs,
                      );
                    },
                  );
                },
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
                  child: Container(color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
              SafeArea(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('journal')
                      .where('childId', isEqualTo: widget.childId)
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF5D4037),
                        ),
                      );
                    }

                    final docs = userRole == 'bakici'
                        ? snapshot.data!.docs
                              .where(
                                (doc) =>
                                    (doc.data()
                                        as Map<String, dynamic>)['isPrivate'] !=
                                    true,
                              )
                              .toList()
                        : snapshot.data!.docs;

                    if (docs.isEmpty) return _buildEmptyState();

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final date =
                            (data['date'] as Timestamp?)?.toDate() ??
                            DateTime.now();
                        final imageUrl = data['imageUrl'] as String?;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(25),
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
                            borderRadius: BorderRadius.circular(25),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      15,
                                      10,
                                      5,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat(
                                                'dd MMMM yyyy HH:mm',
                                                'tr_TR',
                                              ).format(date),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.brown.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (data['authorName'] != null)
                                              Text(
                                                'Ekleyen: ${data['authorName']}',
                                                style: TextStyle(
                                                  color: Colors.brown.shade400,
                                                  fontSize: 10,
                                                ),
                                              ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            if (data['isPrivate'] == true)
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                child: Icon(
                                                  Icons.lock_outline,
                                                  size: 16,
                                                  color: Colors.brown,
                                                ),
                                              ),
                                            if (userRole == 'parent' ||
                                                data['authorId'] ==
                                                    currentUserId)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 20,
                                                  color: Colors.redAccent,
                                                ),
                                                onPressed: () =>
                                                    _showDeleteConfirmDialog(
                                                      doc.id,
                                                    ),
                                                constraints:
                                                    const BoxConstraints(),
                                                padding: EdgeInsets.zero,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      5,
                                      20,
                                      15,
                                    ),
                                    child: Text(
                                      data['note'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF5D4037),
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (imageUrl != null && imageUrl.isNotEmpty)
                                    GestureDetector(
                                      onTap: () =>
                                          _showImageZoom(context, imageUrl),
                                      child: Container(
                                        width: double.infinity,
                                        constraints: const BoxConstraints(
                                          maxHeight: 300,
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                                height: 200,
                                                color: Colors.white24,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const SizedBox.shrink(),
                                        ),
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
                ),
              ),
              if (_isUploading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                _showAddNoteDialog(context, userName, userRole, currentUserId),
            backgroundColor: const Color(0xFF5D4037),
            icon: const Icon(Icons.add_a_photo, color: Colors.white),
            label: const Text(
              'Anı Ekle',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImageZoom(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: const Color(0xFF5D4037).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Henüz bir anı kaydedilmemiş.',
            style: TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(
    BuildContext context,
    String userName,
    String userRole,
    String? currentUserId,
  ) {
    final noteController = TextEditingController();
    String? uploadedImageUrl;
    bool isPrivate = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            title: const Text(
              'Yeni Anı Yaz',
              style: TextStyle(
                fontWeight: FontWeight.bold,

                color: Color(0xFF5D4037),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        final url = await ImageUploadUtils.pickAndUploadImage();
                        if (url != null) {
                          setDialogState(() => uploadedImageUrl = url);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Fotoğraf yüklenemedi: $e')),
                          );
                        }
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: uploadedImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: CachedNetworkImage(
                                imageUrl: uploadedImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Fotoğraf Ekle',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Bugün neler oldu?',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(15),
                    ),
                  ),
                  if (userRole == 'parent')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SwitchListTile(
                        title: const Text(
                          'Özel Not',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Sadece ebeveynler görebilir',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: isPrivate,
                        activeThumbColor: const Color(0xFF5D4037),
                        onChanged: (val) =>
                            setDialogState(() => isPrivate = val),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'İptal',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D4037),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (noteController.text.isEmpty && uploadedImageUrl == null) {
                    return;
                  }
                  Navigator.pop(context);
                  setState(() => _isUploading = true);
                  try {
                    await FirebaseFirestore.instance.collection('journal').add({
                      'childId': widget.childId,
                      'date': FieldValue.serverTimestamp(),
                      'note': noteController.text.trim(),
                      'imageUrl': uploadedImageUrl,
                      'authorId': currentUserId,
                      'authorName': userName,
                      'isPrivate': isPrivate,
                    });

                    // Add to Activity Log
                    await FirebaseFirestore.instance
                        .collection('activity_log')
                        .add({
                          'childId': widget.childId,
                          'actionType': 'journal_added',
                          'authorName': userName,
                          'userRole': userRole,
                          'timestamp': FieldValue.serverTimestamp(),
                          'details': noteController.text.length > 50
                              ? '${noteController.text.substring(0, 50)}...'
                              : noteController.text,
                          'isPrivate': isPrivate,
                        });
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                    }
                  } finally {
                    if (mounted) setState(() => _isUploading = false);
                  }
                },
                child: const Text(
                  'Kaydet',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anıyı Sil'),
        content: const Text('Silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('journal')
                  .doc(docId)
                  .delete();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
