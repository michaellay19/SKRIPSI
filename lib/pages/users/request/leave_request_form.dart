import 'package:flutter/material.dart';
import 'package:skripsi/model/leave_request_model.dart';

class LeaveRequestForm extends StatefulWidget {
  final Function(LeaveRequest) onSubmit;

  const LeaveRequestForm({super.key, required this.onSubmit});

  @override
  State<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends State<LeaveRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String _selectedLeaveType = 'Medical Leave';
  DateTime? _startDate;
  DateTime? _endDate;

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

      widget.onSubmit(
        LeaveRequest(
          id: '',
          leaveType: _selectedLeaveType,
          startDate: _startDate!,
          endDate: _endDate!,
          reason: _reasonController.text,
          isApproved: false,
        ),
      );

      Navigator.of(context).pop();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Leave Request'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildDropdown('Leave Type', _selectedLeaveType, (value) {
                setState(() {
                  _selectedLeaveType = value!;
                });
              }),
              const SizedBox(height: 16),
              _buildDateField('Start Date', _startDate, () => _pickDate(true)),
              const SizedBox(height: 16),
              _buildDateField('End Date', _endDate, () => _pickDate(false)),
              const SizedBox(height: 16),
              _buildTextField('Reason for Leave', _reasonController, maxLines: 3),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submitForm,
          child: const Text('Submit'),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  date != null 
                    ? date.toFormattedString()
                    : 'Select Date',
                  style: TextStyle(
                      color: date == null ? Colors.black54 : Colors.black),
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_today,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
