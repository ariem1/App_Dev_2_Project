import 'package:flutter/material.dart';
import 'package:aura_journal/pages/main_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';


Future<void> main() async {

  //initialize firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  print('Main: Firebase Initialized');

  //Initialize FireStore and sign in anonymously
  final FirestoreService firestoreService = FirestoreService();
  await firestoreService.signInAnonymouslyAndCreateUser();

  print('Current User: ${firestoreService.getCurrentUser()?.isAnonymous}');


  runApp(const MyApp());

}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Color _backgroundColor = const Color(0xFFE3EFF9);


  void _updateBackgroundColor(Color color) {
    setState(() {
      _backgroundColor = color;
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
          titleTextStyle: TextStyle(color: Colors.deepPurple, fontSize: 20),
          backgroundColor: _backgroundColor,
        ),
        useMaterial3: true,
      ),
      home: MainPage(
        onColorUpdate: _updateBackgroundColor,
      ),
    );
  }
}
