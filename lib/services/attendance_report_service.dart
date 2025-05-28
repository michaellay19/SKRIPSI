import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row;
import '../utility/save_file_stub.dart' if (dart.library.html) '../utility/save_file_web.dart';

class AttendanceService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchAttendanceData(int year, int month, List<int> validDates) async {
    List<Map<String, dynamic>> attendanceData = [];

    QuerySnapshot usersSnapshot = await firestore.collection('users').get();
    for (var userDoc in usersSnapshot.docs) {
      String userId = userDoc.id;

      QuerySnapshot profileSnapshot = await firestore.collection('users').doc(userId).collection('profile').get();

      String name = "", position = "";
      if (profileSnapshot.docs.isNotEmpty) {
        var profileDoc = profileSnapshot.docs.first;
        name = profileDoc['name'];
        position = profileDoc['position'];
      }

      Map<int, Map<String, dynamic>> attendance = {};
      QuerySnapshot attendanceSnapshot = await firestore.collection('users').doc(userId).collection('attendance').get();
      for (var doc in attendanceSnapshot.docs) {
        DateTime uploaded = (doc['uploadedAt'] as Timestamp).toDate();
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (uploaded.year == year && uploaded.month == month) {
          attendance[uploaded.day] = {
            "status": "P",
            "late": data.containsKey("late") ? data["late"] : false,
          };
        }
      }

      QuerySnapshot leaveSnapshot = await firestore.collection('users').doc(userId).collection('leave_requests').get();
      for (var leaveDoc in leaveSnapshot.docs) {
        DateTime start = (leaveDoc['startDate'] as Timestamp).toDate();
        DateTime end = (leaveDoc['endDate'] as Timestamp).toDate();
        String leaveType = leaveDoc['leaveType'];
        String status = leaveDoc['status'];

        if (status == "Approved") {
          DateTime current = start;
          while (!current.isAfter(end)) {
            if (current.year == year && current.month == month && validDates.contains(current.day)) {
              attendance[current.day] = {
                "status": leaveType == "Attendance Request" ? "P" : "T",
                "late": false,
              };
            }
            current = current.add(Duration(days: 1));
          }
        }
      }

      attendanceData.add({"name": name, "position": position, "attendance": attendance});
    }

    return attendanceData;
  }

  Future<void> exportToExcel(String title, int year, int month, List<int> validDates, List<String> dayNames,
      List<Map<String, dynamic>> data) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    final Style headerStyle = workbook.styles.add('HeaderStyle')
      ..borders.all.lineStyle = LineStyle.thin
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..bold = true
      ..backColor = '#70AD47';

    final Style subHeaderStyle = workbook.styles.add('SubHeaderStyle')
      ..borders.all.lineStyle = LineStyle.thin
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..bold = true
      ..backColor = '#C6E0B4';

    final Style lateStyle = workbook.styles.add('LateStyle')
      ..borders.all.lineStyle = LineStyle.thin
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..bold = true
      ..backColor = '#FF0000';

    sheet.getRangeByName('A1').columnWidth = 3.67;
    sheet.getRangeByName('B1:C1').columnWidth = 19.78;

    sheet.getRangeByName('A1:C1').merge();
    sheet.getRangeByName('A2:A3').merge();
    sheet.getRangeByName('B2:B3').merge();
    sheet.getRangeByName('C2:C3').merge();

    sheet.getRangeByIndex(2, 1).setText("No.");
    sheet.getRangeByIndex(2, 2).setText("Name");
    sheet.getRangeByIndex(2, 3).setText("Position");

    int colIndex = 4;
    for (int i = 0; i < validDates.length; i++) {
      sheet.getRangeByIndex(2, colIndex).setText(validDates[i].toString());
      sheet.getRangeByIndex(3, colIndex).setText(dayNames[i]);
      colIndex++;
    }

    sheet.getRangeByIndex(2, colIndex).setText("Total");
    sheet.getRangeByIndex(3, colIndex++).setText("Present");
    sheet.getRangeByIndex(3, colIndex++).setText("Absent");
    sheet.getRangeByIndex(3, colIndex++).setText("Time Off");
    sheet.getRangeByIndex(3, colIndex++).setText("Late");
    // sheet.getRangeByIndex(3, colIndex).cellStyle = subHeaderStyle;

    // int lateColIndex = colIndex;
    // colIndex++;

    String getColumnLetter(int colIndex) {
      String columnName = "";
      while (colIndex > 0) {
        colIndex--;
        columnName = String.fromCharCode(65 + (colIndex % 26)) + columnName;
        colIndex = (colIndex / 26).floor();
      }
      return columnName;
    }

    String monthName = DateFormat('MMMM').format(DateTime(year, month));
    String lastDateColumn = getColumnLetter(3 + validDates.length);
    String totalStartColumn = getColumnLetter(3 + validDates.length + 1);
    String totalEndColumn = getColumnLetter(3 + validDates.length + 4);

    sheet.getRangeByName('A1').setText('$monthName $year');
    sheet.getRangeByName('D1:${lastDateColumn}1').merge();
    sheet.getRangeByName('D1:${lastDateColumn}1').cellStyle = headerStyle;

    sheet.getRangeByName('${totalStartColumn}1:${totalEndColumn}2').merge();
    sheet.getRangeByName('${totalStartColumn}1').setText("Total");
    sheet.getRangeByName('A1:${totalEndColumn}1').cellStyle = headerStyle;
    sheet.getRangeByName('A2:${totalEndColumn}3').cellStyle = subHeaderStyle;

    data.sort((a, b) => a["name"].compareTo(b["name"]));

    int rowIndex = 4;
    for (int i = 0; i < data.length; i++) {
      int col = 1;
      final attendance = data[i]["attendance"] as Map<int, dynamic>;
      int present = 0, absent = 0, timeOff = 0, late = 0;

      sheet.getRangeByIndex(rowIndex, col++).setText((i + 1).toString());
      sheet.getRangeByIndex(rowIndex, col++).setText(data[i]["name"]);
      sheet.getRangeByIndex(rowIndex, col++).setText(data[i]["position"]);

      for (int day in validDates) {
        final cell = sheet.getRangeByIndex(rowIndex, col);
        var statusData = attendance[day];
        if (statusData == null) {
          DateTime date = DateTime(year, month, day);
          bool isSunday = date.weekday == DateTime.sunday;

          cell.setText((isSunday) ? "-" : "A");

          if (!(isSunday)) {
            absent++;
          }
        } else {
          String status = statusData["status"];
          bool isLate = statusData["late"] ?? false;

          if (status == "P" && isLate) {
            late++;
            cell.setText("P");
            cell.cellStyle = lateStyle;
          } else {
            cell.setText(status);
          }

          if (status == "P" && !isLate) present++;
          if (status == "A") absent++;
          if (status == "T") timeOff++;
        }
        col++;
      }

      sheet.getRangeByIndex(rowIndex, col++).setText(present.toString());
      sheet.getRangeByIndex(rowIndex, col++).setText(absent.toString());
      sheet.getRangeByIndex(rowIndex, col++).setText(timeOff.toString());
      sheet.getRangeByIndex(rowIndex, col++).setText(late.toString());

      rowIndex++;
    }

    for (int row = 1; row < rowIndex; row++) {
      for (int col = 1; col < colIndex; col++) {
        final Range cell = sheet.getRangeByIndex(row, col);
        cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.center;
      }
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    String fileName = 'Attendance_Report_${monthName}_$year.xlsx';
    await saveAndLaunchFile(bytes, fileName);
  }
}
