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



  //
  // Future<void> _scheduleNotification() async {
  //   // Request exact alarm permission
  //   await _requestExactAlarmPermission();
  //   await _requestNotificationPermission();
  //
  //   if (_selectedDateTime == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please select a date and time')),
  //     );
  //     return;
  //   }
  //
  //   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  //     'journal_channel', // Channel ID
  //     'Journal Reminders', // Channel Name
  //     channelDescription: 'Reminders to log your journal',
  //     importance: Importance.high,
  //     priority: Priority.high,
  //   );
  //
  //   const NotificationDetails notificationDetails =
  //   NotificationDetails(android: androidDetails);
  //
  //   await flutterLocalNotificationsPlugin.zonedSchedule(
  //     0,
  //     'Reminder',
  //     'Don’t forget to log your journal!',
  //     tz.TZDateTime.from(_selectedDateTime!, tz.local),
  //     notificationDetails,
  //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //     uiLocalNotificationDateInterpretation:
  //     UILocalNotificationDateInterpretation.absoluteTime,
  //   );
  //
  //
  //   print("Notification scheduled for: $_selectedDateTime");
  //
  //   print("Current time: ${DateTime.now()}");
  //   print("Scheduled time: $_selectedDateTime");
  //
  //
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Notification scheduled successfully')),
  //   );
  // }
  //

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

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
        'This is your scheduled notification. ${scheduledTime.hour}: ${scheduledTime.minute} ', // Notification Body
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
              'Selected Date: ${DateFormat('MMMM d, y - hh:mm a').format(_selectedDateTime!)}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _showImmediateNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'journal_channel', 'Journal Reminders',
      channelDescription: 'Immediate Test Notification',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Test Notification',
      'This is an immediate test notification',
      notificationDetails,
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
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Language',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _pickDateTime,
                child: const Text(
                  'Select Notification Time',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  DateTime scheduledTime = _selectedDateTime!;
                  _scheduleNotification(scheduledTime);
                },
                child: const Text('Enable Notification'),
              ),
              ElevatedButton(
                onPressed: _showImmediateNotification,
                child: const Text('Test Immediate Notification'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
