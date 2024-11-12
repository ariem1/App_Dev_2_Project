import 'package:flutter/material.dart';
import 'package:aura_journal/pages/main_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyA20UbObasSkmABafhL4uGLeBRmWiBb5cM",
        appId: "223818592172",
        messagingSenderId: "1:223818592172:android:3a874b01cf4936bf7f1409",
        projectId: "aura-journal")
  );
  print('DB Connected');
  CollectionReference users = FirebaseFirestore.instance.collection('Users');
  String name = 'emma';
  String password = 'solo';

 // Future<void> addUsers() async {
    if (name.isNotEmpty && password.isNotEmpty) {
      await users.add({'name': name, 'password': password});

      print('user added');
   // }
  }

  runApp(const MyApp());

}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CollectionReference users = FirebaseFirestore.instance.collection('Users');
  String name = 'emma';
  String password = 'solo';

  Future<void> addUsers() async{
    if(name.isNotEmpty && password.isNotEmpty){
      await users.add({'name':name, 'password': password});

      print('user added');

    }
}

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
