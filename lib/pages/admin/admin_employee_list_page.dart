import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AdminEmployeeListPage extends StatefulWidget {
  const AdminEmployeeListPage({super.key});

  @override
  State<AdminEmployeeListPage> createState() => _AdminEmployeeListPageState();
}

class _AdminEmployeeListPageState extends State<AdminEmployeeListPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> employees = [
    {
      "no": "1",
      "name": "Admin",
      "email": "admin@gmail.com",
      "nik": "12345678",
      "gender": "Male",
      "dob": "1990-01-01",
      "pob": "Jakarta",
      "position": "Manager",
      "religion": "Islam",
      "address": "Jl. Sudirman No.1",
      "employee_status": "Permanent",
      "join_date": "2020-05-10",
      "phone": "081234567890"
    },
  ];

  Uint8List? _selectedImage;

  void _showemployeeDialog({Map<String, String>? employee}) {
    final isEditing = employee != null;
    final controllers = {
      "name": TextEditingController(text: employee?['name'] ?? ''),
      "email": TextEditingController(text: employee?['email'] ?? ''),
      "nik": TextEditingController(text: employee?['nik'] ?? ''),
      "gender": TextEditingController(text: employee?['gender'] ?? ''),
      "dob": TextEditingController(text: employee?['dob'] ?? ''),
      "pob": TextEditingController(text: employee?['pob'] ?? ''),
      "position": TextEditingController(text: employee?['position'] ?? ''),
      "religion": TextEditingController(text: employee?['religion'] ?? ''),
      "address": TextEditingController(text: employee?['address'] ?? ''),
      "employee_status":
          TextEditingController(text: employee?['employee_status'] ?? ''),
      "join_date": TextEditingController(text: employee?['join_date'] ?? ''),
      "phone": TextEditingController(text: employee?['phone'] ?? ''),
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(isEditing ? "Edit employee" : "Add employee"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...controllers.entries
                    .map((entry) => _buildTextField(entry.value, entry.key)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text("Upload Photo"),
                ),
                if (_selectedImage != null)
                  Image.memory(_selectedImage!, height: 100),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isEditing) {
                    employee!.addAll(controllers.map(
                        (key, controller) => MapEntry(key, controller.text)));
                  } else {
                    employees.add({
                      "no": (employees.length + 1).toString(),
                      ...controllers.map(
                          (key, controller) => MapEntry(key, controller.text)),
                    });
                  }
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showemployeeDetails(Map<String, String> employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Employee Details",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem(Icons.badge, "No", employee["no"] ?? "-"),
                _buildDetailItem(Icons.person, "Name", employee["name"] ?? "-"),
                _buildDetailItem(Icons.email, "Email", employee["email"] ?? "-"),
                _buildDetailItem(Icons.credit_card, "NIK", employee["nik"] ?? "-"),
                _buildDetailItem(Icons.male, "Gender", employee["gender"] ?? "-"),
                _buildDetailItem(Icons.cake, "DOB", employee["dob"] ?? "-"),
                _buildDetailItem(
                    Icons.location_on, "Place of Birth", employee["pob"] ?? "-"),
                _buildDetailItem(
                    Icons.work, "Position", employee["position"] ?? "-"),
                _buildDetailItem(
                    Icons.location_city, "Address", employee["address"] ?? "-"),
                _buildDetailItem(Icons.check_circle, "Employee Status",
                    employee["employee_status"] ?? "-"),
                _buildDetailItem(
                    Icons.date_range, "Join Date", employee["join_date"] ?? "-"),
                _buildDetailItem(Icons.phone, "Phone", employee["phone"] ?? "-"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.blue),
          title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(value),
        ),
        Divider(),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: "Search employee",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showemployeeDialog(),
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text("Add employee",
                      style: TextStyle(color: Colors.white)),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("NO")),
                      DataColumn(label: Text("NAME")),
                      DataColumn(label: Text("NIK")),
                      DataColumn(label: Text("EMAIL")),
                      DataColumn(label: Text("ACTIONS")),
                    ],
                    rows: employees
                        .map((employee) => DataRow(cells: [
                              DataCell(Text(employee["no"]!)),
                              DataCell(Text(employee["name"]!)),
                              DataCell(Text(employee["nik"]!)),
                              DataCell(Text(employee["email"]!)),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility,
                                        color: Colors.orange),
                                    onPressed: () => _showemployeeDetails(employee),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _showemployeeDialog(employee: employee),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        setState(() => employees.remove(employee)),
                                  ),
                                ],
                              )),
                            ]))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
