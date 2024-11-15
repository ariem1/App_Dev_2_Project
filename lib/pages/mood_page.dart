import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aura_journal/firestore_service.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  bool showMonthlyView = false;
  bool showEmotionView = false;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final FirestoreService _fsService = FirestoreService();

  int getDaysInMonth(int year, int month) {
    if (month < 1 || month > 12) throw ArgumentError("Month must be between 1 and 12.");
    DateTime firstDayOfNextMonth = DateTime(year, month + 1, 1);
    DateTime lastDayOfCurrentMonth = firstDayOfNextMonth.subtract(Duration(days: 1));
    return lastDayOfCurrentMonth.day;
  }

  Icon _buildIcon(int index) {
    switch (index) {
      case 0:
        return Icon(Icons.sentiment_very_dissatisfied,size: 50,);
      case 1:
        return Icon(Icons.sentiment_dissatisfied,size: 50);
      case 2:
        return Icon(Icons.sentiment_neutral,size: 50);
      case 3:
        return Icon(Icons.sentiment_satisfied,size: 50);
      case 4:
        return Icon(Icons.sentiment_very_satisfied,size: 50);
      default:
        return Icon(Icons.star_border,size: 50);
    }
  }

  Widget monthlyView() {
    List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8.0,
      mainAxisSpacing: 8.0,
      children: List.generate(months.length, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedMonth = index + 1;
              showEmotionView = true;
              showMonthlyView = false;
            });
          },
          child: Card(
            elevation: 4,
            child: Center(
              child: Text(
                months[index],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }),
    );
  }

  Stream<int?> getMoodForDay(int day, int month) {
    int currentYear = DateTime.now().year;
    DateTime startOfDay = DateTime(currentYear, month, day, 0, 0, 0);
    DateTime endOfDay = DateTime(currentYear, month, day, 23, 59, 59);

    CollectionReference journals = FirebaseFirestore.instance.collection('journals');

    return journals
        .where('userId', isEqualTo: _fsService.getCurrentUserId())
        .snapshots()
        .asyncMap((querySnapshot) {
      // Loop through all journal entries and check if any match the date
      for (var doc in querySnapshot.docs) {
        DateTime entryDate = (doc['entryDate'] as Timestamp).toDate();
        if (entryDate.year == currentYear && entryDate.month == month && entryDate.day == day) {
          var mood = doc['mood'];
         // debug stuff print("Real-time mood update: $mood");
          return mood; // Return the updated mood
        }
      }
      return null; // No matching mood data for this date
    });
  }


  Widget emotionView(int month) {
    int currentYear = DateTime.now().year;
    int daysInMonth = getDaysInMonth(currentYear, month);

    return Column(
      children: [
        Text(
          DateFormat('MMMM yyyy').format(DateTime(currentYear, month)),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            children: List.generate(daysInMonth, (index) {
              int day = index + 1;

              return StreamBuilder<int?>(
                stream: getMoodForDay(day, month),  // Listen for real-time updates
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  int mood = snapshot.data ?? -1; // -1 as the default if no mood data
                 // for debugging ignoreee print("Displaying mood for day $day: $mood");
                  return Column(
                    children: [
                      _buildIcon(mood),
                      Text(day.toString()),
                    ],
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }


  Widget initialView() {
    return emotionView(DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mood Page'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Statistics'),
                ),
                SizedBox(width: 30),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (showEmotionView) {
                        showEmotionView = false;
                        showMonthlyView = !showMonthlyView;
                      } else {
                        showMonthlyView = !showMonthlyView;
                      }
                    });
                  },
                  child: Text('Monthly'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: showMonthlyView
                  ? monthlyView()
                  : showEmotionView
                  ? emotionView(selectedMonth)
                  : initialView(),
            ),
          ],
        ),
      ),
    );
  }
}
