import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LeaveSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;

  const LeaveSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kIsWeb) Text('Leave Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (kIsWeb) SizedBox(height: 10),
            Text('Total Requests: ${summary['total']}'),
            Text('Annual Requests: ${summary['annualRequests']}'),
            Text('Sick Requests: ${summary['sickRequests']}'),
            Text('Parental Requests: ${summary['parentalRequests']}'),
            Text('Attendance Requests: ${summary['attendanceRequests']}'),
            const SizedBox(height: 10),
            Text('Approved: ${summary['approved']}'),
            Text('Pending: ${summary['pending']}'),
            Text('Rejected: ${summary['rejected']}'),
            const SizedBox(height: 10),
            Text('Annual Leave Quota Left: ${summary['quotaLeft']} days'),
          ],
        ),
      ),
    );
  }
}
