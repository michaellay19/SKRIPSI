import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/model/activity_tile_model.dart';
import 'package:skripsi/model/attendance_card_model.dart';
import 'package:skripsi/model/leave_request_model.dart';
import 'package:skripsi/pages/users/home/camera_page.dart';
import 'package:skripsi/provider/attendance_provider.dart';
import 'package:skripsi/provider/geofence_provider.dart';
import 'package:skripsi/provider/profile_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  late GeofenceProvider geofenceProvider;
  bool _isGeofenceInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkUserFaceData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isGeofenceInitialized) {
      geofenceProvider = Provider.of<GeofenceProvider>(context, listen: false);
      _isGeofenceInitialized = true;
    }
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

  void _attemptClock(String activityType) async {
    bool insideGeofence = await geofenceProvider.isInsideGeofence(context);

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

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                height: 300,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image, size: 50));
                  },
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final profileImage = profileProvider.profileImage;
    final userName = profileProvider.name;
    final userPosition = profileProvider.position;

    final activitiesStream = attendanceProvider.fetchActivities();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background2,
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: profileProvider.profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
              child: profileProvider.profileImage.isEmpty
                  ? const Icon(Icons.admin_panel_settings, size: 40, color: AppColors.primary)
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
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: activitiesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Expanded(
                child: Center(
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

            final hasClockIn = activities.any((a) => a['activityType'] == 'Clock In' && a['date'] == nowDate);
            final hasClockOut = activities.any((a) => a['activityType'] == 'Clock Out' && a['date'] == nowDate);

            final lateCount = attendanceProvider.countMonthlyLates(activities, selectedMonth);

            final selectedMonthActivities = activities.where((activity) {
              final parts = activity['date'].split('-');
              if (parts.length == 3) {
                final month = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                return month == selectedMonth.month && year == selectedMonth.year;
              }
              return false;
            }).toList();

            final groupedActivities = attendanceProvider.groupActivitiesByDate(selectedMonthActivities);
            final sortedKeys = groupedActivities.keys.toList()
              ..sort((a, b) {
                final aDate = DateTime.parse('${a.split('-')[2]}-${a.split('-')[1]}-${a.split('-')[0]}');
                final bDate = DateTime.parse('${b.split('-')[2]}-${b.split('-')[1]}-${b.split('-')[0]}');
                return bDate.compareTo(aDate);
              });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today Attendance",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildClockButton(
                      label: "Clock In",
                      isEnabled: !hasClockIn,
                      onPressed: () => _attemptClock('Clock In'),
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 16),
                    _buildClockButton(
                      label: "Clock Out",
                      isEnabled: hasClockIn && !hasClockOut,
                      onPressed: () => _attemptClock('Clock Out'),
                      color: AppColors.cancel,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Your Activity",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final selected = await showDialog<DateTime>(
                          context: context,
                          builder: (context) {
                            int tempMonth = selectedMonth.month;
                            int tempYear = selectedMonth.year;
                            return AlertDialog(
                              title: Text(
                                'Select Month and Year',
                                style: TextStyle(fontSize: 20),
                              ),
                              content: Row(
                                children: [
                                  Expanded(
                                    child: StatefulBuilder(
                                      builder: (context, setState) {
                                        return DropdownButton<int>(
                                          isExpanded: true,
                                          value: tempMonth,
                                          items: List.generate(12, (index) {
                                            return DropdownMenuItem(
                                              value: index + 1,
                                              child: Text(DateFormat.MMMM().format(DateTime(0, index + 1))),
                                            );
                                          }),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                tempMonth = value;
                                              });
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: StatefulBuilder(
                                      builder: (context, setState) {
                                        return DropdownButton<int>(
                                          isExpanded: true,
                                          value: tempYear,
                                          items: List.generate(5, (index) {
                                            final year = DateTime.now().year - index;
                                            return DropdownMenuItem(
                                              value: year,
                                              child: Text(year.toString()),
                                            );
                                          }),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                tempYear = value;
                                              });
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(DateTime(tempYear, tempMonth));
                                  },
                                  child: const Text('Confirm'),
                                ),
                              ],
                            );
                          },
                        );

                        if (selected != null) {
                          setState(() {
                            selectedMonth = DateTime(selected.year, selected.month);
                          });
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(DateFormat('MMMM yyyy').format(selectedMonth)),
                    ),
                  ],
                ),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: AppColors.cancel),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "This Month Late",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "$lateCount times",
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedKeys.length,
                        itemBuilder: (context, index) {
                          final date = sortedKeys[index];
                          final items = groupedActivities[date]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                date,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              const Divider(thickness: 1),
                              ...items.map((activity) {
                                final imageUrl = activity['url'];
                                return ActivityTile(
                                  title: activity['activityType'] ?? 'Unknown',
                                  time: activity['time'],
                                  date: activity['date'],
                                  onTap: () {
                                    if (imageUrl != null && imageUrl.isNotEmpty) {
                                      _showImageDialog(imageUrl);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('No image available for this activity')),
                                      );
                                    }
                                  },
                                );
                              }),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildClockButton({
    required String label,
    required bool isEnabled,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? color : AppColors.inactive,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
