import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'petal_animation.dart';

class VerificationEmailPage extends StatefulWidget {
  const VerificationEmailPage({super.key});

  @override
  State<VerificationEmailPage> createState() => _VerificationEmailPageState();
}

class _VerificationEmailPageState extends State<VerificationEmailPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Petal> _petals = [];
  final math.Random _random = math.Random();
  bool _showUI = true;
  bool _isResending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        _updatePetals();
      })
    ..repeat();

    // 3 saniyede bir kullanıcının reload edilerek emailVerified durumunun kontrol edilmesi
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerified();
    });
  }

  Future<void> _checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload(); // Firebase sunucusundan güncel durumu çek
      if (user.emailVerified) {
        _timer?.cancel();
        // AuthWrapper otomatik olarak HomeScreen'e geçirecek, bizim bir şey yapmamıza gerek yok.
      }
    }
  }

  void _updatePetals() {
    if (!mounted) return;
    setState(() {
      if (_petals.length < 25 && _random.nextDouble() < 0.05) {
        _petals.add(Petal(
          x: 0.5,
          y: 0.11,
          size: _random.nextDouble() * 4 + 2,
          velocity: _random.nextDouble() * 0.001 + 0.0005,
          drift: (_random.nextDouble() - 0.5) * 0.003,
          rotation: _random.nextDouble() * math.pi * 2,
          spin: (_random.nextDouble() - 0.5) * 0.05,
        ));
      }

      for (var i = _petals.length - 1; i >= 0; i--) {
        _petals[i].y += _petals[i].velocity;
        _petals[i].x += _petals[i].drift;
        _petals[i].rotation += _petals[i].spin;

        if (_petals[i].y > 1.1 || _petals[i].x < -0.1 || _petals[i].x > 1.1) {
          _petals.removeAt(i);
        }
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doğrulama e-postası tekrar gönderildi.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-posta gönderilirken hata oluştu.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg1.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.1)),
          
          CustomPaint(
            painter: PetalPainter(_petals),
            child: Container(),
          ),

          SafeArea(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showUI ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Column(
                  children: [
                    const Spacer(flex: 10),
                    const Icon(Icons.mark_email_read_outlined, size: 80, color: Color(0xFF5D4037)),
                    const SizedBox(height: 20),
                    const Text(
                      'Mailinizi Kontrol Ediniz',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF5D4037),
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Lütfen e-posta adresinize gönderilen doğrulama linkine tıklayın. Onayladıktan sonra otomatik olarak yönlendirileceksiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8B5E3C),
                        fontSize: 14,
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(flex: 2),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _resendVerificationEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D4037),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isResending 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text(
                              'Maili Tekrar Gönder',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: const Text(
                        'Farklı bir e-posta ile kayıt ol',
                        style: TextStyle(
                          color: Color(0xFF8B5E3C),
                          decoration: TextDecoration.underline,
                          fontFamily: 'serif',
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const Spacer(flex: 4),
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
