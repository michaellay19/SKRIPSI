import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skripsi/constants/app_colors.dart';

class AdminAttendanceListPage extends StatefulWidget {
  const AdminAttendanceListPage({super.key});

  @override
  State<AdminAttendanceListPage> createState() => _AdminAttendanceListPageState();
}

class _AdminAttendanceListPageState extends State<AdminAttendanceListPage> {
  DateTime selectedDate = DateTime.now();
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> attendanceList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() => isLoading = true);

    try {
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection("users").get();

      List<Map<String, dynamic>> tempAttendanceList = [];

      String formattedSelectedDate =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      for (var userDoc in usersSnapshot.docs) {
        String uid = userDoc.id;

        DocumentSnapshot profileSnapshot =
            await FirebaseFirestore.instance.collection("users").doc(uid).collection("profile").doc(uid).get();

        if (!profileSnapshot.exists) continue;

        String no = profileSnapshot["no"];
        String userName = profileSnapshot["name"];

        QuerySnapshot attendanceSnapshot =
            await FirebaseFirestore.instance.collection("users").doc(uid).collection("attendance").get();

        Map<String, dynamic> attendanceData = {
          "no": no,
          "uid": uid,
          "name": userName,
          "checkin": "-",
          "checkout": "-",
          "checkinPhoto": "",
          "checkoutPhoto": "",
          "status": "Absent",
        };

        for (var attendanceDoc in attendanceSnapshot.docs) {
          var data = attendanceDoc.data() as Map<String, dynamic>;
          String activityType = data["activityType"];
          String uploadedAt = data["uploadedAt"];
          String url = data["url"] ?? "";
          String recordDate = uploadedAt.split(" ")[0];

          if (recordDate == formattedSelectedDate) {
            if (activityType == "Clock In") {
              attendanceData["checkin"] = uploadedAt;
              attendanceData["checkinPhoto"] = url;
              attendanceData["status"] = "Present";
            } else if (activityType == "Clock Out") {
              attendanceData["checkout"] = uploadedAt;
              attendanceData["checkoutPhoto"] = url;
            }
          }
        }
        if (attendanceData["checkin"] != "-" || attendanceData["checkout"] != "-") {
          tempAttendanceList.add(attendanceData);
        }
      }

      setState(() {
        attendanceList = tempAttendanceList;
        isLoading = false;
      });

      print("Final attendance list: $attendanceList");
    } catch (e) {
      debugPrint("Error fetching attendance data: $e");
      setState(() => isLoading = false);
    }
  }

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
      _fetchAttendanceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
          entry["name"]!.toLowerCase().contains(searchController.text.toLowerCase());
    }).toList();

    print("Filtered Attendance List: ${filteredList.length}");

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: DataTable(
          columnSpacing: 20,
          columns: const [
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

  Widget _buildViewPhotoButton(Map<String, dynamic> entry) {
    return IconButton(
      icon: const Icon(Icons.photo),
      color: Colors.blue,
      onPressed: () => _showPhotoDialog(entry),
    );
  }

  void _showPhotoDialog(Map<String, dynamic> entry) {
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

  Widget _buildPhotoSection(String label, String photoUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        photoUrl.isNotEmpty
            ? Image.network(photoUrl, height: 100, fit: BoxFit.cover)
            : const Text("No photo available", style: TextStyle(color: AppColors.text2)),
      ],
    );
  }
}
