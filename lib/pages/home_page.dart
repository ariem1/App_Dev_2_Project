import 'package:aura_journal/pages/detailed_to_do_page.dart';
import 'package:aura_journal/pages/journal_page.dart';
import 'package:aura_journal/pages/main_page.dart';
import 'package:aura_journal/pages/map_page.dart';
import 'package:aura_journal/pages/to_do_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aura_journal/firestore_service.dart';

class HomePage extends StatefulWidget {
  final void Function(Color) onColorUpdate;
  final PageController controller;

  const HomePage({
    super.key,
    required this.onColorUpdate,
    required this.controller,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //db connection
  final FirestoreService _fsService = FirestoreService();

  String? currentUserId;
  String? todaysJournalId;
  double spending = 0.0;

  @override
  void initState() {
    super.initState();

    //initialize current user
    initializeUserId();
    print('Home: $currentUserId');

    initializeTodaysJournalId();

    //GETS JOURNAL DATA
    _getJournalData();

    //get the tasks
    _getTasks();
  }

  Future<void> initializeTodaysJournalId() async {
    try {
      String? journalId =
          await _fsService.getJournalIdByUserIdAndDate_2(currentUserId!);

      setState(() {
        todaysJournalId = journalId;
      });

      if (todaysJournalId == null) {
        print("No entry yet for today.");
      } else {
        print("Journal ID: $todaysJournalId");
      }
    } catch (e) {
      print("Error initializing today's journal ID: $e");
    }
  }

  Future<void> initializeUserId() async {
    setState(() {
      currentUserId = _fsService.getCurrentUserId();
    });

    if (currentUserId == null) {
      print("No user is currently signed in.");
    } else {
      print("User ID: $currentUserId");
    }
  }

  Future<void> _getJournalData() async {
    try {
      final journalData = await _fsService.fetchJournalData(currentUserId);

      print('current user id: $currentUserId');
      if (journalData.isEmpty) {
        print('No journal data available.');
        return;
      }

      final int waterCount = (journalData['water'] as int? ?? 0).clamp(0, 8);

      setState(() {
        _selectedMood = journalData['mood'];
        spending = (journalData['balance']).toDouble() ;
        droplets = List.generate(
          waterCount,
              (_) => const Icon(
            Icons.water_drop_outlined,
            size: 27,
          ),
        );
      });


      print('Journal data loaded: $journalData');
    } catch (e) {
      print('Error fetching journal data: $e');
    }
  }

  bool isLoading = true;

  Future<void> _getTasks() async {
    try {
      final taskData = await _fsService.fetchAllTasksByUser(currentUserId!);

      setState(() {
        tasks = taskData;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching tasks: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  //todays date
  DateTime today = DateTime.now();

  // Go to Journal page
  void _onDaySelected(DateTime day, DateTime focusedDay) async {
    print('focused day ${focusedDay}');
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

    //If journal doesnt exist, make an entry
    bool journalExists = await _checkJournalEntry();

    if (!journalExists && focusedDay != DateTime.now()) {
      await _fsService.addJournalEntry(0, -1, '', currentUserId!);
      print('Journal entry created');
    }

    // Go to Journal page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalPage(
          selectedDate: today,
          onColorUpdate: widget.onColorUpdate,
          currentUserId: currentUserId,
        ),
      ),
    );

    print("Selected day is: $selectedDay ");
  }

  List<Map<String, dynamic>> tasks = [];

  //Toggle task completion
  void _toggleTaskComplete(int index, String taskId, bool value) {
    print('Before toggle: ${tasks[index]}');

    setState(() {
      tasks[index]['done'] = value ?? false;
    });

    print('After toggle: ${tasks[index]}');

    // Update task in Firestore
    _fsService.updateTaskCompletion(taskId, value);
  }

  TextEditingController taskController = TextEditingController();

  // Add task to the firebase
  void addTask(String userId, String task) async {
    if (taskController.text.isNotEmpty) {
      if (currentUserId != null) {
        // Add task to Firebase and fetch newly added task
        final newTask = await _fsService.addtask(currentUserId!, task);

        if (newTask != null) {
          setState(() {
            tasks.add({
              "taskId": newTask['taskId'],
              "taskName": newTask['taskName'],
              "done": newTask['done'],
              "dueDate": newTask['dueDate'],
            });

            print('Current tasks list: $tasks');
          });
        }
        taskController.clear();
      }
    }
  }

  /* FIREBASE STUFF */
// Check if journal entry exists for today
  Future<bool> _checkJournalEntry() async {
    bool journalExists =
        await _fsService.journalEntryExistsForToday(currentUserId!);
    print('Journal exists: $journalExists');

    return journalExists;
  }

  // List to store water drop icons
  List<Widget> droplets = [];

  void _addDroplet() async {

    if (droplets.length >= 7) {
      print(droplets.length);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Congratulations!"),
          content: Text("You have completed 8 cups of water for the day!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        ),
      );

        // Increment the cup count in Firestore
        await _fsService.incrementCupsDrank(todaysJournalId!);

        // Reset droplets
        setState(() {
          droplets.clear();
        });

        print("Completed a cup! Droplets reset.");
      // }

      return;
    } else {

      setState(() {
        droplets.add(
            Icon(Icons.water_drop_outlined, size: 27)); // Add a new droplet
      });
    }

    print("Current droplets: ${droplets.length}");

    bool journalExists = await _checkJournalEntry();

    if (!journalExists) {
      await _fsService.addJournalEntry(droplets.length, 5, '', currentUserId!);
      print('Journal entry created and water added');
    } else {
      _fsService.updateJournalWater(todaysJournalId!, droplets.length);
    }


  }

  /////////////// MOOD ///////////////////

  int _selectedMood = -1; // DEFAULT

  Icon _buildIcon(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.sentiment_very_dissatisfied);
      case 1:
        return const Icon(Icons.sentiment_dissatisfied);
      case 2:
        return const Icon(Icons.sentiment_neutral);
      case 3:
        return const Icon(Icons.sentiment_satisfied);
      case 4:
        return const Icon(Icons.sentiment_very_satisfied);
      default:
        return const Icon(Icons.star_border);
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

  /*BUDGET STUFF*/

  TextEditingController budgetController = TextEditingController();
  CollectionReference spendings =
      FirebaseFirestore.instance.collection('spendings');
  double amount = 0.0;
  String description = '';
  Future<void> addSpending() async {
    try {
      // Ensure there's a journal entry for today
      bool entryExists = await _checkJournalEntry();

      if (!entryExists) {
        await _fsService.addJournalEntry(0, -1, '', currentUserId!);
        print('Journal entry created');
      }

      // Fetch today's journal ID
      String? journalId =
          await _fsService.getJournalIdByUserIdAndDate_2(currentUserId!);

      if (journalId == null || journalId.isEmpty) {
        print('No journal ID found. Creating journal failed.');
        return;
      }
      print('Journal ID: $journalId');

      // Fetch budget ID associated with the journal
      String? budgetId = await _fsService.getBudgetIdForJournal(journalId);

      if (budgetId == null || budgetId.isEmpty) {
        print('No budget ID found for the journal');
        return;
      }
      print('Budget ID: $budgetId');

      // Parse the spending amount
      double spendingAmount = double.tryParse(budgetController.text) ?? 0.0;
      if (spendingAmount <= 0) {
        print('Invalid spending amount');
        return;
      }

      // Add the spending to Firestore
      await spendings.add({
        'budgetId': budgetId,
        'amount': spendingAmount,
        'description': description.isNotEmpty ? description : 'No description',
        'timestamp': Timestamp.now(),
      });

      // Update the journal's balance in Firestore
      DocumentReference journalRef =
          FirebaseFirestore.instance.collection('journals').doc(journalId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(journalRef);

        if (!snapshot.exists) {
          throw Exception("Journal document does not exist!");
        }

        double currentBalance = (snapshot['balance'] ?? 0).toDouble();
        double updatedBalance = currentBalance - spendingAmount;

        // Update balance field
        transaction.update(journalRef, {'balance': updatedBalance});
        print('Balance updated to: $updatedBalance');

        // Update the UI
        if (mounted) {
          setState(() {
            spending = updatedBalance;
            description = '';
            budgetController.clear();
          });
        }
      });

      print('Spending added and balance updated successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Spending added successfully!")),
      );
    } catch (e) {
      print('Error adding spending: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
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
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.water_drop_outlined, size: 70),
                    Expanded(
                      // Wrap this part with Expanded instead
                      child: Container(
                        margin: EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Today's Water Intake"),
                            SizedBox(height: 10),
                            Row(children: droplets),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                       onPressed:  _addDroplet,
                    ),
                  ],
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
                                onPressed: () async {
                                  // add mood to journal entry of the day

                                  //If journal doesnt exist, make an entry
                                  bool journalExists =
                                      await _checkJournalEntry();

                                  if (!journalExists) {
                                    await _fsService.addJournalEntry(
                                        0, index, '', currentUserId!);
                                    print(
                                        'Journal entry created and mood added');
                                  } else {
                                    //If journal exists, update the mood
                                    //update mood
                                    _fsService.updateJournalMood(
                                        todaysJournalId!, index);
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
                      width: 175,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Budget"),
                          SizedBox(height: 10),
                          Row(children: [
                            Text("Balance: \$ "),
                            Text(spending.toStringAsFixed(2)),
                          ]),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 60, // Set your desired width
                      child: TextField(
                        controller: budgetController,
                        onChanged: (value) =>
                            amount = double.tryParse(value) ?? 0.0,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () async {
                          addSpending();
                          FocusScope.of(context).unfocus();
                        }),
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
                        color: Colors.black,
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

  Widget toDoView() {
    return SingleChildScrollView(
      child: Container(
        height: 330,
        margin: EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      // Go to View/Detailed To Do page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ToDoPage(
                            controller: widget.controller,
                            onColorUpdate: widget.onColorUpdate,
                            currentUserId: currentUserId!,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'View',
                      style: TextStyle(fontSize: 17, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            // To-Do List
            Flexible(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : tasks.isEmpty
                      ? Center(child: Text('No tasks found.'))
                      : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.black12,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                leading: Checkbox(
                                  value: task['done'] ?? false,
                                  onChanged: (bool? value) {
                                    _toggleTaskComplete(
                                        index, task['taskId'], value!);
                                  },
                                ),
                                title: Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () async {
                                      // Open the detailed view of the to-do

                                      print(
                                          '${task['taskId']} ${task['taskName']} ');
                                      // Go to Journal page
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DetailedToDoPage(
                                            onColorUpdate: widget.onColorUpdate,
                                            controller: widget.controller,
                                            taskId: task['taskId'],
                                          ),
                                        ),
                                      );

                                      // Check if a task was deleted and refresh home page
                                      if (result == true) {
                                        _getTasks();
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      alignment: Alignment.centerLeft,
                                    ),
                                    child: Text(
                                      task['taskName'] ?? 'No task name',
                                      style: TextStyle(
                                        decoration: (task['done'] ?? false)
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        color: (task['done'] ?? false)
                                            ? Colors.grey
                                            : Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            // Task Input Field
            Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: taskController,
                      onSubmitted: (value) {
                        FocusScope.of(context).unfocus();
                      },
                      decoration: InputDecoration(
                        hintText: "Enter a new task",
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      addTask(currentUserId!, taskController.text.trim());
                      FocusScope.of(context).unfocus();
                    },
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
                    decoration: const BoxDecoration(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // For keyboard, to avoid overflow
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar Container
              Container(
                height: MediaQuery.of(context).size.height *
                    0.4, // 40% of screen height
                margin:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: SingleChildScrollView(
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
                        String dayPart = DateFormat('EEE, MMM d').format(today);
                        String monthYearPart =
                            DateFormat('MMM yyyy').format(date);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 160,
                                child: Text(
                                  dayPart,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
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
              ),

              // PageView Container
              Container(
                height: MediaQuery.of(context).size.height *
                    0.4, // 40% of screen height
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PageView(
                  controller: _pageController,
                  children: [
                    easyView(),
                    toDoView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
