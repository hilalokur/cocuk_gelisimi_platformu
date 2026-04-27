import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'providers/child_provider.dart';
import 'utils/pdf_export_service.dart';

class BoyKiloScreen extends StatefulWidget {
  final String childId;
  const BoyKiloScreen({super.key, required this.childId});

  @override
  State<BoyKiloScreen> createState() => _BoyKiloScreenState();
}

class _BoyKiloScreenState extends State<BoyKiloScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final userRole = userData?['role'] ?? 'parent';
        final userName = userData?['name'] ?? (userRole == 'bakici' ? 'Bakıcı' : 'Ebeveyn');

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Boy & Kilo Takibi', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: const Color(0xFF5D4037),
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF5D4037),
              indicatorColor: const Color(0xFF5D4037),
              tabs: const [Tab(text: 'Geçmiş'), Tab(text: 'Grafik')],
            ),
          ),
          body: Stack(
            children: [
              Positioned.fill(child: Image.asset('assets/bg1.png', fit: BoxFit.cover)),
              Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.white24))),
              SafeArea(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('growth_records')
                      .where('childId', isEqualTo: widget.childId)
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

                    final records = snapshot.data!.docs;
                    final latestRecord = records.first.data() as Map<String, dynamic>;

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        Column(
                          children: [
                            _buildLatestStats(latestRecord),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: records.length,
                                itemBuilder: (context, index) => _buildRecordCard(records[index].data() as Map<String, dynamic>, records[index].id, userRole),
                              ),
                            ),
                          ],
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildChartCard('Boy (cm)', records, 'height', Colors.blue),
                              const SizedBox(height: 20),
                              _buildChartCard('Kilo (kg)', records, 'weight', Colors.orange),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: userRole == 'bakici' ? null : FloatingActionButton(
            onPressed: () => _showAddRecordDialog(context, userName, userRole),
            backgroundColor: const Color(0xFF5D4037),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      }
    );
  }

  Widget _buildLatestStats(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(25)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.height, '${data['height']}', 'cm', 'Boy'),
          _statItem(Icons.monitor_weight, '${data['weight']}', 'kg', 'Kilo'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String unit, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF5D4037)),
        Text('$value $unit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> data, String docId, String userRole) {
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white70,
      child: ListTile(
        title: Text(DateFormat('dd.MM.yyyy').format(date)),
        subtitle: Text('Boy: ${data['height']} cm, Kilo: ${data['weight']} kg'),
        trailing: userRole == 'bakici' ? null : IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('growth_records').doc(docId).delete()),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text('Kayıt bulunamadı.'));

  void _showAddRecordDialog(BuildContext context, String userName, String userRole) {
    final hController = TextEditingController();
    final wController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Ölçüm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: hController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Boy (cm)')),
            TextField(controller: wController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kilo (kg)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (hController.text.isNotEmpty && wController.text.isNotEmpty) {
                final height = double.tryParse(hController.text) ?? 0;
                final weight = double.tryParse(wController.text) ?? 0;

                await FirebaseFirestore.instance.collection('growth_records').add({
                  'childId': widget.childId,
                  'date': FieldValue.serverTimestamp(),
                  'height': height,
                  'weight': weight,
                });

                // Add to Activity Log
                await FirebaseFirestore.instance.collection('activity_log').add({
                  'childId': widget.childId,
                  'actionType': 'growth_record_added',
                  'authorName': userName,
                  'userRole': userRole,
                  'timestamp': FieldValue.serverTimestamp(),
                  'details': 'Boy: $height cm, Kilo: $weight kg',
                });

                Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, List<QueryDocumentSnapshot> docs, String field, Color color) {
    final spots = docs.reversed.indexed.map((e) => FlSpot(e.$1.toDouble(), (e.$2.data() as Map<String, dynamic>)[field]?.toDouble() ?? 0)).toList();
    return Container(
      height: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white60, borderRadius: BorderRadius.circular(20)),
      child: LineChart(LineChartData(lineBarsData: [LineChartBarData(spots: spots, color: color, isCurved: true)])),
    );
  }
}
