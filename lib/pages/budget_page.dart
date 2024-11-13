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
  //db connection
  final FirestoreService _fsService = FirestoreService();
  late User? currentUser = _fsService.getCurrentUser();

  late TextEditingController _budgetTextController;
  double? _budgetAmount;
  late double totalSpent;

  @override
  void initState() {
    super.initState();
    _budgetTextController = TextEditingController();
  }

  @override
  void dispose() {
    _budgetTextController.dispose();
    super.dispose();
  }

  void _setBudget() {
    setState(() {
      _budgetAmount = double.tryParse(_budgetTextController.text);
      _budgetTextController.clear();
    });
  }

  // Collection reference for spendings
  CollectionReference spendings = FirebaseFirestore.instance.collection('spendings');

  // Delete spending entry
  Future<void> deleteSpending(String id) async {
    await spendings.doc(id).delete();
  }

  // Update spending description
  Future<void> updateSpending(String id, String description) async {
    if (description.isNotEmpty) {
      try {
        await spendings.doc(id).update({'description': description});
      } catch (error) {
        print('Failed to update');
      }
    } else {
      print('Enter a valid description');
    }
  }

  // Update budget by all spendings
  Future<void> updateBudget() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('spendings').get();

    // loop through each entry and get sum of the amount spent
    for (var doc in snapshot.docs) {
      double amount = doc['amount'] ?? 0.0;
      totalSpent += amount;
    }

    // update budget
    if (_budgetAmount != null) {
      setState(() {
        _budgetAmount = _budgetAmount! - totalSpent;
      });
    }
  }

  // Show dialog to edit description for that entry
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
                // Update
                updateSpending(id, editController.text);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Padding(padding: EdgeInsets.all(5.0), child: Text('AMOUNT LEFT TO SPEND: ' + _budgetAmount.toString())),
            SizedBox(height: 20),
            // Display spendings from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(

                stream: FirebaseFirestore.instance
                    .collection('spendings')
                    .where('userId', isEqualTo: currentUser?.uid) // Filter by userId
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Text('Loading...');

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      // Get values from Firestore document
                      double amount = doc['amount'] ?? 0.0;
                      String description = doc['description'] ?? 'No description';
                      return ListTile(
                        title: Text('\$${amount.toStringAsFixed(2)}'),
                        subtitle: Text('Description: $description'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _showEditDialog(doc.id, description), // Edit button
                              icon: Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: () => deleteSpending(doc.id), // Delete button
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
