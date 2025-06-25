import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'dart:io';
import 'dart:async';
import 'package:vandacoo/core/constants/app_consts.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/common/widgets/dynamic_image_widget.dart';
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
  File? _thumbnailFile;
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
          (_selectedOption == 'Post' || _selectedOption == 'Story') &&
          _captionController.text.isNotEmpty &&
          _categoryController.text.isNotEmpty &&
          _regionController.text.isNotEmpty &&
          (!_isVideo || (_isVideo && _thumbnailFile != null));
    });
  }

  Future<void> _generateThumbnail(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 1080,
        maxWidth: 1080,
        quality: 85,
      );

      if (thumbnailPath != null) {
        setState(() {
          _thumbnailFile = File(thumbnailPath);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating thumbnail: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _validateAspectRatio(String imagePath) async {
    final File imageFile = File(imagePath);
    final image = await decodeImageFromList(await imageFile.readAsBytes());
    final double aspectRatio = image.width / image.height;

    // Updated Instagram-compatible aspect ratio range:
    // Landscape 16:9 = 1.78 (actually supporting up to 2.1 for more flexibility)
    // Portrait 4:5 = 0.8 (supporting down to 0.6 for more flexibility)
    return aspectRatio >= 0.6 && aspectRatio <= 2.1;
  }

  Future<void> _pickMedia(ImageSource source, {required bool isVideo}) async {
    try {
      final ImagePicker picker = ImagePicker();
      if (!isVideo) {
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          maxHeight: 2048,
          maxWidth: 2048,
          imageQuality: 95,
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
          maxWidth: 2048,
          maxHeight: 2048,
          compressQuality: 95,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Adjust Image',
              toolbarColor: AppColors.primaryColor,
              toolbarWidgetColor: Colors.white,
              statusBarColor: AppColors.primaryColor,
              activeControlsWidgetColor: AppColors.primaryColor,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              hideBottomControls: false,
              cropFrameColor: AppColors.primaryColor,
              cropGridColor: Colors.white,
              cropFrameStrokeWidth: 2,
              cropGridStrokeWidth: 1,
              showCropGrid: true,
              aspectRatioPresets: [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio16x9,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.square,
              ],
            ),
            IOSUiSettings(
              title: 'Adjust Image',
              doneButtonTitle: 'Done',
              cancelButtonTitle: 'Cancel',
              aspectRatioLockEnabled: false,
              resetAspectRatioEnabled: true,
              aspectRatioPickerButtonHidden: false,
              cropStyle: CropStyle.rectangle,
              aspectRatioPresets: [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio16x9,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.square,
              ],
            ),
          ],
        );

        if (croppedFile == null) return;

        // Validate aspect ratio
        final bool isValidRatio = await _validateAspectRatio(croppedFile.path);
        if (!isValidRatio) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'This image has an unusual shape. Try cropping it to a standard format'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

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

            // Generate thumbnail automatically
            await _generateThumbnail(trimmedVideo.path);

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

  Future<void> _pickThumbnail() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
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

      setState(() {
        _thumbnailFile = File(pickedFile.path);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking thumbnail: ${e.toString()}'),
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
            thumbnailFile: _isVideo ? _thumbnailFile : null,
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

  Future<void> _showMediaTypeSelector() async {
    if (_selectedOption != 'Post' && _selectedOption != 'Story') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Post or Story first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading:
                      const Icon(Icons.image, color: AppColors.primaryColor),
                  title: const Text('Image'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(ImageSource.gallery, isVideo: false);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.videocam, color: AppColors.primaryColor),
                  title: const Text('Video'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(ImageSource.gallery, isVideo: true);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final isTablet = screenSize.width > 600;

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
            _selectedOption == "Post" ? "Create Post" : "Create Story",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.white,
              fontSize: isSmallScreen ? 16 : 18,
            ),
          ),
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Option selection header
                      Container(
                        color: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 40 : 20,
                          vertical: isSmallScreen ? 10 : 15,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _buildOptionButton(
                                  "Story", "Story", isDark, isSmallScreen),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 20),
                            Expanded(
                              child: _buildOptionButton(
                                  "Post", "Post", isDark, isSmallScreen),
                            ),
                          ],
                        ),
                      ),
                      // Main content
                      Padding(
                        padding: EdgeInsets.all(
                            isTablet ? 32.0 : (isSmallScreen ? 16.0 : 20.0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMediaSection(isDark, isSmallScreen, isTablet),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            _buildInputField(
                              "Caption",
                              _captionController,
                              maxLines: 3,
                              isDark: isDark,
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 24),
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
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 24),
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
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 24 : 32),
                            ElevatedButton(
                              onPressed: _isFormValid ? _uploadPost : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFormValid
                                    ? AppColors.primaryColor
                                    : Colors.grey,
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: BlocBuilder<UploadBloc, UploadState>(
                                builder: (context, state) {
                                  if (state is UploadPostLoading) {
                                    return SizedBox(
                                      height: isSmallScreen ? 16 : 20,
                                      width: isSmallScreen ? 16 : 20,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  }
                                  return Text(
                                    _selectedOption == "Post"
                                        ? "Upload Post"
                                        : "Upload Story",
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection(bool isDark, bool isSmallScreen, bool isTablet) {
    final mediaHeight = isSmallScreen ? 200.0 : (isTablet ? 300.0 : 250.0);
    final thumbnailHeight = isSmallScreen ? 120.0 : 150.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _showMediaTypeSelector,
          icon: Icon(
            Icons.add_photo_alternate,
            size: isSmallScreen ? 18 : 20,
            color: Colors.white,
          ),
          label: Text(
            "Select Media",
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 10 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (_isVideo && _mediaFile != null) ...[
          SizedBox(height: isSmallScreen ? 12 : 16),
          ElevatedButton.icon(
            onPressed: _pickThumbnail,
            icon: Icon(
              Icons.image,
              size: isSmallScreen ? 18 : 20,
              color: Colors.white,
            ),
            label: Text(
              "Select Thumbnail",
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 10 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
        SizedBox(height: isSmallScreen ? 12 : 16),
        if (_isVideo && _mediaFile != null) ...[
          Container(
            constraints: BoxConstraints(
              maxHeight: isTablet ? 400 : mediaHeight,
              minHeight: isSmallScreen ? 180 : 200,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            child: _videoController != null &&
                    _videoController!.value.isInitialized
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
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
                              size: isSmallScreen ? 40 : 50,
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
                    ),
                  )
                : AspectRatio(
                    aspectRatio: 16 / 9, // Default aspect ratio while loading
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
          ),
          if (_thumbnailFile != null) ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            Container(
              height: thumbnailHeight,
              constraints: BoxConstraints(
                maxHeight: isTablet ? 200 : thumbnailHeight,
                minHeight: isSmallScreen ? 100 : 120,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Colors.grey[900] : Colors.grey[200],
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.file(
                      _thumbnailFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Thumbnail',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 10 : 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ] else ...[
          _mediaFile != null
              ? DynamicImageWidget(
                  imageFile: _mediaFile!,
                  maxHeight: 600,
                  minHeight: 200,
                  maintainAspectRatio: true,
                  forceFullWidth: true,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? Colors.grey[900] : Colors.grey[200],
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                )
              : Container(
                  height: mediaHeight,
                  constraints: BoxConstraints(
                    maxHeight: isTablet ? 300 : mediaHeight,
                    minHeight: isSmallScreen ? 180 : 200,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? Colors.grey[900] : Colors.grey[200],
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: isSmallScreen ? 36 : 48,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        Text(
                          "No media selected",
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
        SizedBox(height: isSmallScreen ? 12 : 16),
        Center(
          child: Text(
            'Choose Image or Video',
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 8),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 40 : (isSmallScreen ? 8 : 16),
          ),
          child: Text(
            'Preview shows exactly how your image will appear when posted. Images can be uploaded in their original dimensions. You can choose to crop/adjust or keep the original aspect ratio.',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    required bool isDark,
    bool isSmallScreen = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: isSmallScreen ? 14 : 16,
          ),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: isSmallScreen ? 14 : 16,
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
            contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
    bool isSmallScreen = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: isDark ? Colors.grey[900] : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: isSmallScreen ? 14 : 16,
          ),
          decoration: InputDecoration(
            hintText: 'Select $label',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: isSmallScreen ? 14 : 16,
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
            contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          ),
          items: items.map((String item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildOptionButton(
      String text, String option, bool isDark, bool isSmallScreen) {
    bool isSelected = _selectedOption == option;
    return TextButton(
      onPressed: () => _selectOption(option),
      style: TextButton.styleFrom(
        backgroundColor: isSelected
            ? (isDark ? Colors.white24 : Colors.white)
            : Colors.transparent,
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 8 : 12,
        ),
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
          fontSize: isSmallScreen ? 14 : 16,
        ),
      ),
    );
  }
}
