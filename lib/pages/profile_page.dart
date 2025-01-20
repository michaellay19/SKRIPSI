import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/pages/login_page.dart';
import 'package:skripsi/provider/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfileModel {
  String name;
  String role;
  String profileImage;

  ProfileModel({
    required this.name,
    required this.role,
    required this.profileImage,
  });
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = 'Unknown';
  String _role = '-';
  String _profileImage = '';
  final _firestore = FirebaseFirestore.instance;
  final _uid = 'uid'; // ganti dengan uid pengguna

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final doc = await _firestore.collection('users').doc(_uid).get();
    if (doc.exists) {
      setState(() {
        _name = doc.get('name') ?? 'Unknown';
        _role = doc.get('role') ?? '-';
        _profileImage = doc.get('profileImage') ?? '';
      });
    }
  }

  void _logout() async {
    await Provider.of<MyAuthProvider>(context, listen: false).signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _editProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          profileModel: ProfileModel(
            name: _name,
            role: _role,
            profileImage: _profileImage,
          ),
          onProfileUpdate: (updatedProfileModel) {
            setState(() {
              _name = updatedProfileModel.name;
              _role = updatedProfileModel.role;
              _profileImage = updatedProfileModel.profileImage;
            });
          },
        ),
      ),
    );
  }

  void _navigateToMyProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MyProfilePage(),
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

  void _navigateToPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage.isEmpty
                    ? const AssetImage('images/profile.jpeg')
                    : _profileImage.startsWith('http')
                        ? NetworkImage(_profileImage)
                        : FileImage(File(_profileImage)),
              ),
              const SizedBox(height: 10),
              Text(
                _name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                _role,
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
                child: const Text('Edit Profile'),
              ),
              const SizedBox(height: 30),
              _buildMenuOption(Icons.person, 'My Profile', _navigateToMyProfile),
              _buildMenuOption(Icons.settings, 'Settings', _navigateToSettings),
              _buildMenuOption(Icons.article, 'Terms & Conditions',
                  _navigateToTermsAndConditions),
              _buildMenuOption(Icons.privacy_tip, 'Privacy Policy',
                  _navigateToPrivacyPolicy),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _logout,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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

class EditProfilePage extends StatefulWidget {
  final ProfileModel profileModel;
  final Function(ProfileModel) onProfileUpdate;

  const EditProfilePage(
      {Key? key, required this.profileModel, required this.onProfileUpdate})
      : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profileModel.name;
    _roleController.text = widget.profileModel.role;
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final _firestore = FirebaseFirestore.instance;
      final _uid = 'uid'; // ganti dengan uid pengguna
      await _firestore.collection('users').doc(_uid).set({
        'name': _nameController.text,
        'role': _roleController.text,
        'profileImage': _profileImage != null
            ? _profileImage!.path
            : widget.profileModel.profileImage,
      });
      widget.onProfileUpdate(
        ProfileModel(
          name: _nameController.text,
          role: _roleController.text,
          profileImage: _profileImage != null
              ? _profileImage!.path
              : widget.profileModel.profileImage,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _selectImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : widget.profileModel.profileImage.isEmpty
                        ? const AssetImage('images/profile.jpeg')
                        : widget.profileModel.profileImage.startsWith('http')
                            ? NetworkImage(widget.profileModel.profileImage)
                            : FileImage(File(widget.profileModel.profileImage)),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _selectImage,
                child: Text('Pilih Gambar Profil'),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Role'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your role';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyProfilePage extends StatelessWidget {
  const MyProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: const Center(
        child: const Text('My Profile Page'),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Text('Settings Page'),
      ),
    );
  }
}

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: const Center(
        child: Text('Terms & Conditions Page'),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: const Center(
        child: Text('Privacy Policy Page'),
      ),
    );
  }
}