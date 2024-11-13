import 'package:aura_journal/pages/journal_page.dart';
import 'package:aura_journal/pages/main_page.dart';
import 'package:aura_journal/pages/to_do_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aura_journal/firestore_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //db connection
  final FirestoreService _fsService = FirestoreService();

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

    //Create journal if not exist


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

  int _selectedMood = 4; //happy as defualt

  Icon _buildIcon(int index) {
    switch (index) {
      case 0:
        return Icon(Icons.sentiment_very_dissatisfied); // Lowest rating
      case 1:
        return Icon(Icons.sentiment_dissatisfied); // Moderate-low rating
      case 2:
        return Icon(Icons.sentiment_neutral); // Neutral rating
      case 3:
        return Icon(Icons.sentiment_satisfied); // Moderate-high rating
      case 4:
        return Icon(Icons.sentiment_very_satisfied); // Highest rating
      default:
        return Icon(Icons.star_border); // Default icon
    }
  }

  Icon _moodToDisplay(int index) {
    return Icon(
      _buildIcon(index).icon,
      size: 70,
    );
  }

  bool showToDoPage = false;

  final PageController _pageController = PageController(initialPage: 0);

  /* FIREBASE STUFF */
// Check if journal entry exists for today
  Future<bool> checkJournalEntry() async {
    bool journalExists = await _fsService.journalEntryExistsForToday();
    print('Journal exists: $journalExists');

    return journalExists;
  }

  /*BUDGET STUFF*/

  TextEditingController budgetController = TextEditingController();
  CollectionReference spendings =
      FirebaseFirestore.instance.collection('spendings');
  double amount = 0.0;
  String description = '';

  Future<void> addSpending() async {
    String? userId = _fsService.getCurrentUser()?.uid;

    if (amount > 0) {
      await spendings.add({
        'userId': userId,
        'amount': amount,
        'description': description,
        'createdAt': Timestamp.now(),
      });

      setState(() {
        amount = 0.0;
        description = '';
        budgetController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Column(
                  children: [
                    Container(
                      // CALENDAR CONTAINER
                      padding: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
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
                            String dayPart =
                                DateFormat('EEE, MMM d').format(today);
                            String monthYearPart =
                                DateFormat('MMM yyyy').format(date);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
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
                  ],
                ),
              ),
            ),
          ),
          // Swipeable Container using PageView
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.only(bottom: 60, left: 20, right: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                //color: Colors.pink[50],
              ),
              child: PageView(
                controller: _pageController,
                children: [
                  easyView(),
                  ToDoView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget easyView() {
    return SingleChildScrollView(
      child: Column(children: [
        Container(
          // margin: EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: 5),
                padding: EdgeInsets.only(top: 5, bottom: 15, left: 5),
                decoration: BoxDecoration(
                    border: Border(
                  bottom: BorderSide(color: Colors.black12, width: 1),
                )),
                child: Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.water_drop_outlined, size: 70),
                      Container(
                        //  padding: EdgeInsets.only(bottom: 10),
                        margin: EdgeInsets.only(left: 10),
                        width: 230,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Today's Water Intake"),
                            SizedBox(height: 10),
                            Row(children: droplets),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _addDroplet,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10),
                padding: EdgeInsets.only(top: 5, bottom: 15, left: 5),
                decoration: BoxDecoration(
                    border: Border(
                  bottom: BorderSide(color: Colors.black12, width: 1),
                )),
                child: Row(
                  children: [
                    _moodToDisplay(_selectedMood),
                    Container(
                      //  padding: EdgeInsets.only(bottom: 10),
                      margin: EdgeInsets.only(left: 10),
                      width: 250,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's Mood"),
                          SizedBox(height: 10),
                          Row(
                            children: List.generate(5, (index) {
                              return IconButton(
                                icon: _buildIcon(index),
                                onPressed: () async {  // add mood to journal entry of the day


                                  //If journal doesnt exist, make an entry
                                  bool journalExists = await checkJournalEntry();  // Await the check


                                  if (!journalExists) {
                                    await _fsService.addJournalEntry(_selectedMood, '', 0,0);
                                    print('Journal entry created and mood added');
                                  } else {
                                    //If journal exists, update the mood
                                    String? journalId = await _fsService
                                        .getJournalIdByUserIdAndDate();

                                    //update mood
                                    _fsService.updateJournalMood(
                                        journalId!, _selectedMood);
                                  }

                                  setState(() {
                                    _selectedMood = index;
                                  });
                                },
                                color: _selectedMood == index
                                    ? Colors.deepPurple
                                    : null,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 5),
                padding: EdgeInsets.only(top: 5, bottom: 15, left: 5),
                decoration: BoxDecoration(
                    border: Border(
                  bottom: BorderSide(color: Colors.black12, width: 1),
                )),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, size: 70),
                    Container(
                      //  padding: EdgeInsets.only(bottom: 10),
                      margin: EdgeInsets.only(left: 10),
                      width: 230,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Budget"),
                          SizedBox(height: 10),
                          Row(children: [
                            Text("Balance: \$"),
                            Expanded(
                                child: TextField(
                              controller: budgetController,
                              onChanged: (value) =>
                                  amount = double.tryParse(value) ?? 0.0,
                              keyboardType: TextInputType.number,
                            ))
                          ]),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: addSpending,
                    ),
                  ],
                ),
              ),
              Container(
                // PAGE INDICATORSS
                padding: const EdgeInsets.all(8.0),
                margin: EdgeInsets.only(top: 5),

                child: Row(
                  //mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Filled circle
                    Container(
                      width: 12,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.black, // Filled circle color
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Unfilled circle
                    Container(
                      width: 12,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget ToDoView() {
    return SingleChildScrollView(
      child: Container(
        // TO DO CONTAINER
        height: 330,
        margin: EdgeInsets.only(top: 10),
        //padding: const EdgeInsets.all(10),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ToDoPage()),
                      );
                    },
                    child: Text(
                      'View',
                      style: TextStyle(fontSize: 17, color: Colors.black54),
                    ),
                  )
                ],
              ),
            ),
            Container(
              // color: Colors.lightBlueAccent,
              height: 190,
              margin: EdgeInsets.only(bottom: 10),
              // decoration: BoxDecoration(
              //   //     color: Colors.lightBlueAccent,
              //   borderRadius: BorderRadius.circular(10),
              //   border: Border.all(color: Colors.black12),
              // ),
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
            Container(
              // PAGE INDICATORSS
              padding: const EdgeInsets.all(8.0),

              child: Row(
                //mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Filled circle
                  Container(
                    width: 12,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.grey, // Filled circle color
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Unfilled circle
                  Container(
                    width: 12,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                  color: Colors.black12, // Border color
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
}
