import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AttendanceProvider with ChangeNotifier {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> uploadImage(File image, String activityType) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No authenticated user found");
      }
      final String userId = currentUser.uid;

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('users/$userId/attendance/$fileName.jpg');

      await ref.putFile(image);
      String downloadUrl = await ref.getDownloadURL();

      final now = DateTime.now();
      bool isLate = false;
      bool noDaily = false;

      if (activityType == 'Clock In') {
        isLate = now.hour > 9 || (now.hour == 9 && now.minute > 3);
        noDaily = now.hour >= 9 && now.minute > 30;
      }

      Map<String, dynamic> imageData = {
        'url': downloadUrl,
        'uploadedAt': Timestamp.now(),
        'userEmail': currentUser.email,
        'activityType': activityType,
        'late': isLate,
        'noDaily': noDaily,
      };

      await _firestore.collection('users').doc(userId).collection('attendance').add(imageData);

      print('Image data saved successfully to Firestore.');
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> fetchActivities() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("User not authenticated");
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('attendance')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final Timestamp uploadedAt = doc['uploadedAt'];
              final DateTime dateTime = uploadedAt.toDate();
              final date =
                  '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
              final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
              final activityType = doc['activityType'];
              final bool late = doc.data().containsKey('late') ? doc['late'] : false;

              return {
                'url': doc['url'],
                'date': date,
                'time': time,
                'activityType': activityType,
                'late': late,
              };
            })
            .where((element) => element.isNotEmpty)
            .toList());
  }

  Map<String, List<Map<String, dynamic>>> groupActivitiesByDate(List<Map<String, dynamic>> activities) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var activity in activities) {
      final date = activity['date'];
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(activity);
    }
    return grouped;
  }

  int countMonthlyLates(List<Map<String, dynamic>> activities, DateTime selectedMonth) {
    return activities.where((activity) {
      if (activity['activityType'] != 'Clock In') return false;

      final dateParts = activity['date'].split('-');
      if (dateParts.length != 3) return false;

      final activityMonth = int.tryParse(dateParts[1]);
      final activityYear = int.tryParse(dateParts[2]);
      if (activityMonth != selectedMonth.month || activityYear != selectedMonth.year) return false;

      return activity['late'] == true;
    }).length;
  }
}
