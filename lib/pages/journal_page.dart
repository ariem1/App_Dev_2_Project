import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'settings_page.dart';

class JournalPage extends StatefulWidget {
  final void Function(Color) onColorUpdate;

  final DateTime selectedDate;

  const JournalPage({super.key, required this.selectedDate, required this.onColorUpdate });

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {

  String _journalName = "Journal";

  // Update journal name and refresh AppBar title
  void _updateJournalName(String newName) {
    setState(() {
      _journalName = newName;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entry'),
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
      body: Center(
        child: Column(
          children: [
            Container()
          ],
        )
      ),
    );
  }
}
