import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/pages/users/request/leave_details_page.dart';
import 'package:skripsi/model/leave_request_model.dart';
import 'package:skripsi/pages/users/request/leave_request_form.dart';
import 'package:skripsi/provider/request_provider.dart';

class RequestPage extends StatelessWidget {
  const RequestPage({super.key});

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                      subtitle: Text(
                          '${request.startDate.toString().substring(0, 10)} to ${request.endDate.toString().substring(0, 10)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          leaveRequestProvider.removeLeaveRequest(request.id); 
                          _showSnackBar(context, 'Leave request canceled successfully.');
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
              child: const Text('Apply Leave',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}