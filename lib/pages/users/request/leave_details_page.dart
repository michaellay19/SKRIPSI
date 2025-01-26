import 'package:flutter/material.dart';
import 'package:skripsi/model/leave_request_model.dart';

class LeaveDetailsPage extends StatelessWidget {
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;

  const LeaveDetailsPage({
    super.key,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Details', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Leave Type', leaveType),
            _buildDetailRow('Start Date', startDate.toFormattedString()),
            _buildDetailRow('End Date', endDate.toFormattedString()),
            _buildDetailRow('Reason', reason),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }
}