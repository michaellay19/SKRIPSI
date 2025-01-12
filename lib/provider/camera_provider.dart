import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class CameraProvider with ChangeNotifier {
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
      Reference ref =
          _storage.ref().child('users/$userId/attendance/$fileName.jpg');

      await ref.putFile(image);
      String downloadUrl = await ref.getDownloadURL();

      Map<String, dynamic> imageData = {
        'url': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
        'userEmail': currentUser.email,
        'activityType': activityType,
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .add(imageData);

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
        .map((snapshot) => snapshot.docs.map((doc) {
              final uploadedAt = doc['uploadedAt']?.toDate() ?? DateTime.now();
              final date = uploadedAt.toLocal().toString().substring(0, 10);
              final time = uploadedAt.toLocal().toString().substring(11, 16);
              final activityType = doc['activityType'];

              return {
                'url': doc['url'],
                'date': date,
                'time': time,
                'activityType': activityType,
              };
            }).toList());
  }
}
