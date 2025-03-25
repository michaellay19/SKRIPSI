import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminRequestTimeOffPage extends StatefulWidget {
  const AdminRequestTimeOffPage({super.key});

  @override
  State<AdminRequestTimeOffPage> createState() => _AdminRequestTimeOffPageState();
}

class _AdminRequestTimeOffPageState extends State<AdminRequestTimeOffPage> {
  TextEditingController searchController = TextEditingController();
  String selectedStatus = "All";
  DateTime? selectedDate = DateTime.now();

  Stream<QuerySnapshot> _fetchLeaveRequests() {
    return FirebaseFirestore.instance.collectionGroup('leave_requests').snapshots();
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
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_today),
              label: Text(
                selectedDate != null ? "${selectedDate!.toLocal()}".split(' ')[0] : "Select Date",
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
    return StreamBuilder<QuerySnapshot>(
      stream: _fetchLeaveRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No leave requests found"));
        }

        var requests = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;

          bool matchesStatus = selectedStatus == "All" || (data["status"] ?? "") == selectedStatus;
          bool matchesDate = selectedDate == null ||
              (_isDateInRange(selectedDate!, DateTime.parse(data["startDate"]), DateTime.parse(data["endDate"])));

          return matchesStatus && matchesDate;
        }).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text("No")),
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Leave Type")),
                DataColumn(label: Text("Start Date")),
                DataColumn(label: Text("End Date")),
                DataColumn(label: Text("Reason")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Action")),
              ],
              rows: requests.asMap().entries.map((entry) {
                int index = entry.key + 1;
                var data = entry.value.data() as Map<String, dynamic>;
                return DataRow(cells: [
                  DataCell(Text(index.toString())),
                  DataCell(FutureBuilder<String>(
                    future: _fetchEmployeeName(entry.value.reference.parent.parent!.id),
                    builder: (context, snapshot) {
                      return Text(snapshot.data ?? "Unknown");
                    },
                  )),
                  DataCell(Text(data["leaveType"] ?? "-")),
                  DataCell(Text(_formatDate(DateTime.parse(data["startDate"] ?? "")))),
                  DataCell(Text(_formatDate(DateTime.parse(data["endDate"] ?? "")))),
                  DataCell(Text(data["reason"] ?? "-")),
                  DataCell(_buildStatusBadge(data["status"] ?? "Pending")),
                  DataCell(Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _updateStatus(entry.value.reference, "Approved")),
                      IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _updateStatus(entry.value.reference, "Rejected")),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(status, style: const TextStyle(color: Colors.white)),
    );
  }

  Future<String> _fetchEmployeeName(String userId) async {
    DocumentSnapshot userProfile =
        await FirebaseFirestore.instance.collection('users').doc(userId).collection('profile').doc(userId).get();

    return userProfile.exists ? userProfile["name"] ?? "Unknown" : "Unknown";
  }

  void _updateStatus(DocumentReference requestRef, String newStatus) async {
    await requestRef.update({"status": newStatus});
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  bool _isDateInRange(DateTime selected, DateTime start, DateTime end) {
    return selected.isAfter(start.subtract(const Duration(days: 1))) &&
        selected.isBefore(end.add(const Duration(days: 1)));
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
