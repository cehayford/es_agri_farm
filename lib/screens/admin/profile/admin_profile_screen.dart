import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../controllers/auth_controller.dart';
import '../../../utils/utils.dart';
import '../../../widgets/widgets.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isChangingPassword = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _initializeUserData() {
    final user = Provider.of<AuthController>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.fullname;
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error selecting image'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);
    final user = authController.user;

    if (user == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? profilePictureUrl = user.profilePicture;

      // Upload new image if selected
      if (_selectedImage != null) {
        final storageRef = _storage.ref().child('profile_pictures/${user.id}.jpg');
        await storageRef.putFile(_selectedImage!);
        profilePictureUrl = await storageRef.getDownloadURL();
      }

      // Update user document in Firestore
      await _firestore.collection(AppConstants.usersCollection).doc(user.id).update({
        'fullname': _nameController.text.trim(),
        'profilePicture': profilePictureUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local user model
      final updatedUser = user.copyWith(
        fullname: _nameController.text.trim(),
        profilePicture: profilePictureUrl,
      );

      // Force refresh the state
      authController.refreshUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');

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

  Future<void> _changePassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      // Direct password update without reauthentication
      await _auth.currentUser!.updatePassword(_newPasswordController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Clear the password fields
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      print('Error changing password: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    await authController.logout();
    // No need for navigation - the app.dart will handle redirecting to login
  }

  Future<void> _showChangePasswordDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              children: [

                // New password field
                CustomTextField(
                  label: 'New Password',
                  hint: 'Enter your new password',
                  controller: _newPasswordController,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    } else if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password field
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Confirm your new password',
                  controller: _confirmPasswordController,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    } else if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _changePassword();
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture Section
            Center(
              child: Stack(
                children: [
                  // Profile image
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: AppColors.lightGrey,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : (user.profilePicture != null && user.profilePicture!.isNotEmpty
                            ? NetworkImage(user.profilePicture!)
                            : null),
                    child: (user.profilePicture == null || user.profilePicture!.isEmpty) && _selectedImage == null
                        ? const Icon(Icons.person, size: 64, color: AppColors.grey)
                        : null,
                  ),

                  // Edit button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Email display
            Text(
              user.email,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            // Role badge
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Profile Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 16),

                  // Name field
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Update button
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Update Profile',
                      onPressed: _updateProfile,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Account Settings
            const Text(
              'Account Settings',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),

            // Change Password Button
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: AppColors.primary),
              ),
              title: const Text('Change Password'),
              subtitle: const Text('Update your password'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showChangePasswordDialog();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.grey.withOpacity(0.3)),
              ),
            ),
            const SizedBox(height: 12),

            // Logout Button
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: AppColors.error),
              ),
              title: const Text('Logout'),
              subtitle: const Text('Sign out from your account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showLogoutConfirmation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.grey.withOpacity(0.3)),
              ),
            ),

            const SizedBox(height: 32),

            // App Info
            Text(
              'App Version ${AppConstants.appVersion}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
