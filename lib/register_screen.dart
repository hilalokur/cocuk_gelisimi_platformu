import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'petal_animation.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _showUI = true;
  bool _isLoading = false;
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
        if (_petals[i].y > 1.1 || _petals[i].x < -0.1 || _petals[i].x > 1.1)
          _petals.removeAt(i);
      }
    });
  }

  Future<void> _signUp() async {
    if (_isLoading) return;
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || surname.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Firestore'a kullanıcı bilgilerini kaydet
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'name': name,
              'surname': surname,
              'role': 'parent',
              'email': email,
              'profilePhotoUrl': '',
              'createdAt': FieldValue.serverTimestamp(),
            });

        await userCredential.user!.sendEmailVerification();
        if (mounted) Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = 'Hata oluştu.';
      if (e.code == 'email-already-in-use')
        message = 'Bu e-posta zaten kullanımda.';
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
                      'Kayıt Ol',
                      style: TextStyle(color: Color(0xFF5D4037), fontSize: 42),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Doğrulama maili alacaksınız',
                      style: TextStyle(color: Color(0xFF8B5E3C), fontSize: 14),
                    ),
                    const Spacer(flex: 2),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDF7).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            icon: Icons.person_outline,
                            hint: 'Adınız',
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _buildTextField(
                            controller: _surnameController,
                            icon: Icons.person_outline,
                            hint: 'Soyadınız',
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _buildTextField(
                            controller: _emailController,
                            icon: Icons.mail_outline,
                            hint: 'E-posta',
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _buildTextField(
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            hint: 'Şifre',
                            isPassword: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D4037),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Hesap Oluştur',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscureText,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black38),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
