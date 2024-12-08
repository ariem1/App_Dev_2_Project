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
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _budgetTextController = TextEditingController();
    initializeUserId();

    _initializeBudgetId();
  }

  @override
  void dispose() {
    _budgetTextController.dispose();
    super.dispose();
  }

  Future<void> initializeUserId() async {
    String? userId = _fsService.getCurrentUserId();

    if (mounted) {
      setState(() {
        currentUserId = userId;
      });
    }

    print('Budget Get user id: $currentUserId');
  }


  Future<void> _initializeBudgetId() async {
    try {
      final String? fetchedJournalId =
      await _fsService.getJournalIdByUserIdAndDate_2(currentUserId!);
      final String? fetchedBudgetId = fetchedJournalId != null
          ? await _fsService.getBudgetIdForJournal(fetchedJournalId)
          : null;

      if (mounted) {
        setState(() {
          journalId = fetchedJournalId;
          budgetId = fetchedBudgetId;
        });
      }

      print('Budget journalid: $journalId');
      print('Budget user id: $currentUserId');
      print('Budget id: $budgetId');

      if (budgetId != null) {
        final budgetAmount = await _fsService.getBudgetAmount(budgetId!);
        if (mounted) {
          setState(() {
            _budgetAmount = budgetAmount;
          });
        }
      }

      _calculateTotalSpent();
    } catch (e) {
      print("Error initializing budget: $e");
    }
  }


  //function to set budget
  Future<void> _setBudget() async {
    double? enteredAmount = double.tryParse(_budgetTextController.text);

    // No journal Id
    if (enteredAmount != null && journalId == null) {
      // Make a journal
      await _fsService.addJournalEntry(0, -1, '', currentUserId!);

      await _fsService.setBudgetAmount(journalId!, enteredAmount);

      setState(() {
        _budgetAmount = enteredAmount;
      });
      _budgetTextController.clear();
    } else if (enteredAmount != null && journalId != null) {
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
  CollectionReference spendings =
      FirebaseFirestore.instance.collection('spendings');

  //delete spending
  Future<void> deleteSpending(String id) async {
    await spendings.doc(id).delete();
    _calculateTotalSpent(); // Recalculate after deletion
  }

  //Update spending
  Future<void> updateSpending(String id, String description) async {
    if (description.isNotEmpty) {
      await spendings.doc(id).update({'description': description});
    }
  }
  void _calculateTotalSpent() async {
    if (budgetId != null) {
      try {
        final querySnapshot =
        await spendings.where('budgetId', isEqualTo: budgetId).get();

        double newTotalSpent = 0.0;
        for (var doc in querySnapshot.docs) {
          newTotalSpent += (doc['amount'] ?? 0.0) as double;
        }

        if (mounted) {
          setState(() {
            totalSpent = newTotalSpent;
          });
        }

        if (_budgetAmount != null && totalSpent > _budgetAmount!) {
          double overspendAmount = totalSpent - _budgetAmount!;
          if (mounted) {
            _showOverSpendingDialog(overspendAmount);
          }
        }
      } catch (e) {
        print("Error calculating total spent: $e");
      }
    }
  }


  void _showOverSpendingDialog(double overspendAmount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Overspending Alert',
            style: TextStyle(color: Colors.red),
          ),
          content: Text('You are $overspendAmount over your budget'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(String id, String currentDescription) {
    TextEditingController editController =
        TextEditingController(text: currentDescription);

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
              child: Text(
                  'AMOUNT LEFT TO SPEND: \$${amountLeft.toStringAsFixed(2)}'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: budgetId == null
                  ? Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('spendings')
                    .where('budgetId', isEqualTo: budgetId) // Match budgetId
                    .snapshots(), // Real-time updates
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No spendings yet.'));
                  }

                  // Display the list of spendings
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
              )
            ),
          ],
        ),
      ),
    );
  }
}
