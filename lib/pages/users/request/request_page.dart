import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/pages/users/request/leave_details_page.dart';
import 'package:skripsi/model/leave_request_model.dart';
import 'package:skripsi/pages/users/request/leave_request_form.dart';
import 'package:skripsi/provider/request_provider.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  bool _isDeleteMode = false;

  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
    });
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, LeaveRequest request) async {
    final leaveRequestProvider = Provider.of<LeaveRequestProvider>(context, listen: false);

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete the request for ${request.leaveType}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await leaveRequestProvider.removeLeaveRequest(request.id);
      _showSnackBar(context, "Leave request deleted successfully.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveRequestProvider = Provider.of<LeaveRequestProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isDeleteMode ? Icons.check : Icons.delete, color: _isDeleteMode ? Colors.green : Colors.red),
            onPressed: _toggleDeleteMode,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<LeaveRequest>>(
              stream: leaveRequestProvider.fetchLeaveRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final leaveRequests = snapshot.data ?? [];

                return ListView.builder(
                  itemCount: leaveRequests.length,
                  itemBuilder: (context, index) {
                    final request = leaveRequests[index];
                    return ListTile(
                      title: Text(request.leaveType),
                      subtitle: Text(_formatDate(request.startDate, request.endDate)),
                      trailing: IconButton(
                        icon: _isDeleteMode
                            ? const Icon(Icons.delete, color: Colors.red)
                            : _getStatusIcon(request.status),
                        onPressed: () {
                          if (_isDeleteMode) {
                            _confirmDelete(context, request);
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LeaveDetailsPage(
                              leaveType: request.leaveType,
                              startDate: request.startDate,
                              endDate: request.endDate,
                              reason: request.reason,
                              status: request.status,
                            ),
                          ),
                        );
                      },
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
                showDialog(
                  context: context,
                  builder: (context) => LeaveRequestForm(
                    onSubmit: (request) {
                      leaveRequestProvider.addLeaveRequest(request);
                      _showSnackBar(context, 'Leave request submitted successfully.');
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Apply Leave', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.access_time_filled, color: Colors.orangeAccent);
    }
  }

  String _formatDate(DateTime startDate, DateTime endDate) {
    if (startDate.isAtSameMomentAs(endDate)) {
      return startDate.toFormattedString();
    }
    return '${startDate.toFormattedString()} to ${endDate.toFormattedString()}';
  }
}
