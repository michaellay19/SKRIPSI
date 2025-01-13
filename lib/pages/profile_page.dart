import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/pages/login_page.dart';
import 'package:skripsi/provider/auth_provider.dart';

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
  ProfileModel _profileModel = ProfileModel(
    name: 'Michael Mitc',
    role: 'Lead UI/UX Designer',
    profileImage: 'images/profile.jpeg',
  );

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
          profileModel: _profileModel,
          onProfileUpdate: (updatedProfileModel) {
            setState(() {
              _profileModel = updatedProfileModel;
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
                backgroundImage: AssetImage(_profileModel.profileImage),
              ),
              const SizedBox(height: 10),
              Text(
                _profileModel.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                _profileModel.role,
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
              _buildMenuOption(
                  Icons.person, 'My Profile', _navigateToMyProfile),
              _buildMenuOption(Icons.settings, 'Settings', _navigateToSettings),
              _buildMenuOption(Icons.article, 'Terms & Conditions',
                  _navigateToTermsAndConditions),
              _buildMenuOption(Icons.privacy_tip, 'Privacy Policy',
                  _navigateToPrivacyPolicy),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _logout,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text(
                      'Log Out',
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

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profileModel.name;
    _roleController.text = widget.profileModel.role;
  }

  void _updateProfile() {
    if (_formKey.currentState!.validate()) {
      widget.onProfileUpdate(
        ProfileModel(
          name: _nameController.text,
          role: _roleController.text,
          profileImage: widget.profileModel.profileImage,
        ),
      );
      Navigator.of(context).pop();
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text('Update Profile'),
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
      body: Center(
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
      body: Center(
        child: const Text('Settings Page'),
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
      body: Center(
        child: const Text('Terms & Conditions Page'),
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
      body: Center(
        child: const Text('Privacy Policy Page'),
      ),
    );
  }
}
