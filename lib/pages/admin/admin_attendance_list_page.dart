import 'package:flutter/material.dart';

class AdminAttendanceListPage extends StatefulWidget {
  const AdminAttendanceListPage({super.key});

  @override
  State<AdminAttendanceListPage> createState() =>
      _AdminAttendanceListPageState();
}

class _AdminAttendanceListPageState extends State<AdminAttendanceListPage> {
  DateTime selectedDate = DateTime.now();
  TextEditingController searchController = TextEditingController();

  List<Map<String, String>> attendanceList = [
    {
      "no": "1",
      "name": "Hendry",
      "checkin": "08:00",
      "checkout": "17:00",
      "status": "Present",
      "checkinPhoto": "assets/checkin1.jpg",
      "checkoutPhoto": "assets/checkout1.jpg",
    },
    {
      "no": "2",
      "name": "Alvyn",
      "checkin": "08:05",
      "checkout": "17:10",
      "status": "Present",
      "checkinPhoto": "assets/checkin2.jpg",
      "checkoutPhoto": "assets/checkout2.jpg",
    },
    {
      "no": "3",
      "name": "Michael",
      "checkin": "-",
      "checkout": "-",
      "status": "Absent",
      "checkinPhoto": "",
      "checkoutPhoto": "",
    },
  ];

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilterSection(),
          const SizedBox(height: 10),
          Expanded(child: _buildDataTable()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search employee name...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_today),
              label: Text("${selectedDate.toLocal()}".split(' ')[0]),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    var filteredList = attendanceList.where((entry) {
      return searchController.text.isEmpty ||
          entry["name"]!
              .toLowerCase()
              .contains(searchController.text.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: DataTable(
          columnSpacing: 20,
          columns: [
            DataColumn(label: Text("No")),
            DataColumn(label: Text("Name")),
            DataColumn(label: Text("Check-in")),
            DataColumn(label: Text("Check-out")),
            DataColumn(label: Text("Status")),
            DataColumn(label: Text("Action")),
          ],
          rows: filteredList
              .map((entry) => DataRow(cells: [
                    DataCell(Text(entry["no"]!)),
                    DataCell(Text(entry["name"]!)),
                    DataCell(Text(entry["checkin"]!)),
                    DataCell(Text(entry["checkout"]!)),
                    DataCell(_buildStatusBadge(entry["status"]!)),
                    DataCell(_buildViewPhotoButton(entry)),
                  ]))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor = status == "Present" ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(status, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildViewPhotoButton(Map<String, String> entry) {
    return IconButton(
      icon: const Icon(Icons.photo),
      color: Colors.blue,
      onPressed: () => _showPhotoDialog(entry),
    );
  }

  void _showPhotoDialog(Map<String, String> entry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Attendance Photos - ${entry["name"]}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPhotoSection("Check-in", entry["checkinPhoto"]!),
              const SizedBox(height: 10),
              _buildPhotoSection("Check-out", entry["checkoutPhoto"]!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoSection(String label, String photoPath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        photoPath.isNotEmpty
            ? Image.asset(photoPath, height: 100, fit: BoxFit.cover)
            : const Text("No photo available",
                style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
