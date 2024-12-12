import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aura_journal/firestore_service.dart';

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> {
  final FirestoreService _fsService = FirestoreService(); // Firestore service instance
  double fillPercentage = 1.0; // means full cup
  int counter = 0; // Counter for how many cups have been emptied
  bool isDrinking = false; // To track if water is being consumed

  @override
  void initState() {
    super.initState();
    _fetchWaterProgress(); // Fetch initial water progress
  }

  Future<void> _fetchWaterProgress() async {
    try {

      String? userId = _fsService.getCurrentUser()?.uid; // Get current user ID

      if (userId != null) {
        // Safely fetch the journal ID for today's date
        String? journalId = await _fsService.getJournalIdByUserIdAndDate_2(userId!);

        if (journalId != null) {
          final docSnapshot = await _fsService.getDocument(
            collection: 'journals',
            documentId: journalId, // Pass the journal ID to fetch the document
          );

          if (docSnapshot.exists) {
            int cupsDrank = docSnapshot.data()?['water'] ?? 0; // Fetch cupsDrank

            setState(() {
              counter = cupsDrank;
              // fillPercentage = cupsDrank < 8
              //     ? 1.0 - (cupsDrank / 8.0) // Calculate the remaining percentage
              //     : 0.0;

              fillPercentage = 1.0; // Always start with a full cup

              if (counter >= 8 ){
                fillPercentage = 0;
                setState(() {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Congratulations!"),
                      content: Text("You completed 8/8 cups of water for the day!"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("OK"),
                        ),
                      ],
                    ),
                  );
                });

              }

            });

            print("Water progress updated: $cupsDrank cups.");
          }
        }
      }
    } catch (e) {
      print("Error fetching water progress: $e");
    }
  }

  void increaseFill() {
    setState(() {
      fillPercentage = (fillPercentage + 0.125).clamp(0.0, 1.0); // Restrict value to 0.0–1.0
    });

  //  _fsService.updateJournalWater(journalId, water)
  }

  void decreaseFill() async {
    setState(() {
      fillPercentage = (fillPercentage - 0.125).clamp(0.0, 1.0);
      if (fillPercentage == 0.0 && counter < 8) {
        counter++; // Increment counter when the cup is empty
        if (counter < 8) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Good Job!"),
              content: Text("You drank $counter/8 cups of water!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      fillPercentage = 1.0; // Refill the cup
                    });
                  },
                  child: Text("OK"),
                ),
              ],
            ),
          );
        } else {
          // If 8 cups are reached, show a congrats message
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Congratulations!"),
              content: Text("You completed 8/8 cups of water for the day!"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
                ),
              ],
            ),
          );
        }
      }
    });

    try {
      String? userId = _fsService.getCurrentUserId(); // Fetch user ID once
      if (userId != null) {
        String? journalId = await _fsService.getJournalIdByUserIdAndDate_2(userId);
        if (journalId != null) {
          await _fsService.updateJournalWater(journalId, counter); // Update cupsDrank in Firestore
        }
      }
    } catch (e) {
      print("Error updating water progress: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Water Tracker"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Cups Drank: $counter/8",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: Duration(seconds: 1),
                      width: 200,
                      height: 300 * fillPercentage,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                Image.asset(
                  'assets/emptycup.png',
                  width: 250,
                  height: 300,
                  fit: BoxFit.fill,
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: counter >= 8 ? null : increaseFill, // Disable if counter is 8 or more
                  child: Text("Fill Cup"),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: counter >= 8 ? null :
                  decreaseFill,
                  child: Text("Drink Water"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
