import 'package:flutter/material.dart';
import 'dart:ui';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _vaccineReminders = true;
  bool _developmentMilestones = true;
  bool _dailyTips = true;
  bool _activityUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Bildirim Ayarları',
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
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSwitchTile(
                  title: 'Aşı Hatırlatıcıları',
                  subtitle: 'Yaklaşan aşılar için bildirim al.',
                  value: _vaccineReminders,
                  onChanged: (val) => setState(() => _vaccineReminders = val),
                ),
                _buildSwitchTile(
                  title: 'Gelişim Kontrolleri',
                  subtitle: 'Bebeğinizin yeni becerileri için hatırlatmalar.',
                  value: _developmentMilestones,
                  onChanged: (val) =>
                      setState(() => _developmentMilestones = val),
                ),
                _buildSwitchTile(
                  title: 'Günlük İpuçları',
                  subtitle: 'Her gün bebeğinize özel tavsiyeler.',
                  value: _dailyTips,
                  onChanged: (val) => setState(() => _dailyTips = val),
                ),
                _buildSwitchTile(
                  title: 'Aktivite Güncellemeleri',
                  subtitle: 'Bakıcınız veri girdiğinde haberdar olun.',
                  value: _activityUpdates,
                  onChanged: (val) => setState(() => _activityUpdates = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.brown.shade400, fontSize: 13),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF5D4037),
      ),
    );
  }
}
