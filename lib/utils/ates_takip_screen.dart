import 'dart:ui';

import 'package:flutter/material.dart';

class AtesTakipScreen extends StatefulWidget {
  const AtesTakipScreen({super.key});

  @override
  State<AtesTakipScreen> createState() => _AtesTakipScreenState();
}

class _AtesTakipScreenState extends State<AtesTakipScreen> {
  final TextEditingController _atesController = TextEditingController();
  String _olcumYeri = 'Koltuk Altı';
  bool _isLoading = false;
  _FeverResult? _result;

  Future<void> _saglikBakanligiSistemSorgusu() async {
    final rawValue = _atesController.text.trim();
    final value = double.tryParse(rawValue.replaceAll(',', '.'));

    if (value == null) {
      setState(() {
        _result = const _FeverResult(
          title: 'Ölçüm okunamadı',
          status: 'Geçersiz değer',
          message: 'Ateş değerini 37.2 gibi sayısal biçimde girin.',
          color: Color(0xFFE28A3A),
          icon: Icons.info_rounded,
          rangeText: 'Ölçüm bekleniyor',
        );
      });
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final range = _referenceRangeFor(_olcumYeri);
    setState(() {
      _isLoading = false;
      _result = _buildResult(value, range);
    });
  }

  _FeverRange _referenceRangeFor(String place) {
    if (place == 'Kulaktan') {
      return const _FeverRange(low: 35.7, high: 37.5);
    }
    return const _FeverRange(low: 36.5, high: 37.0);
  }

  _FeverResult _buildResult(double value, _FeverRange range) {
    final rangeText =
        'Referans aralığı: ${range.low.toStringAsFixed(1)} - ${range.high.toStringAsFixed(1)} °C';

    if (value < range.low) {
      return _FeverResult(
        title: 'Düşük Ateş',
        status: '${value.toStringAsFixed(1)} °C',
        message:
            'Vücut ısısı referans aralığının altında. Ortamı sıcak tutup ölçümü yeniden takip edin.',
        color: const Color(0xFF6F9FE8),
        icon: Icons.ac_unit_rounded,
        rangeText: rangeText,
      );
    }

    if (value <= range.high) {
      return _FeverResult(
        title: 'Normal Seyir',
        status: '${value.toStringAsFixed(1)} °C',
        message:
            'Ateş değeri seçilen ölçüm bölgesi için normal aralıkta görünüyor.',
        color: const Color(0xFF4F9E86),
        icon: Icons.check_circle_rounded,
        rangeText: rangeText,
      );
    }

    if (value <= range.high + 1.0) {
      return _FeverResult(
        title: 'Hafif Ateş',
        status: '${value.toStringAsFixed(1)} °C',
        message:
            'Sınır değer aşılmış. Kıyafetleri gevşetin, sıvı desteği sağlayın ve ölçümü kısa süre sonra tekrarlayın.',
        color: const Color(0xFFE28A3A),
        icon: Icons.warning_amber_rounded,
        rangeText: rangeText,
      );
    }

    return _FeverResult(
      title: 'Yüksek Ateş',
      status: '${value.toStringAsFixed(1)} °C',
      message:
          'Kritik sınır aşılmış görünüyor. Çocuğu yakından izleyin ve gecikmeden sağlık uzmanına başvurun.',
      color: const Color(0xFFE57373),
      icon: Icons.emergency_rounded,
      rangeText: rangeText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFFDF7F2),
      appBar: AppBar(
        title: const Text(
          'Ateş Takibi',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0),
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
              child: Container(color: Colors.white.withValues(alpha: 0.36)),
            ),
          ),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                _HeroPanel(
                  selectedPlace: _olcumYeri,
                  onPlaceChanged: (value) {
                    setState(() {
                      _olcumYeri = value;
                      _result = null;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _InputPanel(
                  controller: _atesController,
                  isLoading: _isLoading,
                  onSubmit: _saglikBakanligiSistemSorgusu,
                ),
                const SizedBox(height: 14),
                _ResultPanel(
                  result: _result,
                  selectedPlace: _olcumYeri,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 14),
                const _ReferencePanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _atesController.dispose();
    super.dispose();
  }
}

class _HeroPanel extends StatelessWidget {
  final String selectedPlace;
  final ValueChanged<String> onPlaceChanged;

  const _HeroPanel({required this.selectedPlace, required this.onPlaceChanged});

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE57373).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.thermostat_rounded,
                  color: Color(0xFFE57373),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'T.C. Sağlık Bakanlığı',
                      style: TextStyle(
                        color: Color(0xFF8D7D75),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Ateş Referans Kontrolü',
                      style: TextStyle(
                        color: Color(0xFF3F312C),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Ölçüm bölgesini seçin, ateş değerini girin ve referans aralığına göre hızlı değerlendirme alın.',
            style: TextStyle(
              color: Color(0xFF6D5B52),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PlaceChip(
                  label: 'Koltuk Altı',
                  icon: Icons.accessibility_new_rounded,
                  selected: selectedPlace == 'Koltuk Altı',
                  onTap: () => onPlaceChanged('Koltuk Altı'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PlaceChip(
                  label: 'Kulaktan',
                  icon: Icons.hearing_rounded,
                  selected: selectedPlace == 'Kulaktan',
                  onTap: () => onPlaceChanged('Kulaktan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _InputPanel({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ölçüm Değeri',
            style: TextStyle(
              color: Color(0xFF3F312C),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Color(0xFF3F312C),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              hintText: '37.0',
              suffixText: '°C',
              prefixIcon: const Icon(
                Icons.thermostat_auto_rounded,
                color: Color(0xFF5D4037),
              ),
              filled: true,
              fillColor: const Color(0xFFFFFAF6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: const Color(0xFF5D4037).withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFF5D4037)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.verified_rounded),
              label: Text(
                isLoading ? 'Kontrol ediliyor' : 'Referansla Kontrol Et',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D4037),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFF5D4037,
                ).withValues(alpha: 0.55),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final _FeverResult? result;
  final String selectedPlace;
  final bool isLoading;

  const _ResultPanel({
    required this.result,
    required this.selectedPlace,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final current = result;
    final color = current?.color ?? const Color(0xFF8D7D75);

    return _GlassPanel(
      padding: const EdgeInsets.all(16),
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
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  current?.icon ?? Icons.health_and_safety_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current?.title ?? 'Sistem Yanıtı',
                      style: const TextStyle(
                        color: Color(0xFF3F312C),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      current?.status ?? 'Henüz ölçüm girilmedi',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isLoading
                ? 'Sağlık Bakanlığı referans aralığına göre kontrol ediliyor...'
                : current?.message ??
                      'Ateş değerini girip kontrol ettiğinizde sonuç burada gösterilir.',
            style: const TextStyle(
              color: Color(0xFF5D514B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(icon: Icons.place_rounded, label: selectedPlace),
              _InfoPill(
                icon: Icons.rule_rounded,
                label: current?.rangeText ?? 'Referans aralığı bekleniyor',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferencePanel extends StatelessWidget {
  const _ReferencePanel();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Referans Aralıkları',
            style: TextStyle(
              color: Color(0xFF3F312C),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          _ReferenceRow(label: 'Koltuk Altı', value: '36.5 - 37.0 °C'),
          SizedBox(height: 8),
          _ReferenceRow(label: 'Kulaktan', value: '35.7 - 37.5 °C'),
          SizedBox(height: 12),
          Text(
            'Bu ekran bilgilendirme amaçlıdır. Yüksek ateş, halsizlik veya farklı belirti varsa sağlık uzmanına başvurun.',
            style: TextStyle(
              color: Color(0xFF8D7D75),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassPanel({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A342B).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PlaceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF5D4037) : const Color(0xFFFFFAF6),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF5D4037),
                size: 18,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF5D4037),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7ECE4),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6D5B52)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6D5B52),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReferenceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6D5B52),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF3F312C),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _FeverRange {
  final double low;
  final double high;

  const _FeverRange({required this.low, required this.high});
}

class _FeverResult {
  final String title;
  final String status;
  final String message;
  final Color color;
  final IconData icon;
  final String rangeText;

  const _FeverResult({
    required this.title,
    required this.status,
    required this.message,
    required this.color,
    required this.icon,
    required this.rangeText,
  });
}
