import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:aura_journal/firestore_service.dart';
import 'package:flutter/services.dart';
//import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';

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
    _initializeNotifications();
    fetchJournalName();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();

    // Request Notification Permission
    await _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      print('Notifications denied');

      final result = await Permission.notification.request();
      if (result.isGranted) {
        print('Notification permission granted');
      } else {
        print('Notification permission denied');
      }
    } else {
      print('Notification permission already granted');
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    const platform = MethodChannel('com.example.exact_alarm_permission');
    print('Notifications');
    try {
      // Check if permission is already granted
      final bool? isPermissionGranted =
      await platform.invokeMethod('checkExactAlarmPermission');

      if (isPermissionGranted != null && isPermissionGranted) {
        print('Exact Alarm permission already granted');
        return; // Exit if permission is already granted
      }

      // If permission is not granted, navigate to the alarm settings using native code
      await platform.invokeMethod('openAlarmSettings');
    } on PlatformException catch (e) {
      print("Error requesting exact alarm permission: $e");
    }
  }

  Future<void> _scheduleNotification(DateTime scheduledTime) async {
    // Calculate the delay in seconds between now and the scheduled time
    final Duration delay = scheduledTime.difference(DateTime.now());

    if (delay.isNegative) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected time is in the past!')),
      );
      print("Error: Selected time is in the past.");
      return;
    }

    print("Notification will be displayed after ${delay.inSeconds} seconds.");

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'journal_channel', // Channel ID
      'Journal Reminders', // Channel Name
      channelDescription: 'Scheduled Test Notification',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    // Delay and trigger the notification
    Future.delayed(delay, () async {
      await flutterLocalNotificationsPlugin.show(
        1, // Notification ID
        'Scheduled Reminder', // Notification Title
        'This is your scheduled notification. ${scheduledTime
            .hour}: ${scheduledTime.minute} ', // Notification Body
        notificationDetails,
      );

      print("Notification triggered at: ${DateTime.now()}");
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification scheduled successfully')),
    );

    print("Notification scheduled for: $scheduledTime");
  }

  Future<void> _pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selected Date: ${DateFormat('MMMM d, y - hh:mm a').format(
                  _selectedDateTime!)}',
            ),
          ),
        );
      }
    }
  }

  Future<void> fetchJournalName() async {
    String? userId = fsService
        .getCurrentUser()
        ?.uid;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Container(
                  height: 400,
                  color: Colors.white70,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Journal Name',
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _journalNameController,
                        decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Color',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildRadio('English', 'English', _selectedLanguage),
                          _buildRadio('French', 'French', _selectedLanguage),
                        ],
                      ),
                      SizedBox(height: 50,),
                      ElevatedButton(
                          onPressed: () async {
                            String? userId = fsService.getCurrentUserId();

                            // add the journal name to the db
                            if (userId != null &&
                                _journalNameController.text.isNotEmpty) {
                              await fsService.updateJournalName(
                                  _journalNameController.text);
                              print(
                                  'Settings: Journal name updates to ${_journalNameController
                                      .text}');

                              fetchJournalName();
                            } else {
                              print('Please enter a journal name.');
                            }

                            widget.onColorUpdate(_getColorFromOption(_selectedColor!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Aura journal settings have been updated'),
                                duration: Duration(seconds: 5),
                              ),);
                          }, child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Update Settings'),
                            ],
                          )
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                TextButton(
                  onPressed: _pickDateTime,
                  child: const Text(
                    'Select Notification Time',
                    style: TextStyle(color: Colors.lightBlue),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    DateTime scheduledTime = _selectedDateTime!;
                    _scheduleNotification(scheduledTime);
                  },
                  child: const Text('Enable Notification'),
                ),

              ],),
          ),
        ),
      ),
    );
  }

  Color _getColorFromOption(String colorOption) {
    if (colorOption == 'Option 2') {
      return Colors.pink.shade50;
    } else if (colorOption == 'Option 3') {
      return Colors.purple.shade50;
    }
    return const Color(0xFFE3EFF9); // Default blue color
  }
}