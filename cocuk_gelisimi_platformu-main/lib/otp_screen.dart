import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'petal_animation.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPScreen({super.key, required this.verificationId, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _controller;
  final List<Petal> _petals = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..addListener(() => _updatePetals())..repeat();
  }

  void _updatePetals() {
    if (!mounted) return;
    setState(() {
      if (_petals.length < 25 && _random.nextDouble() < 0.05) {
        _petals.add(Petal(x: 0.5, y: 0.11, size: _random.nextDouble() * 4 + 2, velocity: _random.nextDouble() * 0.001 + 0.0005, drift: (_random.nextDouble() - 0.5) * 0.003, rotation: _random.nextDouble() * math.pi * 2, spin: (_random.nextDouble() - 0.5) * 0.05));
      }
      for (var i = _petals.length - 1; i >= 0; i--) {
        _petals[i].y += _petals[i].velocity;
        _petals[i].x += _petals[i].drift;
        _petals[i].rotation += _petals[i].spin;
        if (_petals[i].y > 1.1 || _petals[i].x < -0.1 || _petals[i].x > 1.1) _petals.removeAt(i);
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length < 6) return;
    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Bakıcı bilgilerini kontrol et ve users koleksiyonuna işle
        final caregiverDoc = await FirebaseFirestore.instance
            .collection('caregivers')
            .where('phone', isEqualTo: widget.phoneNumber)
            .limit(1)
            .get();

        if (caregiverDoc.docs.isNotEmpty) {
          final data = caregiverDoc.docs.first.data();
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'role': 'bakici',
            'parentId': data['parentId'],
            'phone': widget.phoneNumber,
            'name': data['name'] ?? 'Bakıcı',
            'status': 'active',
          }, SetOptions(merge: true));
        }
      }

      if (mounted) Navigator.of(context).pop(); 
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hatalı kod girdiniz.')));
      setState(() => _isLoading = false);
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
          Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/bg1.png'), fit: BoxFit.cover, alignment: Alignment.topCenter))),
          Container(color: Colors.black.withValues(alpha: 0.1)),
          CustomPaint(painter: PetalPainter(_petals), child: Container()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Column(
                children: [
                  Align(alignment: Alignment.topLeft, child: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5D4037)), onPressed: () => Navigator.pop(context))),
                  const Spacer(flex: 10),
                  const Text('Doğrulama', style: TextStyle(color: Color(0xFF5D4037), fontSize: 32, fontStyle: FontStyle.italic, fontFamily: 'serif')),
                  const SizedBox(height: 10),
                  Text('${widget.phoneNumber} numarasına gelen kodu giriniz.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8B5E3C), fontSize: 14, fontStyle: FontStyle.italic, fontFamily: 'serif')),
                  const Spacer(flex: 2),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFFFFDF7).withValues(alpha: 0.95), borderRadius: BorderRadius.circular(20)),
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, fontStyle: FontStyle.italic, fontFamily: 'serif'),
                      decoration: const InputDecoration(
                        hintText: '000000',
                        hintStyle: TextStyle(fontStyle: FontStyle.italic, fontFamily: 'serif', letterSpacing: 8),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _verifyOTP, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Onayla', style: TextStyle(fontStyle: FontStyle.italic, fontFamily: 'serif', fontWeight: FontWeight.bold)))),
                  const Spacer(flex: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
