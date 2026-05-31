import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'petal_animation.dart';
import 'register_screen.dart';
import 'passwordreset.dart';
import 'otp_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _obscureText = true;
  bool _rememberMe = false;
  bool _showUI = true;
  bool _isLoading = false;
  int _selectedUserType = 0; // 0: Ebeveyn, 1: Bakıcı

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

  Future<void> _handleLogin() async {
    if (_selectedUserType == 0) {
      await _loginWithEmail();
    } else {
      await _loginWithPhone();
    }
  }

  Future<void> _loginWithEmail() async {
    if (_isLoading) return;
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen e-posta ve şifrenizi girin.')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String message = 'Giriş başarısız.';

      switch (e.code) {
        case 'user-not-found':
          message = 'Kullanıcı bulunamadı.';
          break;
        case 'wrong-password':
          message = 'Hatalı şifre.';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi.';
          break;
        case 'user-disabled':
          message = 'Bu hesap devre dışı bırakılmış.';
          break;
        case 'too-many-requests':
          message =
              'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
          break;
        case 'invalid-credential':
          message = 'E-posta veya şifre hatalı.';
          break;
        case 'network-request-failed':
          message = 'İnternet bağlantınızı kontrol edin.';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beklenmedik bir hata oluştu.')),
        );
      }
    }
  }

  Future<void> _loginWithPhone() async {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen telefon numaranızı girin.')),
      );
      return;
    }

    // Numara formatı kontrolü (Firebase + ülke kodu bekler)
    if (!phone.startsWith('+')) phone = '+90$phone';

    setState(() => _isLoading = true);

    // Yetki Kontrolü: Bu numara bir bakıcı olarak eklenmiş mi?
    try {
      final query = await FirebaseFirestore.instance
          .collection('caregivers')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bu numara ile kayıtlı bir bakıcı daveti bulunamadı.',
              ),
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Doğrulama hatası: ${e.message}')),
            );
            setState(() => _isLoading = false);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPScreen(
                  verificationId: verificationId,
                  phoneNumber: phone,
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
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

          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: PetalPainter(_petals),
                child: Container(),
              );
            },
          ),

          SafeArea(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showUI ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Column(
                  children: [
                    const Spacer(flex: 16),
                    const Text(
                      'Minik Adımlar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF5D4037),
                        fontSize: 42,
                        fontWeight: FontWeight.w400,

                        letterSpacing: 1.8,
                        shadows: [
                          Shadow(
                            color: Colors.white70,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    _buildUserTypeSelector(),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDF7).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _selectedUserType == 0
                          ? Column(
                              children: [
                                _buildTextField(
                                  controller: _emailController,
                                  icon: Icons.mail_outline,
                                  hint: 'E-posta adresiniz',
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 20,
                                  endIndent: 20,
                                  color: Colors.black12,
                                ),
                                _buildTextField(
                                  controller: _passwordController,
                                  icon: Icons.lock_outline,
                                  hint: 'Şifreniz',
                                  isPassword: true,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.black38,
                                      size: 18,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureText = !_obscureText,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _buildTextField(
                              controller: _phoneController,
                              icon: Icons.phone_android_outlined,
                              hint: '5xx xxx xx xx',
                              isPhone: true,
                            ),
                    ),

                    if (_selectedUserType == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: const Color(0xFF5D4037),
                                    side: const BorderSide(
                                      color: Color(0xFF8B5E3C),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (value) =>
                                        setState(() => _rememberMe = value!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Beni Hatırla',
                                  style: TextStyle(
                                    color: Color(0xFF8B5E3C),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                if (!mounted) return;
                                final navigator = Navigator.of(context);
                                setState(() => _showUI = false);
                                Future.delayed(
                                  const Duration(milliseconds: 350),
                                  () {
                                    if (!mounted) return;
                                    navigator
                                        .push(
                                          PageRouteBuilder(
                                            pageBuilder:
                                                (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                ) => const PasswordResetPage(),
                                            transitionsBuilder:
                                                (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                  child,
                                                ) {
                                                  return FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  );
                                                },
                                            transitionDuration: const Duration(
                                              milliseconds: 700,
                                            ),
                                          ),
                                        )
                                        .then((_) {
                                          if (mounted)
                                            setState(() => _showUI = true);
                                        });
                                  },
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                              ),
                              child: const Text(
                                'Şifremi unuttum?',
                                style: TextStyle(
                                  color: Color(0xFF8B5E3C),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(top: 12, bottom: 8),
                        child: Text(
                          'Sadece ebeveyn tarafından davet edilen bakıcılar giriş yapabilir.',
                          style: TextStyle(
                            color: Color(0xFF8B5E3C),
                            fontSize: 11,
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
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
                            : Text(
                                _selectedUserType == 0
                                    ? 'Giriş Yap'
                                    : 'Kodu Gönder',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    if (_selectedUserType == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Hesabınız yok mu? ',
                              style: TextStyle(
                                color: Color(0xFF8B5E3C),
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (!mounted) return;
                                final navigator = Navigator.of(context);
                                setState(() => _showUI = false);
                                Future.delayed(
                                  const Duration(milliseconds: 350),
                                  () {
                                    if (!mounted) return;
                                    navigator
                                        .push(
                                          PageRouteBuilder(
                                            pageBuilder:
                                                (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                ) => const SignUpPage(),
                                            transitionsBuilder:
                                                (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                  child,
                                                ) {
                                                  return FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  );
                                                },
                                            transitionDuration: const Duration(
                                              milliseconds: 700,
                                            ),
                                          ),
                                        )
                                        .then((_) {
                                          if (mounted)
                                            setState(() => _showUI = true);
                                        });
                                  },
                                );
                              },
                              child: const Text(
                                'Kayıt Ol',
                                style: TextStyle(
                                  color: Color(0xFF5D4037),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Container(
      width: 260,
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5E6).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            alignment: _selectedUserType == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width: 124,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5E3C),
                borderRadius: BorderRadius.circular(19),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedUserType = 0),
                  child: Center(
                    child: Text(
                      'Ebeveyn',
                      style: TextStyle(
                        color: _selectedUserType == 0
                            ? Colors.white
                            : Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedUserType = 1),
                  child: Center(
                    child: Text(
                      'Bakıcı',
                      style: TextStyle(
                        color: _selectedUserType == 1
                            ? Colors.white
                            : Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
    bool isPhone = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscureText,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(icon, color: Colors.black38, size: 20),
        ),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
