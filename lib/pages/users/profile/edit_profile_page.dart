import 'dart:io';
import 'package:flutter/material.dart';
import 'package:skripsi/model/profile_model.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileModel profileModel;
  final Function(ProfileModel) onProfileUpdate;

  const EditProfilePage({
    super.key,
    required this.profileModel,
    required this.onProfileUpdate,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profileModel.name;
    _positionController.text = widget.profileModel.position;
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final profileModel = ProfileModel(
        name: _nameController.text,
        position: _positionController.text,
        profileImage: _profileImage?.path ?? widget.profileModel.profileImage,
      );

      widget.onProfileUpdate(profileModel);
      Navigator.of(context).pop();
    }
  }

  void _selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
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
        backgroundColor: Colors.blue,
        elevation: 0,
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
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _selectImage,
                child: const Text('Select Profile Image'),
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
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'position'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your position';
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
