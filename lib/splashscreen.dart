import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'auth_wrapper.dart';
import 'petal_animation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Petal> _petals = [];
  final math.Random _random = math.Random();
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(_updatePetals)
          ..repeat();
  }

  void _navigateToAuthWrapper() {
    setState(() => _showUI = false);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AuthWrapper(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1500),
        ),
      );
    });
  }

  void _updatePetals() {
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
  }

  @override
  void dispose() {
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
          Container(color: Colors.black.withValues(alpha: 0.05)),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: PetalPainter(_petals),
                  child: Container(),
                );
              },
            ),
          ),

          SafeArea(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _showUI ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    const Spacer(flex: 18),
                    const Text(
                      'Minik Adımlar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF5D4037),
                        fontSize: 46,
                        fontWeight: FontWeight.w400,

                        letterSpacing: 2.0,

                        shadows: [
                          Shadow(
                            color: Colors.white70,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Her adımda sevgi, her dokunuşta bir gelecek...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8B5E3C),
                        fontSize: 18,
                        fontWeight: FontWeight.w400,

                        shadows: [Shadow(color: Colors.white54, blurRadius: 4)],
                      ),
                    ),
                    const Spacer(flex: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _navigateToAuthWrapper,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D4037),
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'BAŞLAYALIM',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
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
