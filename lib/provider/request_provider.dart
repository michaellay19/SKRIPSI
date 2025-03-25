import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skripsi/model/leave_request_model.dart';

class LeaveRequestProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  Future<void> addLeaveRequest(LeaveRequest request) async {
    try {
      if (_currentUserId.isEmpty) {
        throw Exception('User not logged in');
      }

      await _firestore.collection('users').doc(_currentUserId).collection('leave_requests').add({
        'leaveType': request.leaveType,
        'startDate': request.startDate.toIso8601String(),
        'endDate': request.endDate.toIso8601String(),
        'reason': request.reason,
        'status': request.status,
      });

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to submit leave request: $e');
    }
  }

  Stream<List<LeaveRequest>> fetchLeaveRequests() {
    if (_currentUserId.isEmpty) {
      return Stream.error('User not logged in');
    }

    return _firestore.collection('users').doc(_currentUserId).collection('leave_requests').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LeaveRequest(
          id: doc.id,
          leaveType: data['leaveType'],
          startDate: DateTime.parse(data['startDate']),
          endDate: DateTime.parse(data['endDate']),
          reason: data['reason'],
          status: data['status'] ?? "Pending",
        );
      }).toList();
    });
  }

  Future<void> removeLeaveRequest(String requestId) async {
    try {
      if (_currentUserId.isEmpty) {
        throw Exception('User not logged in');
      }

      await _firestore.collection('users').doc(_currentUserId).collection('leave_requests').doc(requestId).delete();

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to cancel leave request: $e');
    }
  }
}
