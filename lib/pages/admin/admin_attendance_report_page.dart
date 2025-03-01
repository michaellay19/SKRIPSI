import 'package:flutter/material.dart';

class AdminAttendanceReportPage extends StatefulWidget {
  const AdminAttendanceReportPage({super.key});

  @override
  State<AdminAttendanceReportPage> createState() =>
      _AdminAttendanceReportPageState();
}

class _AdminAttendanceReportPageState extends State<AdminAttendanceReportPage> {
  String selectedMonth = "All";
  String selectedYear = "2025";

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

  final List<String> years =
      List.generate(11, (index) => (2020 + index).toString());

  final List<Map<String, String>> allReports = List.generate(
    12,
    (index) => {
      "no": "${index + 1}",
      "report_name": "Monthly Attendance Report ${[
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
      ][index]}",
    },
  );

  List<Map<String, String>> filteredReports = [];

  @override
  void initState() {
    super.initState();
    _filterReports();
  }

  void _filterReports() {
    setState(() {
      if (selectedMonth == "All") {
        filteredReports = List.from(allReports);
      } else {
        filteredReports = allReports
            .where((report) => report["report_name"]!.contains(selectedMonth))
            .toList();
      }
    });
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
              setState(() => selectedYear = value!);
            }),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _filterReports,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text("Filter"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String selectedValue,
      ValueChanged<String?> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        constraints:
            BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columnSpacing: 30,
            headingRowColor: MaterialStateColor.resolveWith(
                (states) => Colors.teal.shade100),
            columns: const [
              DataColumn(
                  label: Text("No",
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text("Report Name",
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text("Action",
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: filteredReports
                .map((report) => DataRow(cells: [
                      DataCell(Text(report["no"]!)),
                      DataCell(Text(report["report_name"]!)),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.teal),
                          onPressed: () {},
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
