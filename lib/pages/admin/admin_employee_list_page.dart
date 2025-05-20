import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/model/employee_model.dart';

class AdminEmployeeListPage extends StatefulWidget {
  const AdminEmployeeListPage({super.key});

  @override
  State<AdminEmployeeListPage> createState() => _AdminEmployeeListPageState();
}

class _AdminEmployeeListPageState extends State<AdminEmployeeListPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Employee> employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collectionGroup("profile").get();

    List<Employee> loadedEmployees = snapshot.docs.map((doc) {
      return Employee(
        uid: doc.id,
        no: doc["no"],
        name: doc["name"],
        nik: doc["nik"],
        email: doc["email"],
        gender: doc["gender"],
        dob: doc["dob"],
        pob: doc["pob"],
        position: doc["position"],
        religion: doc["religion"],
        address: doc["address"],
        joinDate: doc["joinDate"],
        phone: doc["phone"],
      );
    }).toList();

    loadedEmployees.sort((a, b) => a.no.compareTo(b.no));

    setState(() {
      employees.clear();
      employees.addAll(loadedEmployees);
    });
  }

  void _showEmployeeFaceImage(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final faceImageUrl = doc.data()?['faceImage'];

      if (faceImageUrl == null || faceImageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Face image not available.")),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Face Image"),
          content: Image.network(faceImageUrl),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load face image: $e")),
      );
    }
  }

  void _showEmployeeDialog({Employee? employee}) {
    final formKey = GlobalKey<FormState>();
    final isEditing = employee != null;
    final controllers = {
      for (var field in [
        "name",
        "nik",
        "email",
        "gender",
        "dob",
        "pob",
        "position",
        "religion",
        "address",
        "joinDate",
        "phone"
      ])
        field: TextEditingController(text: employee != null ? employee.toMap()[field] : ""),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? "Edit Employee" : "Add Employee"),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 600,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  _buildField(controllers["name"]!, "Name", isRequired: true),
                  _buildField(controllers["nik"]!, "NIK", isNik: true, isRequired: true),
                  _buildField(controllers["email"]!, "Email", isRequired: true, isEditable: isEditing ? false : true),
                  _buildGenderField(controllers["gender"]!, "Gender"),
                  _buildField(controllers["dob"]!, "Date of Birth", isDate: true),
                  _buildField(controllers["pob"]!, "Place of Birth"),
                  _buildField(controllers["position"]!, "Position"),
                  _buildField(controllers["religion"]!, "Religion"),
                  _buildField(controllers["address"]!, "Address"),
                  _buildField(controllers["joinDate"]!, "Join Date", isDate: true),
                  _buildField(controllers["phone"]!, "Phone"),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _saveEmployee(controllers, isEditing, employee);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEmployee(Map<String, TextEditingController> controllers, bool isEditing, Employee? employee) async {
    const String functionUrl = 'https://api-ryy35i7zhq-uc.a.run.app/create-user';

    final employeeData = {
      "uid": isEditing ? employee!.uid : null,
      "isEditing": isEditing,
      "no": isEditing ? employee!.no : (employees.length + 1).toString().padLeft(4, '0'),
      "name": controllers["name"]!.text,
      "nik": controllers["nik"]!.text,
      "email": controllers["email"]!.text,
      "gender": controllers["gender"]!.text,
      "dob": controllers["dob"]!.text,
      "pob": controllers["pob"]!.text,
      "position": controllers["position"]!.text,
      "religion": controllers["religion"]!.text,
      "address": controllers["address"]!.text,
      "joinDate": controllers["joinDate"]!.text,
      "phone": controllers["phone"]!.text,
    };

    try {
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(employeeData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final uid = data['uid'] as String;

        final newEmployee = Employee(
          uid: uid,
          no: employeeData["no"]! as String,
          name: employeeData["name"]! as String,
          nik: employeeData["nik"]! as String,
          email: employeeData["email"]! as String,
          gender: employeeData["gender"]! as String,
          dob: employeeData["dob"]! as String,
          pob: employeeData["pob"]! as String,
          position: employeeData["position"]! as String,
          religion: employeeData["religion"]! as String,
          address: employeeData["address"]! as String,
          joinDate: employeeData["joinDate"]! as String,
          phone: employeeData["phone"]! as String,
        );

        setState(() {
          if (isEditing) {
            int index = employees.indexWhere((e) => e.uid == uid);
            if (index != -1) employees[index] = newEmployee;
          } else {
            employees.add(newEmployee);
          }
        });

        Navigator.pop(context);
      } else {
        throw Exception('Failed to save employee: ${response.body}');
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _showEmployeeDetails(Employee employee) {
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
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(Icons.badge, "No", employee.no),
                  _buildDetailItem(Icons.person, "Name", employee.name),
                  _buildDetailItem(Icons.email, "Email", employee.email),
                  _buildDetailItem(Icons.credit_card, "NIK", employee.nik),
                  _buildDetailItem(
                    employee.gender.toLowerCase() == "female" ? Icons.female : Icons.male,
                    "Gender",
                    employee.gender,
                  ),
                  _buildDetailItem(Icons.cake, "DOB", employee.dob),
                  _buildDetailItem(Icons.location_on, "Place of Birth", employee.pob),
                  _buildDetailItem(Icons.work, "Position", employee.position),
                  _buildDetailItem(Icons.location_city, "Address", employee.address),
                  _buildDetailItem(Icons.date_range, "Join Date", employee.joinDate),
                  _buildDetailItem(Icons.phone, "Phone", employee.phone),
                ],
              ),
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

  void _confirmDelete(Employee employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: Text("Are you sure you want to delete ${employee.name}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteEmployee(employee.uid);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEmployee(String uid) async {
    const String functionUrl = 'https://api-ryy35i7zhq-uc.a.run.app/delete-user';

    try {
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'uid': uid}),
      );

      if (response.statusCode == 200) {
        print("User deleted successfully: ${jsonDecode(response.body)}");
        setState(() {
          employees.removeWhere((e) => e.uid == uid);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Employee deleted successfully")),
        );
      } else {
        print("Failed to delete user: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  Widget _buildField(TextEditingController controller, String label,
      {bool isNik = false, bool isDate = false, bool isRequired = false, bool isEditable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: controller,
        maxLength: isNik ? 16 : null,
        readOnly: isDate || !isEditable,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: isDate ? const Icon(Icons.calendar_today) : null,
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return "$label is required";
          }
          if (isNik && value!.length != 16) {
            return "NIK must be exactly 16 digits.";
          }
          return null;
        },
        onTap: isDate
            ? () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  controller.text = pickedDate.toLocal().toString().split(' ')[0];
                }
              }
            : null,
      ),
    );
  }

  Widget _buildGenderField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: DropdownButtonFormField<String>(
        value: controller.text.isNotEmpty ? controller.text : null,
        items: const [
          DropdownMenuItem(value: "Male", child: Text("Male")),
          DropdownMenuItem(value: "Female", child: Text("Female")),
        ],
        onChanged: (value) {
          controller.text = value!;
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.isEmpty ? "Gender is required" : null,
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(value),
        ),
        const Divider(),
      ],
    );
  }

  List<Employee> get _filteredEmployees {
    final query = _searchController.text.toLowerCase();
    return employees.where((e) => e.name.toLowerCase().contains(query)).toList();
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showEmployeeDialog(),
                  icon: const Icon(Icons.person_add, color: AppColors.text1),
                  label: const Text("Add employee", style: TextStyle(color: AppColors.text1)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
                    showBottomBorder: true,
                    rows: _filteredEmployees
                        .map((employee) => DataRow(cells: [
                              DataCell(Text(employee.no)),
                              DataCell(Text(employee.name)),
                              DataCell(Text(employee.nik)),
                              DataCell(Text(employee.email)),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.image, color: Colors.teal),
                                    onPressed: () => _showEmployeeFaceImage(employee.uid),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.orange),
                                    onPressed: () => _showEmployeeDetails(employee),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEmployeeDialog(employee: employee),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(employee),
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
