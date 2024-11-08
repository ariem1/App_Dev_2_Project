import 'home_page.dart';
import 'package:aura_journal/pages/main_page.dart';
import 'package:aura_journal/pages/mood_page.dart';
import 'package:aura_journal/pages/budget_page.dart';
import 'package:aura_journal/pages/water_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'nav_bar.dart';
class ToDoPage extends StatefulWidget {
  const ToDoPage({super.key});

  @override
  State<ToDoPage> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("TO DO VIEW"),
        ),
        body: Text('yes'));
  }
}
