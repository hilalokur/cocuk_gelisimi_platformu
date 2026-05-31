import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'petal_animation.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _showUI = true;

  late AnimationController _controller;
  final List<Petal> _petals = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            _updatePetals();
          })
          ..repeat();
  }

  void _updatePetals() {
    if (!mounted) return;
    setState(() {
      if (_petals.length < 25 && _random.nextDouble() < 0.05) {
        _petals.add(
          Petal(
            x: 0.5,
            y: 0.11,
            size: _random.nextDouble() * 4 + 2,
            velocity: _random.nextDouble() * 0.001 + 0.0005,
            drift: (_random.nextDouble() - 0.5) * 0.003,
            rotation: _random.nextDouble() * math.pi * 2,
            spin: (_random.nextDouble() - 0.5) * 0.05,
          ),
        );
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

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen e-posta adresinizi girin.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre sıfırlama bağlantısı gönderildi.'),
          ),
        );
        // Login ekranına dön
        final nav = Navigator.of(context);
        setState(() => _showUI = false);
        Future.delayed(const Duration(milliseconds: 350), () => nav.pop());
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? 'Hata oluştu')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
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

          CustomPaint(painter: PetalPainter(_petals), child: Container()),

          SafeArea(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showUI ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFF5D4037),
                        ),
                        onPressed: () {
                          final nav = Navigator.of(context);
                          setState(() => _showUI = false);
                          Future.delayed(
                            const Duration(milliseconds: 350),
                            () => nav.pop(),
                          );
                        },
                      ),
                    ),
                    const Spacer(flex: 10),
                    const Text(
                      'Şifre Sıfırlama',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF5D4037),
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8B5E3C), fontSize: 14),
                    ),
                    const Spacer(flex: 2),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDF7).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _emailController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.mail_outline,
                              color: Colors.black38,
                              size: 20,
                            ),
                          ),
                          hintText: 'E-posta adresiniz',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.black38,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D4037),
                          foregroundColor: Colors.white,
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
                                'Bağlantı Gönder',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
