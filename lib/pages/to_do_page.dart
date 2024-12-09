import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../firestore_service.dart';
import 'nav_bar.dart';

class ToDoPage extends StatefulWidget {
  final PageController controller;
  final String currentUserId;

  const ToDoPage(
      {super.key, required this.controller, required this.currentUserId});

  @override
  State<ToDoPage> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {


  final FirestoreService _fsService = FirestoreService();

  Stream<QuerySnapshot> _fetchTasks() {
    return FirebaseFirestore.instance.collection('tasks').snapshots();
  }

  //Catgorize tasks based on entry / due date
  Map<String, List<DocumentSnapshot>> _categorizeTasks(
      List<DocumentSnapshot> tasks) {
    final todayTasks = <DocumentSnapshot>[];
    final futureTasks = <DocumentSnapshot>[];
    final pastTasks = <DocumentSnapshot>[];

    DateTime now = DateTime.now();

    final taskByUserId =
        tasks.where((task) => task['userId'] == widget.currentUserId).toList();

    for (var task in taskByUserId) {
      dynamic dueDateRaw = task['dueDate'];
      dynamic entryDateRaw = task['entryDate'];
      DateTime? dateToEvaluate;

      try {
        if (dueDateRaw is String && dueDateRaw.isNotEmpty) {
          // If dueDate is a formatted string
          dateToEvaluate = DateFormat('MMMM d, y').parse(dueDateRaw);
        } else if (entryDateRaw is Timestamp) {
          // If dueDate is null, use entryDate
          dateToEvaluate = entryDateRaw.toDate();
        } else {
          continue;
        }
      } catch (e) {
        print("Error parsing date: $dueDateRaw or $entryDateRaw - $e");
        continue;
      }

      // Format date
      String formattedDate = DateFormat('MMMM d, y').format(dateToEvaluate);

      if (dateToEvaluate.year == now.year &&
          dateToEvaluate.month == now.month &&
          dateToEvaluate.day == now.day) {
        //Add task to Today
        todayTasks.add(task);

        print(" today: $formattedDate");
      } else if (dateToEvaluate.isBefore(now)) {
        //Add task to Past
        pastTasks.add(task);

        print(" past Date: $formattedDate");
      } else {
        //Add task to Future
        futureTasks.add(task);

        print(" fut Date: $formattedDate");
      }
    }

    return {
      'today': todayTasks,
      'future': futureTasks,
      'past': pastTasks,
    };
  }

  //Toggle task completion
  void _toggleTaskComplete(String taskId, bool? isDone) {
    if (isDone == null) return;

    //Update task complete
    _fsService.updateTaskCompletion(taskId, isDone);
  }

  Widget _taskSection(String title, List<DocumentSnapshot> tasks) {
    return ExpansionTile(
      initiallyExpanded: title == "Today",
      title: Text(
        title,
        style: const TextStyle(
            fontSize: 18, color: Colors.blueGrey, fontWeight: FontWeight.bold),
      ),
      children: tasks.map((task) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task['done'] ?? false,
                onChanged: (bool? value) {
                  _toggleTaskComplete(task.id, value);
                },
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['taskName'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    task['description'] ?? 'No Description',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("To-Do List"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching tasks!"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTasks = snapshot.data!.docs;
          final groupedTasks = _categorizeTasks(allTasks);

          return ListView(
            children: [
              _taskSection("Today", groupedTasks['today']!),
              _taskSection("Future", groupedTasks['future']!),
              _taskSection("Past", groupedTasks['past']!),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        curentIndex: -1,
        backgroundColor: Colors.white,
        onTap: (value) {
          widget.controller.animateToPage(
            value,
            duration: const Duration(milliseconds: 200),
            curve: Curves.ease,
          );
          Navigator.pop(context);
        },
        children: [
          BottomNavBarItem(title: "Home", icon: Icons.home_filled),
          BottomNavBarItem(title: "Mood", icon: Icons.mood),
          BottomNavBarItem(title: "Budget", icon: Icons.attach_money),
          BottomNavBarItem(title: "Water", icon: Icons.water_drop_outlined),
        ],
      ),
    );
  }
}
