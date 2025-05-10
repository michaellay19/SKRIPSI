import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
        employeeStatus: doc["employeeStatus"],
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
        "employeeStatus",
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
                  _buildField(controllers["gender"]!, "Gender"),
                  _buildField(controllers["dob"]!, "DOB", isDate: true),
                  _buildField(controllers["pob"]!, "Place of Birth"),
                  _buildField(controllers["position"]!, "Position"),
                  _buildField(controllers["religion"]!, "Religion"),
                  _buildField(controllers["address"]!, "Address"),
                  _buildField(controllers["employeeStatus"]!, "Employee Status"),
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
    try {
      final firestore = FirebaseFirestore.instance;
      String uid;

      if (!isEditing) {
        final auth = FirebaseAuth.instance;
        UserCredential userCredential = await auth.createUserWithEmailAndPassword(
          email: controllers["email"]!.text,
          password: "User123",
        );
        uid = userCredential.user!.uid;
      } else {
        uid = employee!.uid;
      }

        if (!isEditing) {
        await firestore.collection("users").doc(uid).set({
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      final employeeData = Employee(
        uid: uid,
        no: isEditing ? employee!.no : (employees.length + 1).toString().padLeft(4, '0'),
        name: controllers["name"]!.text,
        nik: controllers["nik"]!.text,
        email: controllers["email"]!.text,
        gender: controllers["gender"]!.text,
        dob: controllers["dob"]!.text,
        pob: controllers["pob"]!.text,
        position: controllers["position"]!.text,
        religion: controllers["religion"]!.text,
        address: controllers["address"]!.text,
        employeeStatus: controllers["employeeStatus"]!.text,
        joinDate: controllers["joinDate"]!.text,
        phone: controllers["phone"]!.text,
      );

      await firestore.collection("users").doc(uid).collection("profile").doc(uid).set(employeeData.toMap());

      setState(() {
        if (isEditing) {
          int index = employees.indexWhere((e) => e.uid == uid);
          print(index);
          print(employees);
          if (index != -1) employees[index] = employeeData;
          print(employees);
        } else {
          employees.add(employeeData);
        }
      });

      Navigator.pop(context);
    } catch (e) {
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
                  _buildDetailItem(Icons.male, "Gender", employee.gender),
                  _buildDetailItem(Icons.cake, "DOB", employee.dob),
                  _buildDetailItem(Icons.location_on, "Place of Birth", employee.pob),
                  _buildDetailItem(Icons.work, "Position", employee.position),
                  _buildDetailItem(Icons.location_city, "Address", employee.address),
                  _buildDetailItem(Icons.check_circle, "Employee Status", employee.employeeStatus),
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
                                    icon: const Icon(Icons.visibility, color: Colors.orange),
                                    onPressed: () => _showEmployeeDetails(employee),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEmployeeDialog(employee: employee),
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
