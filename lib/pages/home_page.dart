import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/provider/camera_provider.dart';
import 'package:skripsi/pages/camera_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextStyle _getTimeAndSubtitleStyle(String time, {required bool isCheckIn}) {
    final timeParts = time.split(":");
    final hour = int.tryParse(timeParts[0]) ?? 0;

    if (isCheckIn) {
      if (hour >= 9) {
        return const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
      }
    } else {
      if (hour < 17) {
        return const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
      }
    }

    return const TextStyle(color: Colors.black, fontWeight: FontWeight.normal);
  }

  String _getSubtitle(String time, {required bool isCheckIn}) {
    final timeParts = time.split(":");
    final hour = int.tryParse(timeParts[0]) ?? 0;

    if (isCheckIn) {
      if (hour >= 9) {
        return "Check In Late";
      }
      return "On Time";
    } else {
      if (hour < 17) {
        return "Early Check Out";
      }
      return "Go Home";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc('uid')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        snapshot.data!['profileImage'].startsWith('http')
                            ? NetworkImage(snapshot.data!['profileImage'])
                            : FileImage(File(snapshot.data!['profileImage'])),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.data!['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        snapshot.data!['role'] ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              return const Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('images/profile.jpeg'),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unknown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '-',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              "Today Attendance",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Provider.of<CameraProvider>(context, listen: false)
                  .fetchActivities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No activities found.'));
                }
                final activities = snapshot.data!;
                String clockInTime = "-";
                String clockOutTime = "-";
                final nowDate = DateTime.now().toString().substring(0, 10);
                for (var activity in activities) {
                  if (activity['activityType'] == 'Clock In' &&
                      activity['date'] == nowDate) {
                    clockInTime = activity['time'];
                  } else if (activity['activityType'] == 'Clock Out' &&
                      activity['date'] == nowDate) {
                    clockOutTime = activity['time'];
                  }
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        AttendanceCard(
                          title: "Check In",
                          time: clockInTime,
                          subtitle: clockInTime == "-"
                              ? "Not Checked In"
                              : _getSubtitle(clockInTime, isCheckIn: true),
                          timeStyle: _getTimeAndSubtitleStyle(clockInTime,
                              isCheckIn: true),
                          subtitleStyle: _getTimeAndSubtitleStyle(clockInTime,
                              isCheckIn: true),
                        ),
                        const SizedBox(width: 16),
                        AttendanceCard(
                          title: "Check Out",
                          time: clockOutTime,
                          subtitle: clockOutTime == "-"
                              ? "Not Checked Out"
                              : _getSubtitle(clockOutTime, isCheckIn: false),
                          timeStyle: _getTimeAndSubtitleStyle(clockOutTime,
                              isCheckIn: false),
                          subtitleStyle: _getTimeAndSubtitleStyle(clockOutTime,
                              isCheckIn: false),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CameraPage(activityType: 'Clock In'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Clock In",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CameraPage(activityType: 'Clock Out'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Clock Out",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Your Activity",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Provider.of<CameraProvider>(context, listen: false)
                    .fetchActivities(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No activities found.'));
                  }

                  final activities = snapshot.data!;
                  return ListView.builder(
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return ActivityTile(
                        title: activity['activityType'] ?? 'Unknown',
                        time: activity['time'],
                        date: activity['date'],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceCard extends StatelessWidget {
  final String title;
  final String time;
  final String subtitle;
  final TextStyle? timeStyle;
  final TextStyle? subtitleStyle;

  const AttendanceCard({
    required this.title,
    required this.time,
    required this.subtitle,
    this.timeStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: timeStyle ??
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: subtitleStyle ?? const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  final String title;
  final String time;
  final String date;

  const ActivityTile({
    required this.title,
    required this.time,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(date),
        trailing: Text(
          time,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
