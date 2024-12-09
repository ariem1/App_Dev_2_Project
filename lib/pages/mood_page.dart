import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aura_journal/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  bool showMonthlyView = false;
  bool showEmotionView = false;
  bool showMonthlyStats = false;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

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

  Widget monthlyStatsView() {

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8.0,
      mainAxisSpacing: 8.0,
      children: List.generate(months.length, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedMonth = index + 1;
              showMonthlyStats = false;
              showEmotionView = false;
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                  ),
                  body: monthlyGraphView(selectedMonth),
                ),
              ),
            );
          },
          child: Card(
            elevation: 4,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    months[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Icon(Icons.bar_chart, size: 30, color: Color(0xFF83C2D9)), // Placeholder for a stats icon
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget monthlyGraphView(int month) {
    int currentYear = DateTime.now().year;
    int daysInMonth = getDaysInMonth(currentYear, month);

    return FutureBuilder<Map<int, int>>(
      future: _getMonthlyMoodCounts(currentYear, month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('No data');
          return Center(child: Text("No data available for ${months[month - 1]}"));
        }

        Map<int, int> moodCounts = snapshot.data!;

        // Calculate the most frequent mood
        int mostFrequentMood = moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

        // Fetch a quote for the most frequent mood
        return FutureBuilder<String>(
          future: fetchMoodQuote(_getMoodName(mostFrequentMood)), // Fetch quote
          builder: (context, quoteSnapshot) {
            return Column(
              children: [
                Text(
                  'Moods for ${months[month - 1]} $currentYear',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF83C2D9)),
                ),
                if (quoteSnapshot.connectionState == ConnectionState.waiting)
                  CircularProgressIndicator()
                else if (quoteSnapshot.hasError)
                  Text("")
                else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      quoteSnapshot.data ?? "No quote available.",
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: moodCounts.entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.toDouble(),
                                color: Color(0xFF83C2D9),
                                width: 40,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                            showingTooltipIndicators: [0],
                          );
                        }).toList(),
                        maxY: daysInMonth.toDouble(),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: _buildIcon(value.toInt()),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                rod.toY.toInt().toString(),
                                TextStyle(
                                  color: Color(0xFF83C2D9),
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        gridData: FlGridData(show: false), // Remove gridlines
                        borderData: FlBorderData(show: false), // Remove borders
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getMoodName(int moodIndex) {
    const moodNames = [
      "anger", "sad", "neutral", "happy", "joyful"
    ]; // Adjust to match your moods
    return moodIndex >= 0 && moodIndex < moodNames.length ? moodNames[moodIndex] : "neutral";
  }

  Future<Map<int, int>> _getMonthlyMoodCounts(int year, int month) async {
    Map<int, int> moodCounts = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0};

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('journals')
        // .where('userId', isEqualTo: _fsService.getCurrentUserId())
     .where('userId', isEqualTo: '3iosUh9ccOSQAu7xWhKeVVVZ6Ei2')

        .get();

    for (var doc in querySnapshot.docs) {
      DateTime entryDate = (doc['entryDate'] as Timestamp).toDate();
      if (entryDate.year == year && entryDate.month == month) {
        int mood = doc['mood'];
        if (moodCounts.containsKey(mood)) {
          moodCounts[mood] = moodCounts[mood]! + 1;
        }
      }
    }
    return moodCounts;
  }

  Widget monthlyView() {
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

  //Code for fetch quote api
  Future<String>fetchMoodQuote(String mood) async{
    const String baseUrl = "https://mood-based-quote-api.p.rapidapi.com/";
    const Map<String, String> headers = {
      "X-RapidAPI-Key": "83586a7b1amshbd3b1190668f113peff0bjsn09a2cc3b7c60", // Replace with your actual API key
      "X-RapidAPI-Host": "mood-based-quote-api.p.rapidapi.com"
    };

    final String url = "$baseUrl$mood";

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['quote'] ?? "No quote found.";
    } else {
      throw Exception("Failed to fetch quote: ${response.reasonPhrase}");
    }
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
                    setState(() {
                      showMonthlyStats = true;
                      showMonthlyView = false;
                      showEmotionView = false;
                    });
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
                      showMonthlyStats = false; // Ensure stats view is turned off
                    });
                  },
                  child: Text('Monthly'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: showMonthlyStats
                  ? monthlyStatsView() // Display Statistics View
                  : showMonthlyView
                  ? monthlyView() // Display Monthly View
                  : showEmotionView
                  ? emotionView(selectedMonth) // Display Emotion View
                  : initialView(), // Default Initial View
            ),
          ],
        ),
      ),
    );
  }
}
