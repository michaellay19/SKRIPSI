import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/model/activity_tile_model.dart';
import 'package:skripsi/model/attendance_card_model.dart';
import 'package:skripsi/model/leave_request_model.dart';
import 'package:skripsi/pages/users/home/camera_page.dart';
import 'package:skripsi/provider/camera_provider.dart';
import 'package:skripsi/provider/profile_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late double geofenceLatitude;
  late double geofenceLongitude;
  late double geofenceRadius;
  bool isGeofenceLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkUserFaceData();
    _loadGeofenceData();
  }

  void _checkUserFaceData() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await profileProvider.loadProfile();

    if (profileProvider.faceImage.isEmpty) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CameraPage(activityType: 'Face Register'),
          ),
        );
      });
    }
  }

  Future<void> _loadGeofenceData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('geofence').doc('location').get();
    if (doc.exists) {
      setState(() {
        geofenceLatitude = (doc['latitude'] as num).toDouble();
        geofenceLongitude = (doc['longitude'] as num).toDouble();
        geofenceRadius = (doc['radius'] as num).toDouble();
        isGeofenceLoaded = true;
      });
    }
  }

  Future<bool> _isInsideGeofence() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied. Please enable it in settings.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied. Enable them in settings.')),
      );
      return false;
    }

    Position position = await Geolocator.getCurrentPosition();
    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      geofenceLatitude,
      geofenceLongitude,
    );

    print('distance: $position');

    return distance <= geofenceRadius;
  }

  void _attemptClock(String activityType) async {
    if (!isGeofenceLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geofence data not loaded. Please try again.')),
      );
      return;
    }

    bool insideGeofence = await _isInsideGeofence();
    if (insideGeofence) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPage(activityType: activityType),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are outside the designated area!')),
      );
    }
  }

  TextStyle _getTimeAndSubtitleStyle(String time, {required bool isCheckIn}) {
    final hour = int.tryParse(time.split(":").first) ?? 0;

    if (((isCheckIn && hour >= 9) || (!isCheckIn && hour < 17) && time != "-")) {
      return const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
    }

    return const TextStyle(color: Colors.black, fontWeight: FontWeight.normal);
  }

  String _getSubtitle(String time, {required bool isCheckIn}) {
    final hour = int.tryParse(time.split(":").first) ?? 0;

    if (time == "-") {
      return isCheckIn ? "Not Clocked In" : "Not Clocked Out";
    }

    if (isCheckIn) {
      return hour >= 9 ? "Clock In Late" : "On Time";
    }

    return hour < 17 ? "Early Clock Out" : "Go Home";
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    final profileImage = profileProvider.profileImage;
    final userName = profileProvider.name;
    final userPosition = profileProvider.position;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: profileProvider.profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
              child: profileProvider.profileImage.isEmpty
                  ? const Icon(Icons.admin_panel_settings, size: 40, color: Colors.blueAccent)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  userPosition,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
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
              stream: Provider.of<CameraProvider>(context, listen: false).fetchActivities(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final activities = snapshot.data ?? [];
                final nowDate = DateTime.now().toFormattedString();

                final clockInActivity = activities.firstWhere(
                  (activity) => activity['activityType'] == 'Clock In' && activity['date'] == nowDate,
                  orElse: () => {'time': '-'},
                );
                final clockOutActivity = activities.firstWhere(
                  (activity) => activity['activityType'] == 'Clock Out' && activity['date'] == nowDate,
                  orElse: () => {'time': '-'},
                );

                final clockInTime = clockInActivity['time'] ?? '-';
                final clockOutTime = clockOutActivity['time'] ?? '-';

                return Column(
                  children: [
                    Row(
                      children: [
                        AttendanceCard(
                          title: "Clock In",
                          time: clockInTime,
                          subtitle: _getSubtitle(clockInTime, isCheckIn: true),
                          timeStyle: _getTimeAndSubtitleStyle(clockInTime, isCheckIn: true),
                          subtitleStyle: _getTimeAndSubtitleStyle(clockInTime, isCheckIn: true),
                        ),
                        const SizedBox(width: 16),
                        AttendanceCard(
                          title: "Clock Out",
                          time: clockOutTime,
                          subtitle: _getSubtitle(clockOutTime, isCheckIn: false),
                          timeStyle: _getTimeAndSubtitleStyle(clockOutTime, isCheckIn: false),
                          subtitleStyle: _getTimeAndSubtitleStyle(clockOutTime, isCheckIn: false),
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
                    onPressed: () => _attemptClock('Clock In'),
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
                    onPressed: () => _attemptClock('Clock Out'),
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
                stream: Provider.of<CameraProvider>(context, listen: false).fetchActivities(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('An error occurred: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No activities recorded yet.'));
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
