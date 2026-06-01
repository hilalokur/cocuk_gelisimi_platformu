import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

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
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
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
      if (!mounted) return;
      setState(() => _isLoading = false);
      var message = 'Hata oluştu.';
      if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta zaten kullanımda.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isShort = constraints.maxHeight < 760;

          return Padding(
            padding: EdgeInsets.fromLTRB(28, isShort ? 235 : 330, 28, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _BackButton(),
                const SizedBox(height: 14),
                const _AuthHeader(
                  title: 'Kayıt Oluştur',
                  description:
                      'Hesabınızı oluşturun, doğrulama bağlantısını e-postanıza gönderelim.',
                ),
                SizedBox(height: isShort ? 22 : 30),
                _InputGroup(
                  children: [
                    _AuthTextField(
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      hint: 'Adınız',
                      textInputAction: TextInputAction.next,
                    ),
                    const _InputDivider(),
                    _AuthTextField(
                      controller: _surnameController,
                      icon: Icons.person_outline_rounded,
                      hint: 'Soyadınız',
                      textInputAction: TextInputAction.next,
                    ),
                    const _InputDivider(),
                    _AuthTextField(
                      controller: _emailController,
                      icon: Icons.mail_outline_rounded,
                      hint: 'E-posta adresiniz',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const _InputDivider(),
                    _AuthTextField(
                      controller: _passwordController,
                      icon: Icons.lock_outline_rounded,
                      hint: 'Şifreniz',
                      obscureText: _obscureText,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF8A7A72),
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _PrimaryButton(
                  label: 'Hesap Oluştur',
                  isLoading: _isLoading,
                  onPressed: _signUp,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg1.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00FFF8F0),
                  Color(0x22FFF8F0),
                  Color(0xF7FFF8F0),
                  Color(0xFFFFF8F0),
                ],
                stops: [0.0, 0.34, 0.52, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF5D4037),
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFF4E2F27),
              fontSize: 32,
              fontWeight: FontWeight.w500,
              height: 1.05,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF74665F),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.32,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _InputGroup extends StatelessWidget {
  const _InputGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A4A37).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InputDivider extends StatelessWidget {
  const _InputDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 54,
      endIndent: 18,
      color: Color(0xFFE5D8CF),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType,
    this.textInputAction = TextInputAction.done,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        style: const TextStyle(
          color: Color(0xFF4E3B35),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF8A7A72), size: 20),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF9B8F89),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7A4C3D), Color(0xFF4E2E26)],
          ),
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A3328).withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded, size: 24),
                  ],
                ),
        ),
      ),
    );
  }
}
