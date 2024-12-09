import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firestore_service.dart';
import 'map_page.dart';
import 'nav_bar.dart';

class DetailedToDoPage extends StatefulWidget {
  final PageController controller;
  final void Function(Color) onColorUpdate;
  final String taskId;

  const DetailedToDoPage({
    super.key,
    required this.controller,
    required this.onColorUpdate,
    required this.taskId,
  });

  @override
  State<DetailedToDoPage> createState() => _DetailedToDoPageState();
}

class _DetailedToDoPageState extends State<DetailedToDoPage> {
  final FirestoreService _fsService = FirestoreService();
  String? selectedCategory = "Category";
  String actionButton = "Edit";

  Map<String, dynamic> _taskData = {};
  bool _isLoading = true;
  bool isEditing = false;

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeTaskDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row(
                  //   children: [
                  //     DropdownButton<String>(
                  //       value: selectedCategory,
                  //       items: const [
                  //         DropdownMenuItem(
                  //             value: "Category", child: Text("Category")),
                  //         DropdownMenuItem(value: "Work", child: Text("Work")),
                  //         DropdownMenuItem(
                  //             value: "Personal", child: Text("Personal")),
                  //       ],
                  //       onChanged: (value) {
                  //         setState(() {
                  //           selectedCategory = value;
                  //         });
                  //       },
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(height: 30),
                  _fieldRow("Title", _titleController),

                  _fieldRow("Description", _descriptionController),
                  _fieldRow("Due Date", _dueDateController),
                  _fieldLocationRow("Location", _locationController),

                  //     _buildFieldRow("Location", _locationController),
                  const SizedBox(height: 10),
                ],
              ),
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit and Delete buttons
          _actionButtons(),
          BottomNavBar(
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
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                if (isEditing) {
                  // Save
                  print("Task edit saved.");
                  _updateTask(
                      _titleController.text,
                      _descriptionController.text,
                      _dueDateController.text,
                      _locationController.text);
                }

                isEditing = !isEditing;
              });
            },
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            label: Text(isEditing ? "Save" : "Edit"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade300,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _deleteTask,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text("Delete"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade300,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldRow(String title, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: isEditing
                ? title == "Due Date"
                    ? GestureDetector(
                        onTap: () => _selectDate(context, controller),
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 202,
                                child: Text(
                                  controller.text.isNotEmpty
                                      ? controller.text
                                      : 'Select a date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.grey,
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear,
                                    size: 18, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    controller.clear(); // Clear the date
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    : TextField(
                        maxLines: null,
                        controller: controller,
                        style: TextStyle(
                            fontSize: title == "Title" ? 35 : 16,
                            color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Enter $title',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      controller.text.isNotEmpty ? controller.text : '',
                      style: TextStyle(
                        fontSize: title == "Title" ? 35 : 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLocationRow(String title, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          SizedBox(
            width: 20,
          ),
          Expanded(
            flex: 3,
            child: isEditing
                ? TextField(
                    controller: controller,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Enter $title',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      controller.text.isNotEmpty ? controller.text : '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () async {
                  // Open the MapPage to select a location
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapPage(
                        onColorUpdate: widget.onColorUpdate,
                        taskId: widget.taskId,
                      ),
                    ),
                  );

                  // Update location if result is true
                  if (result == true) {
                    initializeTaskDetails();
                  }
                },
                icon: const Icon(
                  Icons.add,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Select due date
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final String formattedDate = DateFormat('MMMM d, y').format(pickedDate);

      setState(() {
        controller.text = formattedDate;
      });
    }
  }

  //////   FIREBASE STUFF
  // Fetch task details and update state
  Future<void> initializeTaskDetails() async {
    final fetchedTaskData = await _fsService.fetchATask(widget.taskId);
    setState(() {
      _taskData = fetchedTaskData;
      _isLoading = false;

      // Initialize controllers
      _titleController.text = _taskData['taskName'] ?? '';
      _descriptionController.text = _taskData['description'] ?? '';
      _dueDateController.text = _taskData['dueDate'] ?? '';
      _locationController.text = _taskData['location'] ?? '';
    });
  }

  // Update Task
  Future<void> _updateTask(String taskName, String description, String dueDate,
      String location) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .update({
        'taskName': taskName,
        'description': description,
        'dueDate': dueDate,
        'location': location,
      });

      print('Task updated successfully!');
    } catch (e) {
      print('Error updating task: $e');
      print('Failed to update task. Please try again.');
    }
  }

  // Delete task
  Future<void> _deleteTask() async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .delete();
    Navigator.pop(context, true);
  }
}
