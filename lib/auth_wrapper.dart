import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homescreen.dart';
import 'verificationemail.dart';
import 'login_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'utils/notification_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF5D4037)),
            ),
          );
        }

        Widget currentWidget;
        if (snapshot.hasData) {
          final user = snapshot.data!;

          // Finalize FCM token handling
          if (!kIsWeb) {
            FirebaseMessaging.instance.getToken().then((token) {
              if (token != null) {
                NotificationService().saveTokenToFirestore(token);
              }
            });
          }
          _syncCaregiverInvite(user);

          // Bakıcılar anonim oturumla, telefon OTP beklemeden içeri alınır.
          bool isAuthorized =
              user.isAnonymous ||
              user.phoneNumber != null ||
              user.emailVerified;
          currentWidget = isAuthorized
              ? const HomeScreen()
              : const VerificationEmailPage();
        } else {
          currentWidget = const LoginPage();
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: SizedBox.expand(
            key: ValueKey(currentWidget.runtimeType),
            child: currentWidget,
          ),
        );
      },
    );
  }

  Future<void> _syncCaregiverInvite(User user) async {
    final phone = user.phoneNumber;
    if (phone == null || phone.isEmpty) return;

    final inviteQuery = await FirebaseFirestore.instance
        .collection('caregivers')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (inviteQuery.docs.isEmpty) return;

    final inviteDoc = inviteQuery.docs.first;
    final data = inviteDoc.data();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'role': 'bakici',
      'parentId': data['parentId'],
      'phone': phone,
      'name': data['name'] ?? 'Bakıcı',
      'status': 'active',
      'caregiverInviteId': inviteDoc.id,
    }, SetOptions(merge: true));

    await inviteDoc.reference.set({
      'status': 'active',
      'caregiverUid': user.uid,
      'acceptedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
