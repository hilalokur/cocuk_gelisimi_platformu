import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerificationEmailPage extends StatefulWidget {
  const VerificationEmailPage({super.key});

  @override
  State<VerificationEmailPage> createState() => _VerificationEmailPageState();
}

class _VerificationEmailPageState extends State<VerificationEmailPage> {
  bool _isResending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

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

  Future<void> _resendVerificationEmail() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doğrulama e-postası tekrar gönderildi.'),
            ),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F2),
      body: Stack(
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Image.asset(
                'assets/bg1.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.42)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4A342B,
                            ).withValues(alpha: 0.08),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 74,
                            height: 74,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF1DCCB,
                              ).withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              size: 36,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'E-postanızı doğrulayın',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF3F312C),
                              fontSize: 24,
                              height: 1.12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            email == null
                                ? 'Doğrulama bağlantısını e-posta adresinize gönderdik.'
                                : '$email adresine gönderilen doğrulama bağlantısına tıklayın.',
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6D5B52),
                              fontSize: 13.5,
                              height: 1.42,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFFF5EE,
                              ).withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFF1DCCB),
                              ),
                            ),
                            child: const Text(
                              'Doğrulama tamamlandığında uygulama sizi otomatik olarak ana sayfaya yönlendirecek.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF8D7D75),
                                fontSize: 12.5,
                                height: 1.36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isResending
                                  ? null
                                  : _resendVerificationEmail,
                              icon: _isResending
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.mail_outline_rounded),
                              label: Text(
                                _isResending
                                    ? 'Gönderiliyor'
                                    : 'Doğrulama mailini tekrar gönder',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5D4037),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFF8B6E63,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => FirebaseAuth.instance.signOut(),
                            child: const Text(
                              'Farklı bir e-posta ile devam et',
                              style: TextStyle(
                                color: Color(0xFF5D4037),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
