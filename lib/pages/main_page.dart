import 'home_page.dart';
import 'package:aura_journal/pages/mood_page.dart';
import 'package:aura_journal/pages/budget_page.dart';
import 'package:aura_journal/pages/water_page.dart';
import 'package:aura_journal/pages/to_do_page.dart';
import 'package:flutter/material.dart';
import 'nav_bar.dart';

class MainPage extends StatefulWidget {

  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}


class _MainPageState extends State<MainPage> {
  final PageController controller = PageController(); // Initialize PageController
  int index = 0; // Initialize index to track the current page

  final List<Widget> pages = [
    const HomePage(),
    const MoodPage(),
    const BudgetPage(),
    const WaterPage(),
  ];
 // Control flag to show ToDoPage

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text("AURA JOURNAL  - change to user name"),
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
          BottomNavBarItem(
            title: "   Home   ",
            icon: Icons.home_filled,
          ),
          BottomNavBarItem(
            title: "   Mood   ",
            icon: Icons.mood,
          ),
          BottomNavBarItem(
            title: '   Budget   ',
            icon: Icons.attach_money,
          ),
          BottomNavBarItem(
            title: "   Water   ",
            icon: Icons.water_drop_outlined,
          ),
        ],
      ),
    );
  }
}
