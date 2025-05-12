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
    return Column(
      children: [
        Expanded(
          child: CropGridViewer.edit(
            controller: _controller,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
        Container(
          height: 200,
          margin: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: IconButton(
                      onPressed: () =>
                          _controller.rotate90Degrees(RotateDirection.left),
                      icon: const Icon(Icons.rotate_left, color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () =>
                          _controller.rotate90Degrees(RotateDirection.right),
                      icon: const Icon(Icons.rotate_right, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
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
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
      body: _controller.initialized
          ? Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.all(16),
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
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.black,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!_isCropping)
                      Container(
                        height: 200,
                        margin: const EdgeInsets.only(top: 10),
                        child: Column(
                          children: [
                            ValueListenableBuilder(
                              valueListenable: _controller.video,
                              builder: (_, state, __) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(Duration(
                                          milliseconds:
                                              _controller.minTrim.toInt())),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      _formatDuration(
                                          _controller.video.value.duration),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              child: TrimSlider(
                                controller: _controller,
                                height: 60,
                                horizontalMargin: 15,
                                child: TrimTimeline(
                                  controller: _controller,
                                  padding: const EdgeInsets.only(top: 10),
                                ),
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.rotate_left,
                                    label: 'Reset',
                                    onPressed: () => _controller
                                        .rotate90Degrees(RotateDirection.left),
                                  ),
                                  _buildActionButton(
                                    icon: Icons.crop,
                                    label: 'Crop',
                                    onPressed: _toggleCropView,
                                  ),
                                  _buildActionButton(
                                    icon: Icons.rotate_right,
                                    label: 'Rotate',
                                    onPressed: () => _controller
                                        .rotate90Degrees(RotateDirection.right),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                ValueListenableBuilder(
                  valueListenable: _isExporting,
                  builder: (_, bool export, Widget? child) => AnimatedSwitcher(
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
                                  const SizedBox(height: 16),
                                  ValueListenableBuilder(
                                    valueListenable: _exportingProgress,
                                    builder: (_, double value, __) => Text(
                                      'Exporting video ${(value * 100).ceil()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
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
            )
          : const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.only(bottom: 8),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
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
