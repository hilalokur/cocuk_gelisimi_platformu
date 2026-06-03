import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'passwordreset.dart';
import 'register_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _obscureText = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  int _selectedUserType = 0; // 0: Ebeveyn, 1: Bakıcı

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
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beklenmedik bir hata oluştu.')),
      );
    }
  }

  Future<void> _loginWithPhone() async {
    var phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen telefon numaranızı girin.')),
      );
      return;
    }

    if (!phone.startsWith('+')) phone = '+90$phone';

    setState(() => _isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('caregivers')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bu numara ile kayıtlı bir bakıcı daveti bulunamadı.',
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final inviteDoc = query.docs.first;
      final inviteData = inviteDoc.data();
      final credential = await FirebaseAuth.instance.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'anonymous-login-failed',
          message: 'Bakıcı oturumu açılamadı.',
        );
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': 'bakici',
        'parentId': inviteData['parentId'],
        'phone': phone,
        'name': inviteData['name'] ?? 'Bakıcı',
        'status': 'active',
        'caregiverInviteId': inviteDoc.id,
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await inviteDoc.reference.set({
        'status': 'active',
        'caregiverUid': user.uid,
        'acceptedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bakıcı girişi yapılamadı: $e')));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isShort = constraints.maxHeight < 760;

          return Stack(
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
                          constraints.maxHeight -
                          MediaQuery.paddingOf(context).vertical,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        28,
                        isShort ? 265 : 360,
                        28,
                        24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const _LoginBrand(),
                          SizedBox(height: isShort ? 22 : 30),
                          _buildUserTypeSelector(),
                          const SizedBox(height: 20),
                          _buildInputGroup(),
                          const SizedBox(height: 14),
                          _selectedUserType == 0
                              ? _buildEmailActions()
                              : const _CaregiverNote(),
                          const SizedBox(height: 22),
                          _buildLoginButton(),
                          if (_selectedUserType == 0) ...[
                            const SizedBox(height: 22),
                            _buildRegisterLink(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [_buildUserTab('Ebeveyn', 0), _buildUserTab('Bakıcı', 1)],
      ),
    );
  }

  Widget _buildUserTab(String label, int index) {
    final selected = _selectedUserType == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selectedUserType = index),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF754A3D)
                      : const Color(0xFF7F6F67),
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF8B5E3C)
                      : const Color(0xFFE7DCD4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputGroup() {
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
      child: _selectedUserType == 0
          ? Column(
              children: [
                _buildTextField(
                  controller: _emailController,
                  icon: Icons.mail_outline_rounded,
                  hint: 'E-posta adresiniz',
                ),
                const Divider(
                  height: 1,
                  indent: 54,
                  endIndent: 18,
                  color: Color(0xFFE5D8CF),
                ),
                _buildTextField(
                  controller: _passwordController,
                  icon: Icons.lock_outline_rounded,
                  hint: 'Şifreniz',
                  isPassword: true,
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
            )
          : _buildTextField(
              controller: _phoneController,
              icon: Icons.phone_iphone_rounded,
              hint: '+905xxx...',
              isPhone: true,
            ),
    );
  }

  Widget _buildEmailActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: const Color(0xFF754A3D),
                    side: const BorderSide(
                      color: Color(0xFF8B5E3C),
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: (value) =>
                        setState(() => _rememberMe = value ?? false),
                  ),
                ),
                const SizedBox(width: 9),
                const Text(
                  'Beni Hatırla',
                  style: TextStyle(
                    color: Color(0xFF754A3D),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PasswordResetPage()),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Şifremi unuttum?',
            style: TextStyle(
              color: Color(0xFF754A3D),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
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
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
          ),
          child: _isLoading
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
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Giriş Yap',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded, size: 26),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SignUpPage()));
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Henüz hesabınız yok mu?  ',
                style: TextStyle(
                  color: Color(0xFF8A7A72),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                'Kayıt Oluştur',
                style: TextStyle(
                  color: Color(0xFF4E2E26),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF754A3D),
                size: 18,
              ),
            ],
          ),
        ),
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
    return SizedBox(
      height: 58,
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscureText,
        keyboardType: isPhone
            ? TextInputType.phone
            : TextInputType.emailAddress,
        textInputAction: isPassword || isPhone
            ? TextInputAction.done
            : TextInputAction.next,
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
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

class _LoginBrand extends StatelessWidget {
  const _LoginBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Minik Adımlar',
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              color: Color(0xFF4E2F27),
              fontSize: 36,
              fontWeight: FontWeight.w500,
              height: 1.05,
              letterSpacing: 0,
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Çocuğunuzun gelişimini\nsevgiyle ve güvenle takip edin.',
          textAlign: TextAlign.center,
          style: TextStyle(
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

class _CaregiverNote extends StatelessWidget {
  const _CaregiverNote();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Sadece ebeveyn tarafından davet edilen bakıcılar giriş yapabilir.',
        style: TextStyle(
          color: Color(0xFF754A3D),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.3,
        ),
      ),
    );
  }
}
