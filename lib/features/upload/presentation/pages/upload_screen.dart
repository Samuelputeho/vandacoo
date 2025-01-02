import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'dart:io';
import 'package:vandacoo/features/all_posts/presentation/bloc/post_bloc.dart';
import 'package:vandacoo/core/constants/app_consts.dart';
import '../../../../core/constants/colors.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _thumbnailImage;
  File? _selectedVideo;
  String? _selectedOption;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();

  String? _selectedCategory;
  String? _selectedRegion;

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _thumbnailImage = File(pickedFile.path); // Store the image
        _selectedVideo = null; // Clear selected video if an image is picked
      });
    }
  }

  // Function to pick a video from the gallery
  Future<void> _pickVideo() async {
    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedVideo = File(pickedFile.path); // Store the video
        _thumbnailImage = null; // Clear selected image if a video is picked
      });
    }
  }

  // Function to handle upload action
  void _uploadPost() {
    if (_thumbnailImage != null && _selectedOption != null) {
      final posterId =
          (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
      // Trigger the upload event
      context.read<PostBloc>().add(PostUploadEvent(
            userId: posterId, // Replace with actual poster ID
            caption: _captionController.text,
            image: _thumbnailImage,
            category: _categoryController.text,
            region: _regionController.text,
            postType: _selectedOption!,
          ));
    } else {
      // Show error message if image or option is not selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image and an option')),
      );
    }
  }

  // Function to handle option selection
  void _selectOption(String option) {
    setState(() {
      _selectedOption = option; // Update selected option
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton("Story", "Story", isDark),
                  const SizedBox(width: 20),
                  _buildOptionButton("Post", "Post", isDark),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMediaSection(isDark),
                  const SizedBox(height: 24),
                  _buildInputField(
                    "Caption",
                    _captionController,
                    maxLines: 3,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildDropdownField(
                    "Category",
                    _selectedCategory,
                    AppConstants.categories,
                    (value) {
                      setState(() {
                        _selectedCategory = value;
                        _categoryController.text = value ?? '';
                      });
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildDropdownField(
                    "Region",
                    _selectedRegion,
                    AppConstants.regions,
                    (value) {
                      setState(() {
                        _selectedRegion = value;
                        _regionController.text = value ?? '';
                      });
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _uploadPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Upload Post",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String text, String option, bool isDark) {
    bool isSelected = _selectedOption == option;
    return Expanded(
      child: TextButton(
        onPressed: () => _selectOption(option),
        style: TextButton.styleFrom(
          backgroundColor: isSelected
              ? (isDark ? Colors.white24 : Colors.white)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.white,
              width: 1,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.white : AppColors.primaryColor)
                : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMediaButton(
                "Select Image",
                _pickImage,
                Icons.image,
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMediaButton(
                "Select Video",
                _pickVideo,
                Icons.video_library,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark ? Colors.grey[900] : Colors.grey[200],
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
          child: _selectedVideo != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_file,
                        size: 48,
                        color: isDark ? Colors.grey[400] : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Video Selected",
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : _thumbnailImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _thumbnailImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No media selected",
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildMediaButton(
    String text,
    VoidCallback onTap,
    IconData icon,
    bool isDark,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 20,
        color: isDark ? Colors.white : Colors.black,
      ),
      label: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[900] : Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: isDark ? Colors.grey[900] : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Select $label',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[900] : Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          items: items.map((String item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
