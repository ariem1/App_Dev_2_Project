import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aura_journal/pages/main_page.dart';
import 'package:aura_journal/pages/splash_screen.dart';
import 'firestore_service.dart';

Future<void> main() async {
  // Ensure Firebase is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  print('Main: Firebase Initialized');

  // Initialize Firestore and sign in anonymously
  final FirestoreService firestoreService = FirestoreService();
  await firestoreService.signInAnonymouslyAndCreateUser();

  print('Current User: ${firestoreService.getCurrentUser()?.isAnonymous}');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Color _backgroundColor = const Color(0xFFE3EFF9);
  bool _isSplashScreen = true;

  void _updateBackgroundColor(Color color) {
    setState(() {
      _backgroundColor = color;
    });
  }

  @override
  void initState() {
    super.initState();

    // a delay for the splash screen
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isSplashScreen = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Journal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        scaffoldBackgroundColor: _backgroundColor,
        appBarTheme: AppBarTheme(
          titleTextStyle: const TextStyle(
            color: Colors.deepPurple,
            fontSize: 20,
          ),
          backgroundColor: _backgroundColor,
        ),
        useMaterial3: true,
      ),
      home: _isSplashScreen
          ? const SplashScreen() // Show splash screen i
          : MainPage(
        onColorUpdate: _updateBackgroundColor,
      ),
    );
  }
}
