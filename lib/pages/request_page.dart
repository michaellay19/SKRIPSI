import 'package:flutter/material.dart';

class LeaveRequest {
  final String title;
  final String leaveType;
  final String contactNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;

  LeaveRequest({
    required this.title,
    required this.leaveType,
    required this.contactNumber,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });
}

class RequestPage extends StatefulWidget {
  const RequestPage({Key? key}) : super(key: key);

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _reasonController = TextEditingController();
  String _selectedLeaveType = 'Medical Leave';
  DateTime? _startDate;
  DateTime? _endDate;
  List<LeaveRequest> _leaveRequests = [];

  void _pickDate(bool isStartDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        _showSnackBar('Please select both start and end dates.');
        return;
      }
      if (_startDate!.isAfter(_endDate!)) {
        _showSnackBar('End date must be after start date.');
        return;
      }

      setState(() {
        _leaveRequests.add(LeaveRequest(
          title: _titleController.text,
          leaveType: _selectedLeaveType,
          contactNumber: _contactNumberController.text,
          startDate: _startDate!,
          endDate: _endDate!,
          reason: _reasonController.text,
        ));
      });

      _titleController.clear();
      _contactNumberController.clear();
      _reasonController.clear();
      _startDate = null;
      _endDate = null;

      _showSnackBar('Leave request submitted successfully.');
    } else {
      _showSnackBar('Please fill in all required fields.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _leaveRequests.length,
              itemBuilder: (context, index) {
                final request = _leaveRequests[index];
                return ListTile(
                  title: Text(request.title),
                  subtitle: Text(
                      '${request.leaveType} - ${request.startDate.year}-${request.startDate.month}-${request.startDate.day} to ${request.endDate.year}-${request.endDate.month}-${request.endDate.day}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeaveDetailsPage(
                          title: request.title,
                          leaveType: request.leaveType,
                          contactNumber: request.contactNumber,
                          startDate: request.startDate,
                          endDate: request.endDate,
                          reason: request.reason,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                _showLeaveRequestForm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Apply Leave',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveRequestForm() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Leave Request'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField('Title', _titleController),
                  const SizedBox(height: 16),
                  _buildDropdown('Leave Type', _selectedLeaveType, (value) {
                    setState(() {
                      _selectedLeaveType = value!;
                    });
                  }),
                  const SizedBox(height: 16),
                  _buildTextField('Contact Number', _contactNumberController,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildDateField(
                      'Start Date', _startDate, () => _pickDate(true)),
                  const SizedBox(height: 16),
                  _buildDateField('End Date', _endDate, () => _pickDate(false)),
                  const SizedBox(height: 16),
                  _buildTextField('Reason for Leave', _reasonController,
                      maxLines: 3),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _submitForm();
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required.';
            }
            return null;
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
      String label, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          items: ['Medical Leave', 'Casual Leave', 'Annual Leave']
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              date != null
                  ? '${date.year}-${date.month}-${date.day}'
                  : 'Select Date',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }
}

class LeaveDetailsPage extends StatelessWidget {
  final String title;
  final String leaveType;
  final String contactNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;

  const LeaveDetailsPage({
    Key? key,
    required this.title,
    required this.leaveType,
    required this.contactNumber,
    required this.startDate,
    required this.endDate,
    required this.reason,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Leave Details', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Title', title),
            _buildDetailRow('Leave Type', leaveType),
            _buildDetailRow('Contact Number', contactNumber),
            _buildDetailRow('Start Date',
                '${startDate.year}-${startDate.month}-${startDate.day}'),
            _buildDetailRow(
                'End Date', '${endDate.year}-${endDate.month}-${endDate.day}'),
            _buildDetailRow('Reason', reason),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }
}
