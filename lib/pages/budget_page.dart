
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text('BUDGET VIEW'),
    );
  }
}
