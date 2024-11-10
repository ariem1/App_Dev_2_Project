import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  bool showMonthlyView = false;
  bool showEmotionView = false; // Add a flag to track whether the emotion view is shown
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  // Function to calculate days in a specific month
  int getDaysInMonth(int year, int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError("Month must be between 1 and 12.");
    }

    DateTime firstDayOfNextMonth = DateTime(year, month + 1, 1);
    DateTime lastDayOfCurrentMonth = firstDayOfNextMonth.subtract(Duration(days: 1));
    return lastDayOfCurrentMonth.day;
  }

  // Monthly view displaying all months in a grid
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
              showEmotionView = true; // When a month is selected, show the emotion view
              showMonthlyView = false; // Close the monthly view
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

  // Function to display grid of emotion based on month
  Widget emotionView(int month) {
    List<Widget> smileyIcons = List.generate(getDaysInMonth(DateTime.now().year, month), (index) {
      return Column(
        children:[ 
          Center(
          child: Icon(
            Icons.insert_emoticon,
            size: 40,
          ),
        ),
          Text((index + 1).toString()),
      ]
      );
    });

    return Column(
      children: [
        Text(
          DateFormat('MMMM').format(DateTime(DateTime.now().year, month)),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            children: smileyIcons,
          ),
        ),
      ],
    );
  }

  // Initial view displaying the current month emotion view
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
                  onPressed: () {
                  },
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
                  : initialView(), //default
            ),
          ],
        ),
      ),
    );
  }
}
