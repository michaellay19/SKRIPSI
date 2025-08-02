import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skripsi/models/leave_request_model.dart';
import 'package:skripsi/utility/holiday_utils.dart';

class LeaveService {
  static Future<Map<String, dynamic>> computeLeaveSummary(List<LeaveRequest> requests, DateTime joinDate) async {
    final holidayDoc = await FirebaseFirestore.instance.collection('admin').doc('holiday').get();
    final holidaysField = holidayDoc.data()?['holidays'] as List<dynamic>? ?? [];
    final holidays = holidaysField.map((dateStr) => DateTime.parse(dateStr as String)).toSet();
    HolidayUtils.setHolidays(holidays);

    final shiftDoc = await FirebaseFirestore.instance.collection('admin').doc('shift').get();
    final totalQuota = shiftDoc.data()?['leaveQuota'] as int? ?? 21;

    int total = 0;
    int approved = 0;
    int pending = 0;
    int rejected = 0;
    int annualLeaveUsedDays = 0;

    int annualRequests = 0;
    int sickRequests = 0;
    int parentalRequests = 0;
    int attendanceRequests = 0;

    for (var request in requests) {
      final days = HolidayUtils.getWorkingDaysBetween(request.startDate, request.endDate);
      total++;

      switch (request.leaveType.toLowerCase()) {
        case 'annual leave':
          annualRequests++;
          if (request.status.toLowerCase() == 'approved') {
            annualLeaveUsedDays += days;
          }
          break;
        case 'sick leave':
          sickRequests++;
          break;
        case 'parental leave':
          parentalRequests++;
          break;
        case 'attendance request':
          attendanceRequests++;
          break;
      }

      final status = request.status.toLowerCase();
      switch (status) {
        case 'approved':
          approved++;
          break;
        case 'pending':
          pending++;
          break;
        case 'rejected':
          rejected++;
          break;
      }
    }

    final quotaLeft = (totalQuota - annualLeaveUsedDays).clamp(0, totalQuota);

    return {
      'total': total,
      'annualRequests': annualRequests,
      'sickRequests': sickRequests,
      'parentalRequests': parentalRequests,
      'attendanceRequests': attendanceRequests,
      'approved': approved,
      'pending': pending,
      'rejected': rejected,
      'quotaLeft': quotaLeft,
    };
  }
}
