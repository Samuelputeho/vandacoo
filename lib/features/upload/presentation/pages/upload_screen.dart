import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:video_player/video_player.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'dart:io';
import 'package:vandacoo/core/constants/app_consts.dart';
import '../../../../core/constants/colors.dart';
import '../bloc/upload/upload_bloc.dart';
import '../widgets/trimmer_view.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _mediaFile;
  bool _isVideo = false;
  VideoPlayerController? _videoController;
  String? _selectedOption;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();

  String? _selectedCategory;
  String? _selectedRegion;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _captionController.addListener(_validateForm);
    _categoryController.addListener(_validateForm);
    _regionController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    _categoryController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _mediaFile != null &&
          _selectedOption != null &&
          _captionController.text.isNotEmpty &&
          _categoryController.text.isNotEmpty &&
          _regionController.text.isNotEmpty;
    });
  }

  Future<void> _pickMedia(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Show dialog to choose media type
      final String? mediaType = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Media Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Image'),
                  onTap: () => Navigator.pop(context, 'image'),
                ),
                ListTile(
                  leading: const Icon(Icons.video_library),
                  title: const Text('Video'),
                  onTap: () => Navigator.pop(context, 'video'),
                ),
              ],
            ),
          );
        },
      );

      if (mediaType == null) return;

      if (mediaType == 'image') {
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          maxHeight: 1080,
          maxWidth: 1080,
          imageQuality: 85,
        );

        if (pickedFile == null) return;

        // Validate image file type
        final String extension = pickedFile.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'heic'].contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Please select a valid image file (JPG, PNG, HEIC)'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Check image file size (25MB)
        final int fileSize = await File(pickedFile.path).length();
        if (fileSize > 25 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 25MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Crop image
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Adjust Image',
              toolbarColor: AppColors.primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Adjust Image',
              doneButtonTitle: 'Done',
              cancelButtonTitle: 'Cancel',
            ),
          ],
        );

        if (croppedFile == null) return;
        if (!mounted) return;

        setState(() {
          _mediaFile = File(croppedFile.path);
          _isVideo = false;
          _validateForm();
        });
      } else {
        final XFile? pickedFile = await picker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 30),
        );

        if (pickedFile == null) return;

        // Validate video file type
        final String extension = pickedFile.path.split('.').last.toLowerCase();
        if (!['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Please select a valid video file (MP4, MOV, AVI, MKV)'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Check video duration
        final VideoPlayerController controller = VideoPlayerController.file(
          File(pickedFile.path),
        );
        await controller.initialize();
        final duration = controller.value.duration;
        await controller.dispose();

        if (duration > const Duration(minutes: 30)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video must be shorter than 30 minutes'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Navigate to video trimmer screen
        if (mounted) {
          final File? trimmedVideo = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TrimmerView(
                videoFile: File(pickedFile.path),
                maxDuration: const Duration(minutes: 30),
              ),
            ),
          );

          if (trimmedVideo != null) {
            setState(() {
              _mediaFile = trimmedVideo;
              _isVideo = true;
              _validateForm();
            });

            // Initialize video controller for preview
            _videoController = VideoPlayerController.file(_mediaFile!)
              ..initialize().then((_) {
                setState(() {});
              });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking media: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _uploadPost() {
    if (_isFormValid) {
      final posterId =
          (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
      context.read<UploadBloc>().add(UploadPostEvent(
            userId: posterId,
            caption: _captionController.text,
            mediaFile: _mediaFile,
            category: _categoryController.text,
            region: _regionController.text,
            postType: _selectedOption!,
          ));
    }
  }

  // Function to handle option selection
  void _selectOption(String option) {
    setState(() {
      _selectedOption = option;
      _validateForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<UploadBloc, UploadState>(
      listener: (context, state) {
        if (state is UploadPostSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          // Clear the form after successful upload
          setState(() {
            _mediaFile = null;
            _captionController.clear();
            _categoryController.clear();
            _regionController.clear();
            _selectedCategory = null;
            _selectedRegion = null;
            _selectedOption = null;
            _isFormValid = false;
          });
        } else if (state is UploadPostFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                          _validateForm();
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
                          _validateForm();
                        });
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isFormValid ? _uploadPost : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isFormValid ? AppColors.primaryColor : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: BlocBuilder<UploadBloc, UploadState>(
                        builder: (context, state) {
                          if (state is UploadPostLoading) {
                            return const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            );
                          }
                          return const Text(
                            "Upload Post",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
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

  Widget _buildMediaSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _pickMedia(ImageSource.gallery),
          icon: const Icon(
            Icons.add_photo_alternate,
            size: 20,
            color: Colors.white,
          ),
          label: const Text(
            "Select Media",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
          child: _mediaFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _isVideo && _videoController != null
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_videoController!),
                              IconButton(
                                icon: Icon(
                                  _videoController!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  size: 50,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _videoController!.value.isPlaying
                                        ? _videoController!.pause()
                                        : _videoController!.play();
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      : Image.file(
                          _mediaFile!,
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
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
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
}
