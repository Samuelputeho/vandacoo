import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'dart:async';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/app_consts.dart';
import '../../../../core/common/widgets/dynamic_image_widget.dart';
import '../bloc/feeds_bloc/feeds_bloc.dart';
import '../widgets/feeds_trimmerview.dart';

class UploadFeedsPage extends StatefulWidget {
  final int? durationDays;
  const UploadFeedsPage({
    super.key,
    this.durationDays,
  });

  @override
  State<UploadFeedsPage> createState() => _UploadFeedsPageState();
}

class _UploadFeedsPageState extends State<UploadFeedsPage> {
  File? _mediaFile;
  File? _thumbnailFile;
  bool _isVideo = false;
  VideoPlayerController? _videoController;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  late final int _durationDays;

  String? _selectedCategory;
  String? _selectedRegion;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _durationDays = widget.durationDays ?? 1; // Default to 1 if not provided
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

    // Allow all reasonable aspect ratios - much more flexible range
    // Supporting ultra-wide panoramic to very tall portrait images
    return aspectRatio >= 0.1 && aspectRatio <= 10.0;
  }

  Future<void> _pickMedia(ImageSource source, {required bool isVideo}) async {
    try {
      final ImagePicker picker = ImagePicker();
      if (!isVideo) {
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          // Remove max dimensions to preserve original image size
          imageQuality: 95,
        );

        if (pickedFile == null) return;

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

        // Check image file size (50MB - increased limit for high-res images)
        final int fileSize = await File(pickedFile.path).length();
        if (fileSize > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 50MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Validate aspect ratio with more flexible range
        final bool isValidRatio = await _validateAspectRatio(pickedFile.path);
        if (!isValidRatio) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'This image has an extreme aspect ratio that may not display well'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          // Don't return - allow the upload to continue
        }

        // Show dialog to ask user if they want to crop or keep original
        if (mounted) {
          final bool? shouldCrop = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Image Options'),
                content: const Text(
                    'Would you like to crop/adjust your image or keep it in its original dimensions?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Keep Original'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Crop/Adjust'),
                  ),
                ],
              );
            },
          );

          if (shouldCrop == null) return; // User cancelled

          if (shouldCrop) {
            // User chose to crop - use the existing cropper
            final CroppedFile? croppedFile = await ImageCropper().cropImage(
              sourcePath: pickedFile.path,
              compressQuality: 95,
              uiSettings: [
                AndroidUiSettings(
                  toolbarTitle: 'Adjust Image',
                  toolbarColor: AppColors.primaryColor,
                  toolbarWidgetColor: Colors.white,
                  initAspectRatio: CropAspectRatioPreset.original,
                  lockAspectRatio: false,
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

            setState(() {
              _mediaFile = File(croppedFile.path);
              _isVideo = false;
              _validateForm();
            });
          } else {
            // User chose to keep original - use the image as-is
            setState(() {
              _mediaFile = File(pickedFile.path);
              _isVideo = false;
              _validateForm();
            });
          }
        }
      } else {
        final XFile? pickedFile = await picker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 30),
        );

        if (pickedFile == null) return;

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

        if (mounted) {
          final File? trimmedVideo = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FeedsTrimmerView(
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

            await _generateThumbnail(trimmedVideo.path);

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
      context.read<FeedsBloc>().add(UploadFeedsPostEvent(
            userId: posterId,
            postType: 'Post',
            caption: _captionController.text,
            region: _regionController.text,
            category: _categoryController.text,
            mediaFile: _mediaFile,
            thumbnailFile: _isVideo ? _thumbnailFile : null,
            durationDays: _durationDays,
          ));
    }
  }

  Future<void> _showMediaTypeSelector() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                leading: const Icon(Icons.image, color: AppColors.primaryColor),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    //print duration
    print('Duration: $_durationDays');

    return BlocListener<FeedsBloc, FeedsState>(
      listener: (context, state) {
        if (state is FeedsPostSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.pop(context, true);
        } else if (state is FeedsPostFailure) {
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
          title: const Text(
            "Upload Ad",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      child: BlocBuilder<FeedsBloc, FeedsState>(
                        builder: (context, state) {
                          if (state is FeedsPostLoading) {
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
          onPressed: _showMediaTypeSelector,
          icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
          label: const Text(
            "Select Media",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (_isVideo && _mediaFile != null) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickThumbnail,
            icon: const Icon(Icons.image, color: Colors.white),
            label: const Text(
              "Select Thumbnail",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_mediaFile != null)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            child: _isVideo
                ? _videoController?.value.isInitialized ?? false
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
                        ),
                      )
                    : AspectRatio(
                        aspectRatio:
                            16 / 9, // Default aspect ratio while loading
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                      )
                : DynamicImageWidget(
                    imageFile: _mediaFile!,
                    maxHeight: 500,
                    minHeight: 200,
                    borderRadius: BorderRadius.circular(12),
                    maintainAspectRatio: true,
                    forceFullWidth: false,
                    fit: BoxFit.contain,
                  ),
          ),
        if (_isVideo && _thumbnailFile != null) ...[
          const SizedBox(height: 16),
          Container(
            height: 150,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Thumbnail',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Choose Image or Video',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Images can be uploaded in their original dimensions. You can choose to crop/adjust or keep the original aspect ratio.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
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
}
