
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text('MOOD VIEW'),
    );
  }
}
