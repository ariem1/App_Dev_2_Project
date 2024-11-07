import 'package:flutter/material.dart';
import 'package:aura_journal/pages/main_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Define the custom color with correct alpha channel
  final Color customColor = const Color(0xFFE3EFF9);  // Updated with full opacity (0xFF)

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Journal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        scaffoldBackgroundColor: customColor, // Set the body background color here
        appBarTheme: AppBarTheme(
          backgroundColor: customColor,  // Set the AppBar background color here
        ),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}
