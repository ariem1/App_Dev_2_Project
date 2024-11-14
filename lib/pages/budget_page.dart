import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aura_journal/firestore_service.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}
class _BudgetPageState extends State<BudgetPage> {
  final FirestoreService _fsService = FirestoreService();
  late TextEditingController _budgetTextController;
  double? _budgetAmount;
  String? budgetId;
  String? journalId;
  double totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _budgetTextController = TextEditingController();
    _initializeBudgetId();
  }

  @override
  void dispose() {
    _budgetTextController.dispose();
    super.dispose();
  }

  Future<void> _initializeBudgetId() async {
    // Retrieve journalId and budgetId and update the state
    journalId = await _fsService.getJournalIdByUserIdAndDate();
    budgetId = await _fsService.getBudgetIdForJournal(journalId!);
    setState(() {});
    _calculateTotalSpent();
  }

  Future<void> _setBudget() async {
    double? enteredAmount = double.tryParse(_budgetTextController.text);

    if (enteredAmount != null && journalId != null) {
      await _fsService.setBudgetAmount(journalId!, enteredAmount);

      setState(() {
        _budgetAmount = enteredAmount;
      });
      _budgetTextController.clear();
    } else {
      print("Please enter a valid budget amount.");
    }
  }

  // Collection reference for spendings
  CollectionReference spendings = FirebaseFirestore.instance.collection('spendings');

  Future<void> deleteSpending(String id) async {
    await spendings.doc(id).delete();
    _calculateTotalSpent(); // Recalculate after deletion
  }

  Future<void> updateSpending(String id, String description) async {
    if (description.isNotEmpty) {
      await spendings.doc(id).update({'description': description});
    }
  }

  void _calculateTotalSpent() async {
    if (budgetId != null) {
      final querySnapshot = await spendings
          .where('budgetId', isEqualTo: budgetId)
          .get();

      double newTotalSpent = 0.0;
      for (var doc in querySnapshot.docs) {
        newTotalSpent += (doc['amount'] ?? 0.0) as double;
      }

      setState(() {
        totalSpent = newTotalSpent;
      });
    }
  }

  void _showEditDialog(String id, String currentDescription) {
    TextEditingController editController = TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Description'),
          content: TextField(
            controller: editController,
          ),
          actions: [
            TextButton(
              onPressed: () {
                updateSpending(id, editController.text);
                Navigator.of(context).pop();
                _calculateTotalSpent();
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final amountLeft = (_budgetAmount ?? 0) - totalSpent;

    return Scaffold(
      appBar: AppBar(title: Text('Budget Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set budget', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextField(
                      controller: _budgetTextController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: '\$',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _setBudget,
                  child: Text('Set budget'),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(5.0),
              child: Text('AMOUNT LEFT TO SPEND: \$${amountLeft.toStringAsFixed(2)}'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: budgetId == null
                  ? Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                stream: spendings
                    .where('budgetId', isEqualTo: budgetId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Text('Loading...');

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      double amount = doc['amount'] ?? 0.0;
                      String description = doc['description'] ?? 'No description';

                      return ListTile(
                        title: Text('\$${amount.toStringAsFixed(2)}'),
                        subtitle: Text('Description: $description'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _showEditDialog(doc.id, description),
                              icon: Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: () {
                                deleteSpending(doc.id);
                                _calculateTotalSpent();
                              },
                              icon: Icon(Icons.delete),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
