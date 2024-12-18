import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'dart:io';
import 'package:vandacoo/features/all_posts/presentation/bloc/post_bloc.dart'; // Import your PostBloc

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _thumbnailImage;
  File? _selectedVideo;
  String? _selectedOption; // Track selected option (Story or Post)
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();

  // Add these lists
  final List<String> _categories = [
    'Education',
    'Entertainment',
    'Food and Travel',
    'Health',
    'Kids',
    'Finance',
    'Sports',
    'Technology',
  ];

  final List<String> _regions = [
    'Erongo',
    'Hardap',
    'Karas',
    'Kavango East',
    'Kavango West',
    'Khomas',
    'Kunene',
    'Ohangwena',
    'Omaheke',
    'Omusati',
    'Oshana',
    'Oshikoto',
    'Otjozondjupa',
    'Zambezi',
  ];

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
            posterId: posterId, // Replace with actual poster ID
            caption: _captionController.text,
            image: _thumbnailImage,
            category: _categoryController.text,
            region: _regionController.text,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: _pickImage, // Open the gallery when tapped
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.orange,
                    ),
                    child: const Text("Select Image"),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: _pickVideo, // Open the gallery when tapped
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.orange,
                    ),
                    child: const Text("Select Video"),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.grey,
                  ),
                  child: _selectedVideo != null
                      ? Center(
                          child: Text(
                            "Video Selected: ${_selectedVideo!.path.split('/').last}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : _thumbnailImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.file(
                                _thumbnailImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Center(
                              child: Text("Video Preview"),
                            ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Caption",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _captionController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter caption',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Category",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select category',
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                    _categoryController.text = newValue ?? '';
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "Region",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select region',
                ),
                items: _regions.map((String region) {
                  return DropdownMenuItem(
                    value: region,
                    child: Text(region),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRegion = newValue;
                    _regionController.text = newValue ?? '';
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "Thumbnail",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: _pickImage, // Open the gallery when tapped
                child: Container(
                  height: 150,
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.grey[300],
                  ),
                  child: _thumbnailImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.file(
                            _thumbnailImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Text("Tap to select thumbnail"),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => _selectOption("Story"),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedOption == "Story"
                            ? Colors.orange
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text("Story"),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _selectOption("Post"),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedOption == "Post"
                            ? Colors.orange
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text("Post"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _uploadPost, // Call upload function
                  child: const Text("Upload"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Background color
                  ),
                ),
              ),
              // Listen for state changes and show messages
              BlocListener<PostBloc, PostState>(
                listener: (context, state) {
                  if (state is PostLoading) {
                    // Show loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Uploading...')),
                    );
                  } else if (state is PostSuccess) {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Post uploaded successfully!')),
                    );
                  } else if (state is PostFailure) {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Upload failed: ${state.error}')),
                    );
                  }
                },
                child: Container(), // Placeholder for BlocListener
              ),
            ],
          ),
        ),
      ),
    );
  }
}
