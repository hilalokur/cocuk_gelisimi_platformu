import 'package:flutter/material.dart';
import 'dart:ui';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Gizlilik ve Güvenlik', 
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Veri Gizliliği Taahhüdümüz',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Minik Adımlar olarak, çocuğunuzun ve ailenizin verilerinin güvenliğini en ön planda tutuyoruz. Paylaştığınız tüm fotoğraflar ve sağlık kayıtları güvenli sunucularımızda şifrelenmiş olarak saklanır.',
                      style: TextStyle(height: 1.6, fontFamily: 'serif', fontStyle: FontStyle.italic),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Hangi Verileri Topluyoruz?',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037), fontFamily: 'serif'),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '• Çocuğunuzun adı ve doğum tarihi (gelişim takibi için).\n'
                      '• Boy ve kilo verileri (büyüme grafikleri için).\n'
                      '• Aşı ve sağlık kayıtları.\n'
                      '• Profil ve aile fotoğrafları.',
                      style: TextStyle(height: 1.6, fontFamily: 'serif'),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Veri Paylaşımı',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037), fontFamily: 'serif'),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Verileriniz asla üçüncü şahıslarla paylaşılmaz veya reklam amaçlı kullanılmaz. Bakıcı erişimi sadece sizin onayınızla ve kısıtlı yetkilerle sağlanır.',
                      style: TextStyle(height: 1.6, fontFamily: 'serif', fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
