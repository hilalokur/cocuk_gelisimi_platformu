import 'package:flutter/material.dart';
import 'dart:ui';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Yardım ve Destek', 
          style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF5D4037),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/bg1.png',
              fit: BoxFit.cover,
            ),
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
                _buildFaqItem(
                  'Bakıcı nasıl eklerim?',
                  'Profil sekmesinden "Bakıcı Yönetimi" kısmına giderek, bakıcınızın e-posta adresini girip davet edebilirsiniz.',
                ),
                _buildFaqItem(
                  'Fotoğraflarımı kimler görebilir?',
                  'Günlük kısmındaki fotoğrafları "Özel" olarak işaretlerseniz sadece siz görebilirsiniz. İşaretlemezseniz yetkili bakıcınız da görebilir.',
                ),
                _buildFaqItem(
                  'Aşı takvimi nasıl çalışır?',
                  'Bebeğinizin doğum tarihine göre Sağlık Bakanlığı aşı takvimi otomatik oluşturulur. Tamamlanan aşıları işaretleyerek takip edebilirsiniz.',
                ),
                const SizedBox(height: 30),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Bize Ulaşın',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D4037), fontFamily: 'serif', fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: const Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.email_outlined, color: Color(0xFF5D4037)),
                        title: Text('destek@minikadimlar.com', style: TextStyle(fontFamily: 'serif')),
                      ),
                      ListTile(
                        leading: Icon(Icons.language, color: Color(0xFF5D4037)),
                        title: Text('www.minikadimlar.com', style: TextStyle(fontFamily: 'serif')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037), fontFamily: 'serif')),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: const TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}
