import 'package:flutter/material.dart';

class AdminRequestTimeOffPage extends StatefulWidget {
  @override
  _AdminRequestTimeOffPageState createState() =>
      _AdminRequestTimeOffPageState();
}

class _AdminRequestTimeOffPageState extends State<AdminRequestTimeOffPage> {
  TextEditingController searchController = TextEditingController();
  String selectedStatus = "All";
  DateTime? selectedDate;

  List<Map<String, String>> requests = [
    {
      "no": "1",
      "name": "Hendry",
      "date": "02/03/2025",
      "reason": "Annual leave",
      "file": "No File",
      "status": "Approved"
    },
    {
      "no": "2",
      "name": "Alvyn",
      "date": "03/03/2025",
      "reason": "Medical Leave",
      "file": "File",
      "status": "Pending"
    },
    {
      "no": "3",
      "name": "Michael",
      "date": "04/03/2025",
      "reason": "Casual leave",
      "file": "No File",
      "status": "Rejected"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilterSection(),
          SizedBox(height: 10),
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
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search employee name...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            SizedBox(width: 10),
            DropdownButton<String>(
              value: selectedStatus,
              items: ["All", "Approved", "Pending", "Rejected"]
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
              },
            ),
            SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _selectDate(context),
              icon: Icon(Icons.calendar_today),
              label: Text(
                selectedDate != null
                    ? "${selectedDate!.toLocal()}".split(' ')[0]
                    : "Select Date",
              ),
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
    var filteredRequests = requests.where((req) {
      bool matchesName = searchController.text.isEmpty ||
          req["name"]!
              .toLowerCase()
              .contains(searchController.text.toLowerCase());
      bool matchesStatus =
          selectedStatus == "All" || req["status"] == selectedStatus;
      bool matchesDate =
          selectedDate == null || req["date"] == _formatDate(selectedDate!);

      return matchesName && matchesStatus && matchesDate;
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
            DataColumn(label: Text("Date")),
            DataColumn(label: Text("Reason")),
            DataColumn(label: Text("File")),
            DataColumn(label: Text("Status")),
            DataColumn(label: Text("Action")),
          ],
          rows: filteredRequests
              .map((req) => DataRow(cells: [
                    DataCell(Text(req["no"]!)),
                    DataCell(Text(req["name"]!)),
                    DataCell(Text(req["date"]!)),
                    DataCell(Text(req["reason"]!)),
                    DataCell(
                      req["file"] == "File"
                          ? TextButton(
                              onPressed: () {},
                              child: Text("File",
                                  style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline)),
                            )
                          : Text(req["file"]!),
                    ),
                    DataCell(_buildStatusBadge(req["status"]!)),
                    DataCell(Row(
                      children: [
                        IconButton(
                            icon: Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () {}),
                        IconButton(
                            icon: Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {}),
                      ],
                    )),
                  ]))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    switch (status) {
      case "Approved":
        bgColor = Colors.green;
        break;
      case "Pending":
        bgColor = Colors.orange;
        break;
      case "Rejected":
        bgColor = Colors.red;
        break;
      default:
        bgColor = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(status, style: TextStyle(color: Colors.white)),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
