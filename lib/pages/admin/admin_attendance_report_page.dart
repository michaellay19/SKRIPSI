import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skripsi/model/save_file_web.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row;

class AdminAttendanceReportPage extends StatefulWidget {
  const AdminAttendanceReportPage({super.key});

  @override
  State<AdminAttendanceReportPage> createState() => _AdminAttendanceReportPageState();
}

class _AdminAttendanceReportPageState extends State<AdminAttendanceReportPage> {
  String selectedMonth = "All";
  String selectedYear = DateFormat('yyyy').format(DateTime.now());

  final List<String> months = [
    "All",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  final List<String> years = List.generate(20, (index) => (2020 + index).toString());
  final List<Map<String, String>> allReports = [];
  List<Map<String, String>> filteredReports = [];

  void _generateReports() {
    int reportNumber = 1;
    for (String year in years) {
      for (String month in months.skip(1)) {
        allReports.add({
          "no": reportNumber.toString(),
          "report_name": "Monthly Attendance Report $month $year",
        });
        reportNumber++;
      }
    }
  }

  void _filterReports() {
    setState(() {
      List<Map<String, String>> tempFiltered = allReports.where((report) {
        if (selectedMonth == "All" && selectedYear == "All") return true;

        List<String> words = report["report_name"]!.split(" ");
        if (words.length < 5) return false;

        String reportMonth = words[3];
        String reportYear = words[4];

        bool monthMatches = (selectedMonth == "All" || reportMonth == selectedMonth);
        bool yearMatches = (selectedYear == "All" || reportYear == selectedYear);

        return monthMatches && yearMatches;
      }).toList();

      for (int i = 0; i < tempFiltered.length; i++) {
        tempFiltered[i]["no"] = (i + 1).toString();
      }

      filteredReports = tempFiltered;
    });
  }

  Future<void> exportToExcel(String title) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
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

    sheet.getRangeByName('A1').columnWidth = 3.67;
    sheet.getRangeByName('B1:C1').columnWidth = 19.78;
    sheet.getRangeByName('A1:C1').merge();
    sheet.getRangeByName('A2:A3').merge();
    sheet.getRangeByName('B2:B3').merge();
    sheet.getRangeByName('C2:C3').merge();

    int colIndex = 4;
    sheet.getRangeByIndex(2, 1).setText("No.");
    sheet.getRangeByIndex(2, 2).setText("Name");
    sheet.getRangeByIndex(2, 3).setText("Position");

    List<String> words = title.split(" ");

    if (words.length >= 5) {
      selectedMonth = words[3];
      selectedYear = words[4];
    }

    int year = int.parse(selectedYear);
    int month = months.indexOf(selectedMonth);

    List<int> validDates = [];
    List<String> dayNames = [];
    int count = 0;

    for (int day = 1; day <= DateTime(year, month + 1, 0).day; day++) {
      DateTime date = DateTime(year, month, day);
      if (date.weekday != DateTime.sunday) {
        validDates.add(day);
        dayNames.add(DateFormat('EEE').format(date));
        count++;

        sheet.getRangeByIndex(2, colIndex).setText(day.toString());
        sheet.getRangeByIndex(3, colIndex++).setText(dayNames.last);
      }
    }

    String monthName = DateFormat('MMMM').format(DateTime(year, month));
    sheet.getRangeByName('A1').setText('$monthName $year');
    sheet.getRangeByName('D1').setText('Day & Date');

    String getColumnLetter(int colIndex) {
      String columnName = "";
      while (colIndex > 0) {
        colIndex--;
        columnName = String.fromCharCode(65 + (colIndex % 26)) + columnName;
        colIndex = (colIndex / 26).floor();
      }
      return columnName;
    }

    String lastDateColumn = getColumnLetter(3 + count);
    String totalStartColumn = getColumnLetter(3 + count + 1);
    String totalEndColumn = getColumnLetter(3 + count + 3);

    sheet.getRangeByName('D1:${lastDateColumn}1').merge();
    sheet.getRangeByName('D1:${lastDateColumn}1').cellStyle = headerStyle;

    sheet.getRangeByName('${totalStartColumn}1:${totalEndColumn}2').merge();
    sheet.getRangeByName('${totalStartColumn}1').setText("Total");
    sheet.getRangeByName('D1:${lastDateColumn}1').columnWidth = 4.44;
    sheet.getRangeByName('${totalStartColumn}1:${totalEndColumn}1').columnWidth = 9.22;
    sheet.getRangeByName('${totalStartColumn}1:${totalEndColumn}1').cellStyle = headerStyle;

    sheet.getRangeByName('A2:C3').cellStyle = subHeaderStyle;
    sheet.getRangeByName('D2:${lastDateColumn}3').cellStyle = subHeaderStyle;
    sheet.getRangeByName('${totalStartColumn}2:${totalEndColumn}3').cellStyle = subHeaderStyle;

    sheet.getRangeByIndex(2, colIndex).setText("Total");
    sheet.getRangeByIndex(3, colIndex++).setText("Present");
    sheet.getRangeByIndex(3, colIndex++).setText("Absent");
    sheet.getRangeByIndex(3, colIndex++).setText("Time Off");
    sheet.getRangeByName('A1:${totalEndColumn}1').cellStyle = headerStyle;
    sheet.getRangeByName('A2:${totalEndColumn}3').cellStyle = subHeaderStyle;

    List<Map<String, dynamic>> attendanceData = [];

    QuerySnapshot usersSnapshot = await firestore.collection('users').get();
    for (var userDoc in usersSnapshot.docs) {
      String userId = userDoc.id;

      QuerySnapshot profileSnapshot = await firestore.collection('users').doc(userId).collection('profile').get();

      String name = "";
      String position = "";

      if (profileSnapshot.docs.isNotEmpty) {
        var profileDoc = profileSnapshot.docs.first;
        name = profileDoc['name'];
        position = profileDoc['position'];
      }

      Map<int, String> attendance = {};
      QuerySnapshot attendanceSnapshot = await firestore.collection('users').doc(userId).collection('attendance').get();

      for (var attendanceDoc in attendanceSnapshot.docs) {
        DateTime attendanceDate = DateTime.parse(attendanceDoc['uploadedAt']);
        if (attendanceDate.year == year && attendanceDate.month == month) {
          int day = attendanceDate.day;
          attendance[day] = "P";
        }
      }

      QuerySnapshot leaveSnapshot = await firestore.collection('users').doc(userId).collection('leave_requests').get();

      for (var leaveDoc in leaveSnapshot.docs) {
        DateTime startDate = DateTime.parse(leaveDoc['startDate']);
        DateTime endDate = DateTime.parse(leaveDoc['endDate']);
        String leaveType = leaveDoc['leaveType'];
        String status = leaveDoc['status'];

        if (status == "Approved") {
          for (int day = startDate.day; day <= endDate.day; day++) {
            if (validDates.contains(day) && leaveType != "Missed Punch Request") {
              attendance[day] = "T";
            }
          }
        }

        if (leaveType == "Missed Punch Request" && status == "Approved") {
          for (int day = startDate.day; day <= endDate.day; day++) {
            if (validDates.contains(day)) {
              attendance[day] = "P";
            }
          }
        }
      }

      attendanceData.add({
        "name": name,
        "position": position,
        "attendance": attendance,
      });
    }

    attendanceData.sort((a, b) => a["name"].compareTo(b["name"]));

    int rowIndex = 4;
    for (int i = 0; i < attendanceData.length; i++) {
      int col = 1;
      sheet.getRangeByIndex(rowIndex, col++).setText((i + 1).toString());
      sheet.getRangeByIndex(rowIndex, col++).setText(attendanceData[i]["name"]);
      sheet.getRangeByIndex(rowIndex, col++).setText(attendanceData[i]["position"]);

      int present = 0, absent = 0, timeOff = 0;

      for (int day in validDates) {
        String status = attendanceData[i]["attendance"][day] ?? "A";
        sheet.getRangeByIndex(rowIndex, col++).setText(status);

        if (status == "P") present++;
        if (status == "A") absent++;
        if (status == "T") timeOff++;
      }

      sheet.getRangeByIndex(rowIndex, col++).setText(present.toString());
      sheet.getRangeByIndex(rowIndex, col++).setText(absent.toString());
      sheet.getRangeByIndex(rowIndex, col++).setText(timeOff.toString());

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

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    String fileName = 'Attendance_Report_${monthName}_$selectedYear.xlsx';
    await saveAndLaunchFile(bytes, fileName);
  }

  @override
  void initState() {
    super.initState();
    _generateReports();
    _filterReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterSection(),
              const SizedBox(height: 20),
              _buildReportTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildDropdown(months, selectedMonth, (value) {
              setState(() {
                selectedMonth = value!;
                _filterReports();
              });
            }),
            const SizedBox(width: 12),
            _buildDropdown(years, selectedYear, (value) {
              setState(() {
                selectedYear = value!;
                _filterReports();
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String selectedValue, ValueChanged<String?> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items.map((String item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
      ),
    );
  }

  Widget _buildReportTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columnSpacing: 30,
            headingRowColor: WidgetStateColor.resolveWith((states) => Colors.teal.shade100),
            columns: const [
              DataColumn(label: Text("No", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Report Name", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: filteredReports
                .map((report) => DataRow(cells: [
                      DataCell(Text(report["no"]!)),
                      DataCell(Text(report["report_name"]!)),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.teal),
                          onPressed: () {
                            exportToExcel(report["report_name"]!);
                          },
                        ),
                      ),
                    ]))
                .toList(),
          ),
        ),
      ),
    );
  }
}
