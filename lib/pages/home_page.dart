import 'package:aura_journal/pages/journal_page.dart';
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

    // Navigate to the new page with the selected date
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalPage(selectedDate: today),
      ),
    );

    print("Selected day is: $selectedDay ");
  }

  // List to store tasks with their status
  List<Map<String, dynamic>> tasks = [
    {"task": "Buy groceries", "completed": false},
    {"task": "Finish homework", "completed": true},
    {"task": "Workout", "completed": false},
    {"task": "Buy groceries", "completed": false},
    {"task": "Finish homework", "completed": true},
    {"task": "Workout", "completed": false},
  ];

  // Function to toggle the checkbox state
  void _toggleTaskCompletion(int index) {
    setState(() {
      tasks[index]['completed'] = !tasks[index]['completed'];
    });
  }

  TextEditingController taskController = new TextEditingController();

  // Function to add a new task
  void addTask() {
    if (taskController.text.isNotEmpty) {
      setState(() {
        tasks.add({"task": taskController.text, "completed": false});
      });
      taskController.clear(); // Clear the text field
    }
  }

  // List to store water drop icons
  List<Widget> droplets = [];

  // Function to add a droplet
  void _addDroplet() {
    setState(() {
      droplets
          .add(Icon(Icons.water_drop_outlined, size: 30)); // Add a new droplet
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Column(
            children: [
              Container(
                // CALENDAR CONTAINER
                padding: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white, // Background color of the container
                  borderRadius: BorderRadius.circular(25), // Rounded corners
                ),
                child: TableCalendar(
                  locale: "en_US",
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    headerMargin: EdgeInsets.symmetric(vertical: 5),
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    headerTitleBuilder: (context, date) {
                      // dayPart and monthYearPart
                      String dayPart = DateFormat('EEE, MMM d').format(today);
                      String monthYearPart =
                          DateFormat('MMM yyyy').format(date);

                      //Header text
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // DAY PART
                            Container(
                              width: 160,
                              child: Text(
                                dayPart,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // MONTH YEAR PART
                            Container(
                              width: 90,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    monthYearPart,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
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
              //  const SizedBox(height: 20),
              Container(
                margin: EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(' DATA'),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue, // Set the border color
                          width: 2.0, // Set the border width
                        ),
                      ),
                      margin: EdgeInsets.only(top: 5),
                      padding: EdgeInsets.only(top: 5),

                      child: Row(
                        children: [
                          Container(
                            child: Icon(
                              Icons.water_drop_outlined,
                              size: 70,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 7),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.blue, // Set the border color
                                width: 2.0, // Set the border width
                              ),),
                            width: 250,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Today's Water Intake"),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: droplets,
                                )
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children:[ IconButton(
                              icon: Icon(Icons.add), // Icon to display
                              onPressed: () {
                                _addDroplet();
                                print("Water added!");
                              },
                            ),
                          ],),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget toDoList() {
    // Shows the to-do items
    return Column(
      children: List.generate(
        tasks.length,
        (index) {
          return Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey, // Border color
                  width: 1.0, // Border width
                ),
              ),
            ),
            child: ListTile(
              leading: Checkbox(
                value: tasks[index]['completed'],
                onChanged: (bool? value) {
                  _toggleTaskCompletion(index);
                },
              ),
              title: Text(
                tasks[index]['task'],
                style: TextStyle(
                  decoration: tasks[index]['completed']
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget ToDoView() {
    return Container(
      // TO DO CONTAINER
      height: 350,
      margin: EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      // decoration: BoxDecoration(
      //  // color: Colors.green,
      //   borderRadius: BorderRadius.circular(10),
      //   border: Border.all(color: Colors.black12),
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  'To Do',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: 260,
                ),
                GestureDetector(
                  onTap: () {
                    //CHANGE - NAVIGATE TO TO DO VIEW
                    print("View To Do !");
                  },
                  child: Text(
                    'View',
                    style: TextStyle(fontSize: 17, color: Colors.black54),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            // color: Colors.lightBlueAccent,
            height: 190,
            margin: EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              //     color: Colors.lightBlueAccent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: SingleChildScrollView(
              child: toDoList(),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskController,
                    decoration: InputDecoration(
                      hintText: "Enter a new task",
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 0, horizontal: 15), // Controls height

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            30), // Rounded corners for enabled state
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: addTask,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
