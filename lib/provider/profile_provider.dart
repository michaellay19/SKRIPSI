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

  String get name => _name;
  String get role => _role;
  String get profileImage => _profileImage;

  Future<void> loadProfile() async {
    try {
      final User? currentUser  = _auth.currentUser ;
      if (currentUser == null) {
        throw Exception("User  not authenticated");
      }

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists){
        _name = doc.get('name');
        _role = doc.get('role');
        _profileImage = doc.get('profileImage');
      } else {
        _name = "Unknown";
        _role = "-";
        _profileImage = '';
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
      if (currentUser  == null) {
        throw Exception("User  not authenticated");
      }

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
