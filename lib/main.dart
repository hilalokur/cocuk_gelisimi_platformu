import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'splashscreen.dart';
import 'utils/notification_service.dart';
import 'providers/child_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await initializeDateFormatting('tr_TR', null);
  await NotificationService().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChildProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minik Adımlar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'serif',
        useMaterial3: true,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontStyle: FontStyle.italic),
          displayMedium: TextStyle(fontStyle: FontStyle.italic),
          displaySmall: TextStyle(fontStyle: FontStyle.italic),
          headlineLarge: TextStyle(fontStyle: FontStyle.italic),
          headlineMedium: TextStyle(fontStyle: FontStyle.italic),
          headlineSmall: TextStyle(fontStyle: FontStyle.italic),
          titleLarge: TextStyle(fontStyle: FontStyle.italic),
          titleMedium: TextStyle(fontStyle: FontStyle.italic),
          titleSmall: TextStyle(fontStyle: FontStyle.italic),
          bodyLarge: TextStyle(fontStyle: FontStyle.italic),
          bodyMedium: TextStyle(fontStyle: FontStyle.italic),
          bodySmall: TextStyle(fontStyle: FontStyle.italic),
          labelLarge: TextStyle(fontStyle: FontStyle.italic),
          labelSmall: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
