import 'package:flutter/material.dart';
import 'package:aura_journal/pages/home_page.dart';
import 'package:aura_journal/pages/mood_page.dart';
import 'package:aura_journal/pages/budget_page.dart';
import 'package:aura_journal/pages/water_page.dart';
import 'package:aura_journal/pages/nav_bar.dart';
import 'package:aura_journal/pages/settings_page.dart';
import 'package:aura_journal/firestore_service.dart';

class MainPage extends StatefulWidget {
  final void Function(Color) onColorUpdate;


  const MainPage({super.key, required this.onColorUpdate});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // DB connection
  final FirestoreService _fsService = FirestoreService();
  final PageController controller = PageController();
  int index = 0;
  String _journalName = "Journal"; // Default journal name

  // Control flag to show ToDoPage
  final List<Widget> pages = [];

  @override
  void initState() {
    super.initState();

    // Initialize pages inside initState to access widget properties
    pages.addAll([
      HomePage(onColorUpdate: widget.onColorUpdate),
      const MoodPage(),
      const BudgetPage(),
      const WaterPage(),
    ]);

    // Fetch the journal name from Firestore
    fetchJournalName();
  }

  // Fetch the journal name from Firestore and update the state
  Future<void> fetchJournalName() async {
    String? userId = _fsService.getCurrentUser()?.uid;

    if (userId != null) {
      try {
        // Fetch the user document from Firestore
        final docSnapshot = await _fsService.getDocument(
          collection: 'users',
          documentId: userId,
        );

        // Check if the document exists
        if (docSnapshot.exists) {
          // Extract the journal name from the document
          String journalName = docSnapshot.data()?['journalName'] ?? 'Journal';

          // Update the state to reflect the journal name
          setState(() {
            _journalName = journalName;
          });
          print('Settings: Journal Name updated in the app');
        } else {
          print('User document not found');
        }
      } catch (e) {
        print('Error fetching journal name: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_journalName), // Display journal name here
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'Settings') {
                // Navigate to Settings page and wait for the result
                final updatedName = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      journalName: _journalName,
                      onNameUpdated: _updateJournalName,
                      onColorUpdate: widget.onColorUpdate,
                    ),
                  ),
                );

                // Update the journal name if a new one was returned
                if (updatedName != null) {
                  _updateJournalName(updatedName);
                }
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
            index = value;
          });
        },
        children: pages,
      ),
      bottomNavigationBar: BottomNavBar(
        curentIndex: index,
        backgroundColor: Colors.white,
        onTap: (value) {
          setState(() {
            index = value;
            controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          });
        },
        children: [
          BottomNavBarItem(title: "   Home   ", icon: Icons.home_filled),
          BottomNavBarItem(title: "   Mood   ", icon: Icons.mood),
          BottomNavBarItem(title: '   Budget   ', icon: Icons.attach_money),
          BottomNavBarItem(title: "   Water   ", icon: Icons.water_drop_outlined),
        ],
      ),
    );
  }

  // Update journal name and refresh AppBar title
  void _updateJournalName(String newName) {
    setState(() {
      _journalName = newName;
    });
  }
}
