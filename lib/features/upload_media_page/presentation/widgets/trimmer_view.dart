import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import '../services/export_service.dart';

class TrimmerView extends StatefulWidget {
  final File videoFile;
  final Duration maxDuration;

  const TrimmerView({
    super.key,
    required this.videoFile,
    required this.maxDuration,
  });

  @override
  TrimmerViewState createState() => TrimmerViewState();
}

class TrimmerViewState extends State<TrimmerView> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  late final VideoEditorController _controller;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoEditorController.file(
      widget.videoFile,
      minDuration: const Duration(seconds: 1),
      maxDuration: widget.maxDuration,
    );
    _controller.initialize().then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _exportVideo() async {
    if (_isExporting.value) return;

    _exportingProgress.value = 0;
    _isExporting.value = true;

    try {
      await ExportService.trimVideo(
        controller: _controller,
        onProgress: (progress) {
          _exportingProgress.value = progress.clamp(0.0, 1.0);
        },
        onError: (e, s) {
          _showErrorSnackBar('Export failed: ${e.toString()}');
          _isExporting.value = false;
        },
        onCompleted: (file) {
          _handleExportCompletion(file);
        },
      );
    } catch (e) {
      _showErrorSnackBar('Failed to export video: ${e.toString()}');
      _isExporting.value = false;
    }
  }

  void _handleExportCompletion(File file) {
    _isExporting.value = false;
    if (!mounted) return;

    if (file.existsSync()) {
      final fileSize = file.lengthSync();
      if (fileSize > 0) {
        Navigator.of(context).pop(file);
      } else {
        _showErrorSnackBar('Export failed: Output file is empty');
      }
    } else {
      _showErrorSnackBar('Failed to save video: output file not found');
    }
  }

  void _toggleCropView() {
    setState(() {
      _isCropping = !_isCropping;
    });
  }

  void _applyCrop() {
    // Apply the current crop
    _controller.applyCacheCrop();
    _toggleCropView();
    setState(() {});
  }

  Widget _buildCropView() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    return Column(
      children: [
        Expanded(
          child: CropGridViewer.edit(
            controller: _controller,
            margin: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 20,
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxHeight: isSmallScreen ? 140 : 200,
            minHeight: 120,
          ),
          margin: EdgeInsets.only(top: isSmallScreen ? 5 : 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: IconButton(
                        onPressed: () =>
                            _controller.rotate90Degrees(RotateDirection.left),
                        icon:
                            const Icon(Icons.rotate_left, color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        onPressed: () =>
                            _controller.rotate90Degrees(RotateDirection.right),
                        icon:
                            const Icon(Icons.rotate_right, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 5 : 10),
              Flexible(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            // Reset crop on cancel
                            _controller.updateCrop(
                              const Offset(0.0, 0.0),
                              const Offset(1.0, 1.0),
                            );
                            _toggleCropView();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyCrop,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _isCropping ? 'Crop Video' : 'Trim Video',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isExporting.value && !_isCropping)
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 8,
                vertical: 8,
              ),
              child: ElevatedButton(
                onPressed: _exportVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Save'),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _controller.initialized
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Column(
                        children: [
                          // Video preview section
                          Expanded(
                            flex: _isCropping ? 1 : 2,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(color: Colors.white24),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin:
                                      EdgeInsets.all(isSmallScreen ? 8 : 16),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: _isCropping
                                        ? _buildCropView()
                                        : CropGridViewer.preview(
                                            controller: _controller),
                                  ),
                                ),
                                if (!_isCropping)
                                  AnimatedBuilder(
                                    animation: _controller.video,
                                    builder: (_, __) => AnimatedOpacity(
                                      opacity: _controller.isPlaying ? 0 : 1,
                                      duration: kThemeAnimationDuration,
                                      child: GestureDetector(
                                        onTap: _controller.video.play,
                                        child: Container(
                                          width: isSmallScreen ? 48 : 64,
                                          height: isSmallScreen ? 48 : 64,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.5),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.play_arrow,
                                            color: Colors.black,
                                            size: isSmallScreen ? 24 : 32,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Controls section
                          if (!_isCropping)
                            Flexible(
                              flex: 1,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxHeight: isSmallScreen ? 180 : 220,
                                  minHeight: 140,
                                ),
                                margin: EdgeInsets.only(
                                  top: isSmallScreen ? 5 : 10,
                                  bottom: isSmallScreen ? 5 : 10,
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Duration display
                                      ValueListenableBuilder(
                                        valueListenable: _controller.video,
                                        builder: (_, state, __) => Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isSmallScreen ? 16 : 24,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _formatDuration(Duration(
                                                      milliseconds: _controller
                                                          .minTrim
                                                          .toInt())),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        isSmallScreen ? 12 : 14,
                                                  ),
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  _formatDuration(_controller
                                                      .video.value.duration),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        isSmallScreen ? 12 : 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Trim slider
                                      Container(
                                        width: constraints.maxWidth,
                                        margin: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 5 : 10,
                                          horizontal: isSmallScreen ? 8 : 16,
                                        ),
                                        child: TrimSlider(
                                          controller: _controller,
                                          height: isSmallScreen ? 50 : 60,
                                          horizontalMargin:
                                              isSmallScreen ? 10 : 15,
                                          child: TrimTimeline(
                                            controller: _controller,
                                            padding: EdgeInsets.only(
                                              top: isSmallScreen ? 5 : 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Action buttons
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 16 : 24,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Flexible(
                                              child: _buildActionButton(
                                                icon: Icons.rotate_left,
                                                label: 'Reset',
                                                onPressed: () =>
                                                    _controller.rotate90Degrees(
                                                        RotateDirection.left),
                                                isSmallScreen: isSmallScreen,
                                              ),
                                            ),
                                            SizedBox(
                                                width: isSmallScreen ? 8 : 16),
                                            Flexible(
                                              child: _buildActionButton(
                                                icon: Icons.crop,
                                                label: 'Crop',
                                                onPressed: _toggleCropView,
                                                isSmallScreen: isSmallScreen,
                                              ),
                                            ),
                                            SizedBox(
                                                width: isSmallScreen ? 8 : 16),
                                            Flexible(
                                              child: _buildActionButton(
                                                icon: Icons.rotate_right,
                                                label: 'Rotate',
                                                onPressed: () =>
                                                    _controller.rotate90Degrees(
                                                        RotateDirection.right),
                                                isSmallScreen: isSmallScreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Export overlay
                      ValueListenableBuilder(
                        valueListenable: _isExporting,
                        builder: (_, bool export, Widget? child) =>
                            AnimatedSwitcher(
                          duration: kThemeAnimationDuration,
                          child: export
                              ? Container(
                                  color: Colors.black.withOpacity(0.7),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                        SizedBox(
                                            height: isSmallScreen ? 12 : 16),
                                        ValueListenableBuilder(
                                          valueListenable: _exportingProgress,
                                          builder: (_, double value, __) =>
                                              Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  isSmallScreen ? 16 : 24,
                                            ),
                                            child: Text(
                                              'Exporting video ${(value * 100).ceil()}%',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize:
                                                    isSmallScreen ? 14 : 16,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  );
                },
              )
            : const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isSmallScreen = false,
  }) {
    final buttonSize = isSmallScreen ? 36.0 : 48.0;
    final fontSize = isSmallScreen ? 10.0 : 12.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: buttonSize,
          height: buttonSize,
          margin: EdgeInsets.only(bottom: isSmallScreen ? 4 : 8),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
              size: isSmallScreen ? 18 : 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
