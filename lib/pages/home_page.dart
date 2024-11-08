import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //todays date
  DateTime today = DateTime.now();

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });

    // Check which day of the week is selected
    String selectedDay;
    switch (day.weekday) {
      case 1:
        selectedDay = "Monday";
        break;
      case 2:
        selectedDay = "Tuesday";
        break;
      case 3:
        selectedDay = "Wednesday";
        break;
      case 4:
        selectedDay = "Thursday";
        break;
      case 5:
        selectedDay = "Friday";
        break;
      case 6:
        selectedDay = "Saturday";
        break;
      case 7:
        selectedDay = "Sunday";
        break;
      default:
        selectedDay = "Unknown";
    }

    print("Selected day is: $selectedDay");
  }

  String _formatHeaderText(DateTime date) {
    // Get the full date in the format: "Mon, Aug 17"
    String dayPart = DateFormat('EEE, MMM d').format(today);
    // Get the month and year part: "Aug 2024"
    String monthYearPart = DateFormat('MMM yyyy').format(date);

    return "$dayPart $monthYearPart";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white, // Background color of the container
                borderRadius: BorderRadius.circular(20), // Rounded corners
                border: Border.all(
                  color: Colors.black26, // Border color
                  width: 0.5, // Border width
                ),
              ),
              child:
                TableCalendar(
                  locale: "en_US",
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    headerMargin: EdgeInsets.symmetric(vertical: 5),
                    titleTextStyle: TextStyle(fontSize: 18),
                  ),
                  calendarBuilders: CalendarBuilders(
                    headerTitleBuilder: (context, date) {
                      // dayPart and monthYearPart
                      String dayPart = DateFormat('EEE, MMM d').format(today);
                      String monthYearPart = DateFormat('MMM yyyy').format(date);

                      //Header text
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // DAY PART
                            Text(
                              dayPart,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 68,),
                            // MONTH YEAR PART
                            Text(
                              monthYearPart,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  availableGestures: AvailableGestures.all,
                  focusedDay: today,
                  selectedDayPredicate: (day) => isSameDay(day, today),
                  firstDay: DateTime.utc(1970, 1, 1),
                  lastDay: DateTime.utc(2050, 1, 1),
                  onDaySelected: _onDaySelected,
                  daysOfWeekHeight: 25,
                ),
            ),
            const SizedBox(height: 20),
            Text(
              "Selected Day: ${today.toString().split(" ")[0]}",
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}