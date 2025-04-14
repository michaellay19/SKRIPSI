import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skripsi/constants/app_strings.dart';
import 'package:skripsi/pages/admin/all_admin_pages.dart';
import 'package:skripsi/pages/users/all_users_pages.dart';

class MyAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  MyAuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      notifyListeners();

      if (user != null) {
        await _saveUserLocally(user.email!);
      }
    });

    _loadUserFromLocal();
  }

  User? get user => _user;
  String get adminEmail => AppStrings.adminEmail;

  Future<void> signIn(String email, String password, BuildContext context) async {
    String trimmedEmail = email.trim();
    String trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      _showSnackBar(context, 'Please enter both email and password.');
      return;
    }

    bool isWeb = kIsWeb;
    bool isAdmin = trimmedEmail.toLowerCase() == AppStrings.adminEmail;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      Navigator.pop(context);

      if (userCredential.user != null) {
        _user = userCredential.user;
        notifyListeners();

        await _saveUserLocally(trimmedEmail);

        if (isWeb && isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AllAdminPage()),
          );
        } else if (!isWeb && !isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AllPages()),
          );
        } else {
          _showSnackBar(context, 'Access denied.');
        }
      } else {
        _showSnackBar(context, 'Email or password is incorrect. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      String errorMessage = _getErrorMessage(e);
      debugPrint(e.toString());
      _showSnackBar(context, errorMessage);
    } catch (e) {
      Navigator.pop(context);
      debugPrint("Unexpected error: $e");
      _showSnackBar(context, 'An unexpected error occurred. Please try again.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _clearLocalUser();
    notifyListeners();
  }

  Future<void> _saveUserLocally(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedUserEmail', email);
  }

  Future<void> _loadUserFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('savedUserEmail');

    if (email != null) {
      try {
        _user = _auth.currentUser;
        notifyListeners();
      } catch (e) {
        print("Error auto-login: $e");
      }
    }
  }

  Future<void> _clearLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('savedUserEmail');
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with that email.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'too-many-requests':
        return 'Too many failed attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
