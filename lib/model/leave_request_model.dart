class LeaveRequest {
  final String id;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;

  LeaveRequest({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
  });
}

extension DateFormatting on DateTime {
  String toFormattedString() {
    return '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year';
  }
}