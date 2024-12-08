import 'package:flutter/material.dart';
import 'nav_bar.dart';

class DetailedToDoPage extends StatelessWidget {
  final PageController controller;
  final String taskId;

  const DetailedToDoPage({super.key, required this.controller, required this.taskId});

  //fetch To Do details


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agenda Field"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Dropdown
        Row(
          children: [
            const Text(
              "Category",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: "Category",
              items: const [
                DropdownMenuItem(value: "Category", child: Text("Category")),
                DropdownMenuItem(value: "Work", child: Text("Work")),
                DropdownMenuItem(value: "Personal", child: Text("Personal")),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Title
        const Text(
          "Title",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Divider(color: Colors.grey, thickness: 1),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Expanded(
              flex: 3,
              child: Text(
                "Description",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Value",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Expanded(
              flex: 3,
              child: Text(
                "Due Date",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Value",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
             const Expanded(
              flex: 3,
              child: Text(
                "Location",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
             const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child:
                IconButton(
                  onPressed: () {

                  },
                  icon: const Icon(Icons.add, size: 15, color: Colors.grey,),
                ),
              ),
            ),
      ],

    ),
      ),
    ],
        ),
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
          Navigator.pop(context); // Close and navigate to the selected page
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
