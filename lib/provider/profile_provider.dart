import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _name = '';
  String _role = '';
  String _profileImage = '';
  String _faceImage = '';

  String get name => _name;
  String get role => _role;
  String get profileImage => _profileImage;
  String get faceImage => _faceImage;

  Future<void> loadProfile() async {
    try {
      final User? currentUser  = _auth.currentUser ;
      if (currentUser == null) throw Exception("User  not authenticated");
      
      final doc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (doc.exists && doc.data() != null){
        final data = doc.data() as Map<String, dynamic>; 

        _name = data.containsKey('name') ? data['name'] as String : "Unknown";
        _role = data.containsKey('role') ? data['role'] as String : "-";
        _profileImage = data.containsKey('profileImage') ? data['profileImage'] as String : "";
        _faceImage = data.containsKey('faceImage') ? data['faceImage'] as String : "";
      } else {
        _name = "Unknown";
        _role = "-";
        _profileImage = '';
        _faceImage = '';
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading profile: $e');
      throw Exception('Failed to load profile');
    }
  }

  Future<void> updateProfile(String name, String role, File? profileImage) async {
    try {
      final User? currentUser  = _auth.currentUser;
      if (currentUser  == null) throw Exception("User  not authenticated");

      _name = name;
      _role = role;

      if (profileImage != null && profileImage.existsSync()) {
        String fileName = 'users/${currentUser.uid}/profile/${currentUser.uid}.jpg';
        Reference ref = _storage.ref().child(fileName);

        await ref.putFile(profileImage);
        _profileImage = await ref.getDownloadURL();
      }
      
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set({
        'name': _name,
        'role': _role,
        'profileImage': _profileImage,
      }, SetOptions(merge: true));

      await loadProfile();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw Exception('Failed to update profile');
    }
  }
}
