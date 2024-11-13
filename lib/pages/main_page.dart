import 'package:flutter/material.dart';
import 'package:aura_journal/pages/home_page.dart';
import 'package:aura_journal/pages/mood_page.dart';
import 'package:aura_journal/pages/budget_page.dart';
import 'package:aura_journal/pages/water_page.dart';
import 'package:aura_journal/pages/nav_bar.dart';
import 'package:aura_journal/pages/settings_page.dart';

class MainPage extends StatefulWidget {
  final void Function(Color) onColorUpdate;

  const MainPage({super.key, required this.onColorUpdate});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final PageController controller =
      PageController();
  int index = 0;
  String _journalName = "Journal";

  final List<Widget> pages = [
    const HomePage(),
    const MoodPage(),
    const BudgetPage(),
    const WaterPage(),
  ];
  // Control flag to show ToDoPage

  // Update journal name and refresh AppBar title
  void _updateJournalName(String newName) {
    setState(() {
      _journalName = newName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_journalName),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'Settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      journalName: _journalName,
                      onNameUpdated: _updateJournalName,
                      onColorUpdate: widget.onColorUpdate,
                    ),
                  ),
                ).then((updatedName) {
                  if (updatedName != null) {
                    _updateJournalName(updatedName);
                  }
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'Settings',
                child: Text('Settings'),
              ),
            ],
          ),
        ],
      ),
      body: PageView(
        scrollDirection: Axis.horizontal,
        controller: controller,
        onPageChanged: (value) {
          setState(() {
            index = value; // Update the index when page changes
          });
        },
        children: pages, // Use the pages list for PageView
      ),
      bottomNavigationBar: BottomNavBar(
        curentIndex: index,
        backgroundColor: Colors.white,
        onTap: (value) {
          setState(() {
            index = value; // Update the index
            controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            ); // Animate to the selected page
          });
        },
        children: [
          BottomNavBarItem(title: "   Home   ", icon: Icons.home_filled),
          BottomNavBarItem(title: "   Mood   ", icon: Icons.mood),
          BottomNavBarItem(title: '   Budget   ', icon: Icons.attach_money),
          BottomNavBarItem(
              title: "   Water   ", icon: Icons.water_drop_outlined),
        ],
      ),
    );
  }
}
