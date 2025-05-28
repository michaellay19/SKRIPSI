import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminShiftDialog extends StatefulWidget {
  const AdminShiftDialog({super.key});

  @override
  State<AdminShiftDialog> createState() => _AdminShiftDialogState();
}

class _AdminShiftDialogState extends State<AdminShiftDialog> {
  final _auth = FirebaseAuth.instance;
  Map<String, TimeOfDay> shiftTimes = {
    'Shift 1 Start': const TimeOfDay(hour: 7, minute: 0),
    'Shift 1 End': const TimeOfDay(hour: 15, minute: 0),
    'Shift 2 Start': const TimeOfDay(hour: 15, minute: 0),
    'Shift 2 End': const TimeOfDay(hour: 23, minute: 0),
    'Late Tolerance': const TimeOfDay(hour: 0, minute: 15),
    'No Daily Wage Tolerance': const TimeOfDay(hour: 0, minute: 30),
  };

  Map<String, List<String>> shiftDays = {
    'Shift 1': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    'Shift 2': ['Saturday', 'Sunday'],
  };

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    final uid = _auth.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('admin').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (data['shiftTimes'] != null) {
        setState(() {
          shiftTimes = Map<String, dynamic>.from(data['shiftTimes']).map((key, value) {
            final time = TimeOfDay(
              hour: int.parse(value.split(":")[0]),
              minute: int.parse(value.split(":")[1]),
            );
            return MapEntry(key, time);
          });
        });
      }
      if (data['shiftDays'] != null) {
        setState(() {
          shiftDays = Map<String, dynamic>.from(data['shiftDays']).map((key, value) {
            return MapEntry(key, List<String>.from(value));
          });
        });
      }
    }
  }

  Future<void> _saveShifts() async {
    final uid = _auth.currentUser!.uid;
    final shiftTimeStr =
        shiftTimes.map((key, value) => MapEntry(key, "${value.hour}:${value.minute.toString().padLeft(2, '0')}"));

    await FirebaseFirestore.instance.collection('admin').doc(uid).set({
      'shiftTimes': shiftTimeStr,
      'shiftDays': shiftDays,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Shift Configuration", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...shiftTimes.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                trailing: Text(entry.value.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: entry.value,
                  );
                  if (picked != null) {
                    setState(() {
                      shiftTimes[entry.key] = picked;
                    });
                  }
                },
              );
            }),
            const Divider(),
            ...shiftDays.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${entry.key} Days"),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (var day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'])
                        FilterChip(
                          label: Text(day),
                          selected: entry.value.contains(day),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                shiftDays[entry.key]!.add(day);
                              } else {
                                shiftDays[entry.key]!.remove(day);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              );
            }),
            TextButton(
              onPressed: () async {
                await _saveShifts();
                Navigator.pop(context);
              },
              child: const Text("Save Settings", style: TextStyle(fontSize: 20)),
            )
          ],
        ),
      ),
    );
  }
}
