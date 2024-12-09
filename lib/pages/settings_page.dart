import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart' hide DatePickerTheme; // Hide the conflicting import
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:aura_journal/firestore_service.dart';

class SettingsPage extends StatefulWidget {
  final String journalName;
  final ValueChanged<String> onNameUpdated;
  final ValueChanged<Color> onColorUpdate;

  const SettingsPage({
    super.key,
    required this.journalName,
    required this.onNameUpdated,
    required this.onColorUpdate,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirestoreService fsService = FirestoreService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  late TextEditingController _journalNameController;
  String? _selectedColor;
  String? _selectedLanguage;
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _journalNameController = TextEditingController(text: widget.journalName);
    _selectedColor = 'Option 1';
    _selectedLanguage = 'English';

    fetchJournalName();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones(); // Initialize time zones
  }

  Future<void> _scheduleNotification() async {
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
      );
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'journal_channel', // Channel ID
      'Journal Reminders', // Channel name
      channelDescription: 'Reminders to log your journal',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID
      'Reminder', // Notification title
      'Don’t forget to log your journal!', // Notification body
      tz.TZDateTime.from(_selectedDateTime!, tz.local), // Time in local time zone
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Fixed parameter
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification scheduled successfully')),
    );
  }

  Future<void> fetchJournalName() async {
    String? userId = fsService.getCurrentUser()?.uid;

    if (userId != null) {
      final docSnapshot = await fsService.getDocument(
        collection: 'users',
        documentId: userId,
      );
      setState(() {
        widget.onNameUpdated(docSnapshot.data()?['journalName']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                height: 350,
                color: Colors.white70,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Journal Name',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _journalNameController,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Color',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRadio('Option 1', 'Blue', _selectedColor),
                        _buildRadio('Option 2', 'Pink', _selectedColor),
                        _buildRadio('Option 3', 'Purple', _selectedColor),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Language',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRadio('English', 'English', _selectedLanguage),
                        _buildRadio('French', 'French', _selectedLanguage),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  DatePicker.showDateTimePicker(
                    context,
                    showTitleActions: true,
                    onChanged: (date) => setState(() {
                      _selectedDateTime = date;
                    }),
                    onConfirm: (date) {
                      setState(() {
                        _selectedDateTime = date;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected Date: $date'),
                        ),
                      );
                    },
                  );
                },
                child: const Text(
                  'Select Notification Time',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              ElevatedButton(
                onPressed: _scheduleNotification,
                child: const Text('Enable Notification'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadio(String value, String label, String? groupValue) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: (value) {
            setState(() {
              _selectedColor = value;
            });
          },
        ),
        Text(label),
      ],
    );
  }
}
