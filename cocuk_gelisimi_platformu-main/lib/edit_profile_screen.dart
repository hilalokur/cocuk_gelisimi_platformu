import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'utils/image_upload.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final _passwordController = TextEditingController();
  String? _profilePhotoUrl;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _profilePhotoUrl = widget.userData['profilePhotoUrl'];
    _nameController = TextEditingController(text: widget.userData['name']);
    _emailController = TextEditingController(text: FirebaseAuth.instance.currentUser?.email);
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? FirebaseAuth.instance.currentUser?.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    setState(() => _isLoading = true);
    try {
      final url = await ImageUploadUtils.pickAndUploadImage();
      if (url != null) {
        setState(() {
          _profilePhotoUrl = url;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf yükleme hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profilePhotoUrl': _profilePhotoUrl ?? '',
      });

      // 2. Update Auth Email if changed
      if (_emailController.text.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-posta doğrulama bağlantısı gönderildi. Lütfen onaylayın.')),
          );
        }
      }

      // 3. Update Password if entered
      if (_passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Şifre başarıyla güncellendi.')),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi.')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Bir hata oluştu';
      if (e.code == 'requires-recent-login') {
        message = 'Bu işlem için tekrar giriş yapmanız gerekiyor.';
      } else {
        message = e.message ?? message;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Bilgilerimi Düzenle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
          ),
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
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _changePhoto,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF5D4037).withValues(alpha: 0.5), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                backgroundImage: (_profilePhotoUrl != null && _profilePhotoUrl!.startsWith('http'))
                                    ? CachedNetworkImageProvider(_profilePhotoUrl!)
                                    : null,
                                child: (_profilePhotoUrl == null || !_profilePhotoUrl!.startsWith('http'))
                                    ? const Icon(Icons.person, size: 70, color: Color(0xFF5D4037))
                                    : null,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF5D4037),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Glassmorphic Card for Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 5, bottom: 20),
                                child: Text(
                                  'Kişisel Bilgiler',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5D4037),
                                    fontFamily: 'serif',
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              _buildTextField(
                                controller: _nameController,
                                label: 'Ad Soyad',
                                icon: Icons.person_outline,
                                validator: (val) => val!.isEmpty ? 'Ad soyad boş bırakılamaz' : null,
                              ),
                              const SizedBox(height: 15),
                              _buildTextField(
                                controller: _emailController,
                                label: 'E-posta',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) => !val!.contains('@') ? 'Geçerli bir e-posta girin' : null,
                              ),
                              const SizedBox(height: 15),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'Telefon Numarası',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                hint: '+90...',
                              ),
                              const SizedBox(height: 30),
                              const Padding(
                                padding: EdgeInsets.only(left: 5, bottom: 20),
                                child: Text(
                                  'Güvenlik',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5D4037),
                                    fontFamily: 'serif',
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Yeni Şifre',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                hint: 'Değiştirmek istemiyorsanız boş bırakın',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D4037),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Değişiklikleri Kaydet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'serif',
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Center(
                      child: Text(
                        '* E-posta veya şifre değişikliği için son zamanlarda giriş yapmış olmanız gerekebilir.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.brown,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'serif',
                        ),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF5D4037).withValues(alpha: 0.1)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          color: Color(0xFF5D4037),
          fontWeight: FontWeight.w500,
          fontFamily: 'serif',
          fontStyle: FontStyle.italic,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.brown.shade700,
            fontSize: 14,
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.brown.shade300,
            fontSize: 12,
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF5D4037), size: 20),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}
