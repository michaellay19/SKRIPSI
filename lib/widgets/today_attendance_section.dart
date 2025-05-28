import 'package:flutter/material.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/widgets/attendance_card.dart';

class TodayAttendanceSection extends StatelessWidget {
  final String clockInTime;
  final String clockOutTime;
  final bool hasClockIn;
  final bool hasClockOut;
  final Function(String) onClockPressed;
  final bool isLateClockIn;

  const TodayAttendanceSection({
    super.key,
    required this.clockInTime,
    required this.clockOutTime,
    required this.hasClockIn,
    required this.hasClockOut,
    required this.onClockPressed,
    required this.isLateClockIn,
  });

  TextStyle _getTimeStyle({
    required String time,
    required bool isCheckIn,
    required bool isLate,
  }) {
    if (time == "-") return const TextStyle(color: Colors.black);

    if (isCheckIn) {
      return isLate
          ? const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
          : const TextStyle(color: Colors.black);
    }

    final hour = int.tryParse(time.split(":").first) ?? 0;
    if (hour < 17) {
      return const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
    }

    return const TextStyle(color: Colors.black);
  }

  String _getSubtitle({
    required String time,
    required bool isCheckIn,
    required bool isLate,
  }) {
    if (time == "-") return isCheckIn ? "Not Clocked In" : "Not Clocked Out";

    if (isCheckIn) return isLate ? "Clock In Late" : "On Time";

    final hour = int.tryParse(time.split(":").first) ?? 0;
    return hour < 17 ? "Early Clock Out" : "Go Home";
  }

  @override
  Widget build(BuildContext context) {
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
              subtitle: _getSubtitle(
                time: clockInTime,
                isCheckIn: true,
                isLate: isLateClockIn,
              ),
              timeStyle: _getTimeStyle(
                time: clockInTime,
                isCheckIn: true,
                isLate: isLateClockIn,
              ),
              subtitleStyle: _getTimeStyle(
                time: clockInTime,
                isCheckIn: true,
                isLate: isLateClockIn,
              ),
            ),
            AttendanceCard(
              title: "Clock Out",
              time: clockOutTime,
              subtitle: _getSubtitle(
                time: clockOutTime,
                isCheckIn: false,
                isLate: false,
              ),
              timeStyle: _getTimeStyle(
                time: clockOutTime,
                isCheckIn: false,
                isLate: false,
              ),
              subtitleStyle: _getTimeStyle(
                time: clockOutTime,
                isCheckIn: false,
                isLate: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildClockButton(
              label: "Clock In",
              isEnabled: !hasClockIn,
              color: AppColors.primary,
              onPressed: () => onClockPressed('Clock In'),
            ),
            const SizedBox(width: 16),
            _buildClockButton(
              label: "Clock Out",
              isEnabled: hasClockIn && !hasClockOut,
              color: AppColors.cancel,
              onPressed: () => onClockPressed('Clock Out'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClockButton({
    required String label,
    required bool isEnabled,
    required Color color,
    required VoidCallback onPressed,
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
