import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ActivityLogScreen extends StatelessWidget {
  final String childId;
  const ActivityLogScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Aktivite Günlüğü',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'serif', fontStyle: FontStyle.italic),
        ),
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
              child: Container(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('activity_log')
                  .where('childId', isEqualTo: childId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF5D4037)));
                }

                // Get current user role from snapshots for real-time updates
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                  builder: (context, userSnapshot) {
                    final userRole = (userSnapshot.data?.data() as Map<String, dynamic>?)?['role'] ?? 'parent';
                    
                    var logs = snapshot.data?.docs ?? [];
                    
                    // Bakıcılar için isPrivate true olan journal_added loglarını filtrele
                    if (userRole == 'bakici') {
                      logs = logs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['isPrivate'] != true;
                      }).toList();
                    }

                    if (logs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Henüz bir aktivite kaydedilmemiş.',
                          style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final data = logs[index].data() as Map<String, dynamic>;
                        final timestamp = data['timestamp'] as Timestamp?;
                        final date = timestamp?.toDate() ?? DateTime.now();
                        
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: _getIconForAction(data['actionType']),
                                title: Text(
                                  _getActionText(data),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 14, 
                                    fontFamily: 'serif', 
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF5D4037),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (data['details'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                                        child: Text(
                                          data['details'],
                                          style: const TextStyle(
                                            fontSize: 12, 
                                            color: Colors.brown, 
                                            fontFamily: 'serif', 
                                            fontStyle: FontStyle.italic
                                          ),
                                        ),
                                      ),
                                    Text(
                                      DateFormat('dd MMMM HH:mm', 'tr_TR').format(date),
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'serif'),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (data['userRole'] == 'bakici' ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    data['userRole'] == 'bakici' ? 'Bakıcı' : 'Ebeveyn',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: data['userRole'] == 'bakici' ? Colors.orange.shade800 : Colors.blue.shade800,
                                      fontFamily: 'serif',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _getIconForAction(String? actionType) {
    IconData icon;
    Color color;

    switch (actionType) {
      case 'journal_added':
        icon = Icons.book;
        color = Colors.brown;
        break;
      case 'growth_record_added':
        icon = Icons.show_chart;
        color = Colors.blue;
        break;
      case 'vaccine_completed':
        icon = Icons.vaccines;
        color = Colors.green;
        break;
      case 'milestone_completed':
        icon = Icons.check_circle;
        color = Colors.purple;
        break;
      case 'food_tried':
        icon = Icons.restaurant;
        color = Colors.orange;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _getActionText(Map<String, dynamic> data) {
    final userName = data['authorName'] ?? 'Bilinmeyen Kullanıcı';
    final actionType = data['actionType'];

    switch (actionType) {
      case 'journal_added':
        return '$userName yeni bir anı ekledi';
      case 'growth_record_added':
        return '$userName büyüme verisi girdi';
      case 'vaccine_completed':
        return '$userName bir aşıyı tamamladı';
      case 'milestone_completed':
        return '$userName bir gelişimi onayladı';
      case 'food_tried':
        return '$userName yeni bir gıdayı denetti';
      default:
        return '$userName bir işlem yaptı';
    }
  }
}
