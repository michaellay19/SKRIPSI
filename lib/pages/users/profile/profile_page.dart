import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/model/profile_model.dart';
import 'package:skripsi/pages/users/profile/edit_profile_page.dart';
import 'package:skripsi/pages/users/profile/setting_page.dart';
import 'package:skripsi/pages/users/profile/terms_and_conditions_page.dart';
import 'package:skripsi/provider/auth_provider.dart';
import 'package:skripsi/provider/profile_provider.dart';
import 'package:skripsi/pages/auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.loadProfile();
  }

  void _logout() async {
    await Provider.of<MyAuthProvider>(context, listen: false).signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _editProfile() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          profileModel: ProfileModel(
            name: profileProvider.name,
            role: profileProvider.role,
            profileImage: profileProvider.profileImage,
          ),
          onProfileUpdate: (updatedProfileModel) {
            profileProvider.updateProfile(
              updatedProfileModel.name,
              updatedProfileModel.role,
              File(updatedProfileModel.profileImage),
            );
          },
        ),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _navigateToTermsAndConditions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TermsAndConditionsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profileProvider.profileImage.isEmpty
                ? const AssetImage('images/profile.jpeg')
                : NetworkImage(profileProvider.profileImage) as ImageProvider,
            ),
            const SizedBox(height: 10),
            Text(
              profileProvider.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              profileProvider.role,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _editProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Edit Profile', style: TextStyle(color: Colors.white),),
            ),
            const SizedBox(height: 30),
            _buildMenuOption(Icons.settings, 'Settings', _navigateToSettings),
            _buildMenuOption(Icons.article, 'Terms & Conditions', _navigateToTermsAndConditions),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _logout,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    'Log out',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}