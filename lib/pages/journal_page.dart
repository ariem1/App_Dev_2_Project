import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class JournalPage extends StatefulWidget {

  final DateTime selectedDate;

  const JournalPage({super.key, required this.selectedDate});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entry'),
      ),
      body: Center(
        child: Text(
          widget.selectedDate.day.toString(), // Display the passed string
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
