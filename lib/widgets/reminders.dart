import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class Reminder {
  final String type;
  final DateTime dateTime;

  Reminder({required this.type, required this.dateTime});

  Map<String, dynamic> toMap() => {
        'type': type,
        'dateTime': dateTime.toIso8601String(),
      };

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      type: map['type'] ?? 'Unknown',
      dateTime: map['dateTime'] != null
          ? DateTime.parse(map['dateTime'])
          : DateTime.now(),
    );
  }
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<Reminder> _reminders = [];
  bool _showForm = false;

  String? _selectedReminderType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<String> _reminderTypes = [
    'Electricity Bill',
    'Rent Payment',
    'Mobile Recharge',
    'Credit Card Bill',
    'SIP Investment Reminder',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndLoadReminders();
  }

  Future<void> _initializeFirebaseAndLoadReminders() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.signInAnonymously();
    _loadReminders();
  }

  Future<void> _setReminder() async {
    if (_selectedReminderType != null &&
        _selectedDate != null &&
        _selectedTime != null) {
      final fullDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final newReminder = Reminder(
        type: _selectedReminderType!,
        dateTime: fullDateTime,
      );

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('reminders')
            .add(newReminder.toMap());
      }

      setState(() {
        _reminders.add(newReminder);
        _selectedReminderType = null;
        _selectedDate = null;
        _selectedTime = null;
        _showForm = false;
      });
    }
  }

  Future<void> _loadReminders() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('reminders')
        .get();

    setState(() {
      _reminders.clear();
      for (var doc in snapshot.docs) {
        _reminders.add(Reminder.fromMap(doc.data()));
      }
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  final reminder = _reminders[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.alarm),
                      title: Text(reminder.type),
                      subtitle: Text('${reminder.dateTime}'),
                    ),
                  );
                },
              ),
            ),
            if (_showForm)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: _reminderTypes.contains(_selectedReminderType)
                        ? _selectedReminderType
                        : null,
                    hint: const Text("Select Reminder Type"),
                    isExpanded: true,
                    items: _reminderTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedReminderType = value),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate == null
                          ? 'Pick Date'
                          : '${_selectedDate!.toLocal()}'.split(' ')[0],
                    ),
                    onPressed: _pickDate,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _selectedTime == null
                          ? 'Pick Time'
                          : _selectedTime!.format(context),
                    ),
                    onPressed: _pickTime,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _setReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Set Reminder"),
                  ),
                ],
              ),
            if (!_showForm)
              ElevatedButton.icon(
                icon: const Icon(Icons.add_alert),
                label: const Text("Set New Reminder"),
                onPressed: () => setState(() => _showForm = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
