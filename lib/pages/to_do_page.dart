import 'package:flutter/material.dart';
import 'nav_bar.dart'; // Import the BottomNavBar class

class ToDoPage extends StatelessWidget {
  final PageController controller;

  const ToDoPage({super.key, required this.controller});

  // A helper method to build task cards
  Widget _buildTaskCard(String title, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.purpleAccent, // Purple border to match the screenshot
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_box, color: Colors.black), // Checkbox icon
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
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
  }

  @override
  Widget build(BuildContext context) {
    // Example tasks for Today, Future, and Past sections
    final todayTasks = [
      {"title": "Label", "description": "Description"},
      {"title": "Label", "description": "Description"},
    ];

    final futureTasks = [
      {"title": "Future Task 1", "description": "Description"},
    ];

    final pastTasks = [
      {"title": "Past Task 1", "description": "Description"},
      {"title": "Past Task 2", "description": "Description"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("To-Do List"),
      ),
      body: ListView(
        children: [
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text(
              "Today",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: todayTasks
                .map((task) => _buildTaskCard(task["title"]!, task["description"]!))
                .toList(),
          ),
          ExpansionTile(
            title: const Text(
              "Future",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: futureTasks
                .map((task) => _buildTaskCard(task["title"]!, task["description"]!))
                .toList(),
          ),
          ExpansionTile(
            title: const Text(
              "Past",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: pastTasks
                .map((task) => _buildTaskCard(task["title"]!, task["description"]!))
                .toList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        curentIndex: -1,
        backgroundColor: Colors.white,
        onTap: (value) {

          controller.animateToPage(
            value,
            duration: const Duration(milliseconds: 200),
            curve: Curves.ease,
          );
          Navigator.pop(context); // Close ToDoPage and return go to page i clicked like budget
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
