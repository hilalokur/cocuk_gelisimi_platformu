import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          FirebaseMessaging.instance.getToken().then((token) {
            if (token != null) {
              NotificationService().saveTokenToFirestore(token);
            }
          });

          // Telefonla giriş yapanlar (phoneNumber != null) email onayına takılmaz
          bool isAuthorized = user.phoneNumber != null || user.emailVerified;
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
}
