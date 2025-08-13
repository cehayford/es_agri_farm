import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/user_model.dart';
import '../../../utils/utils.dart';
import '../../../widgets/widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthController>(context, listen: false).user;
      if (user != null) {
        _fullNameController.text = user.fullname;
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authController = Provider.of<AuthController>(context, listen: false);

      // Create an updated user object
      UserModel updatedUser = authController.user!.copyWith(
        fullname: _fullNameController.text.trim(),
      );

      // Update the profile in Firebase
      await _updateUserProfile(authController, updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to update user profile and handle image upload
  Future<void> _updateUserProfile(AuthController authController, UserModel user) async {
    String? profileImageUrl;

    // If a new image was selected, upload it to Firebase Storage
    if (_selectedImage != null) {
      // You'll need to implement image upload logic here
      // For now, we'll just update the profile with the new name
    }

    // Call the existing updateProfile method in AuthController
    final success = await authController.updateProfile(
      userId: user.id,
      fullname: _fullNameController.text.trim(),
      profileImageUrl: profileImageUrl,
    );

    if (!success) {
      throw Exception(authController.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthController>(context).user;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.lightGrey,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (user.profilePicture != null && user.profilePicture!.isNotEmpty
                              ? NetworkImage(user.profilePicture!) as ImageProvider
                              : null),
                      child: (_selectedImage == null &&
                              (user.profilePicture == null || user.profilePicture!.isEmpty))
                          ? const Icon(Icons.person, size: 60, color: AppColors.grey)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Email display (non-editable)
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                  helperText: 'Email cannot be changed',
                  filled: true,
                  fillColor: AppColors.lightGrey.withAlpha(50),
                ),
                controller: TextEditingController(text: user.email),
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Update button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('UPDATE PROFILE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
