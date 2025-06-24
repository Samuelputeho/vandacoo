import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vandacoo/core/constants/colors.dart';
import 'package:vandacoo/features/profile/presentation/bloc/edit_user_info_bloc/edit_user_info_bloc.dart'; // Import the EditUserInfoBloc
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/features/profile/presentation/pages/profile_screen.dart'
    show ProfileScreen;

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentBio;
  final String currentEmail;
  final String userId;
  final UserEntity user;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentBio,
    required this.currentEmail,
    required this.userId,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController bioController;
  late TextEditingController emailController;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    bioController = TextEditingController(text: widget.currentBio);
    emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Crop the image
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: AppColors.primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          selectedImage = File(croppedFile.path);
        });
      }
    }
  }

  void _updateProfile() {
    try {
      final String? newName = nameController.text != widget.currentName
          ? nameController.text
          : null;
      final String? newBio =
          bioController.text != widget.currentBio ? bioController.text : null;
      final String? newEmail = emailController.text != widget.currentEmail
          ? emailController.text
          : null;

      if (newName == null &&
          newBio == null &&
          newEmail == null &&
          selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes made'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Dispatch the event to EditUserInfoBloc
      context.read<EditUserInfoBloc>().add(
            UpdateUserInfoEvent(
              userId: widget.userId,
              name: newName,
              email: newEmail,
              bio: newBio,
              propicFile:
                  selectedImage, // Pass the File object for image upload
            ),
          );
    } catch (e) {
      print('Error in _updateProfile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            //Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(user: widget.user),
              ),
            );
          },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: BlocConsumer<EditUserInfoBloc, EditUserInfoState>(
        listener: (context, state) {
          if (state is EditUserInfoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Dismiss',
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  textColor: Colors.white,
                ),
              ),
            );
            print('Profile update failed: ${state.message}');
          } else if (state is EditUserInfoSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // Add a slight delay before navigation
            Future.delayed(const Duration(milliseconds: 500), () {
              Navigator.pop(
                  context, true); // Pass true to indicate successful update
            });
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!)
                            : null,
                        child: selectedImage == null
                            ? const Icon(Icons.add_a_photo, size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: state is EditUserInfoLoading
                          ? null
                          : _updateProfile, // Disable button while loading
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                      ),
                      child: state is EditUserInfoLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
              if (state is EditUserInfoLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
