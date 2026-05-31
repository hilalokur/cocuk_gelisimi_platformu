import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AlerjilerScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const AlerjilerScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<AlerjilerScreen> createState() => _AlerjilerScreenState();
}

class _AlerjilerScreenState extends State<AlerjilerScreen> {
  static const officialAllergens = [
    'Gluten içeren tahıllar',
    'Kabuklular ve ürünleri',
    'Yumurta ve yumurta ürünleri',
    'Balık ve balık ürünleri',
    'Yerfıstığı ve ürünleri',
    'Soya fasulyesi ve ürünleri',
    'Süt ve süt ürünleri',
    'Sert kabuklu meyveler',
    'Kereviz ve ürünleri',
    'Hardal ve ürünleri',
    'Susam tohumu ve ürünleri',
    'Kükürt dioksit ve sülfitler',
    'Acı bakla ve ürünleri',
    'Yumuşakçalar ve ürünleri',
  ];

  final Set<String> _selected = {};
  final _customController = TextEditingController();
  final _noteController = TextEditingController();
  final _doctorNoteController = TextEditingController();
  DateTime? _diagnosisDate;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _customController.dispose();
    _noteController.dispose();
    _doctorNoteController.dispose();
    super.dispose();
  }

  void _load(Map<String, dynamic> data) {
    if (_loaded) return;
    _selected
      ..clear()
      ..addAll(
        (data['allergiesOfficial'] as List?)?.whereType<String>() ??
            (data['allergies'] as List?)?.whereType<String>() ??
            const [],
      );
    _customController.text =
        (data['allergiesCustom'] ?? data['allergiesOther'] ?? '') as String;
    _noteController.text = (data['allergyNote'] ?? '') as String;
    _doctorNoteController.text = (data['allergyDoctorNote'] ?? '') as String;
    final rawDate = data['allergyDiagnosedAt'];
    if (rawDate is Timestamp) _diagnosisDate = rawDate.toDate();
    _loaded = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .collection('children')
        .doc(widget.childId)
        .set({
          'allergiesOfficial': _selected.toList(),
          'allergiesCustom': _customController.text.trim(),
          'allergyNote': _noteController.text.trim(),
          'allergyDiagnosedAt': _diagnosisDate == null
              ? null
              : Timestamp.fromDate(_diagnosisDate!),
          'allergyDoctorNote': _doctorNoteController.text.trim(),
          'allergies': _selected.toList(),
          'allergiesOther': _customController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerji bilgileri kaydedildi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('children')
          .doc(widget.childId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        if (data != null) _load(data);

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: const Color(0xFFFDF7F2),
          appBar: AppBar(
            title: const Text(
              'Alerjiler',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: const Color(0xFF3F312C),
          ),
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
              SafeArea(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  children: [
                    _GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sağlık Bilgileri > Alerjiler',
                            style: TextStyle(
                              color: const Color(0xFF8D7D75),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.childName,
                            style: const TextStyle(
                              color: Color(0xFF3F312C),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Resmi alerjen listesinden birden fazla madde seçebilir, ek not ve doktor bilgisini saklayabilirsiniz.',
                            style: TextStyle(
                              color: Color(0xFF6D5B52),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alerjiye veya intoleransa neden olan maddeler',
                            style: TextStyle(
                              color: Color(0xFF3F312C),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: officialAllergens.map((item) {
                              final selected = _selected.contains(item);
                              return FilterChip(
                                label: Text(item),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    selected
                                        ? _selected.remove(item)
                                        : _selected.add(item);
                                  });
                                },
                                selectedColor: const Color(
                                  0xFF5D4037,
                                ).withValues(alpha: 0.16),
                                checkmarkColor: const Color(0xFF5D4037),
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.86,
                                ),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? const Color(0xFF5D4037)
                                      : const Color(0xFF6D5B52),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _GlassPanel(
                      child: Column(
                        children: [
                          _Field(
                            controller: _customController,
                            label: 'Kendi alerjisini yaz',
                            icon: Icons.edit_note_rounded,
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _noteController,
                            label: 'Alerji notu',
                            icon: Icons.notes_rounded,
                            minLines: 2,
                          ),
                          const SizedBox(height: 12),
                          _DateTile(
                            date: _diagnosisDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _diagnosisDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _diagnosisDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _doctorNoteController,
                            label: 'Doktor notu',
                            icon: Icons.medical_information_rounded,
                            minLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text(
                          'Kaydet',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D4037),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
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

class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int minLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.minLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines + 2,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF5D4037)),
        filled: true,
        fillColor: const Color(0xFFFFFAF6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _DateTile({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFAF6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.event_rounded, color: Color(0xFF5D4037)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  date == null
                      ? 'Alerji teşhis tarihi'
                      : '${date!.day}.${date!.month}.${date!.year}',
                  style: const TextStyle(
                    color: Color(0xFF3F312C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
