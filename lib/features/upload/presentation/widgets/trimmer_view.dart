import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import 'package:path_provider/path_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = VideoEditorController.file(
      widget.videoFile,
      minDuration: const Duration(seconds: 1),
      maxDuration: widget.maxDuration,
    );
    _controller.initialize().then((_) => setState(() {}));
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
      // Get the input video path and ensure it exists
      final String inputPath = widget.videoFile.path;
      if (!File(inputPath).existsSync()) {
        throw Exception('Input video file not found');
      }

      // Create output path in temporary directory
      final tempDir = await getTemporaryDirectory();
      final String outputPath =
          '${tempDir.path}/trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final config = await VideoFFmpegVideoEditorConfig(
        _controller,
        commandBuilder: (config, videoPath, outputPath) {
          final List<String> filters = config.getExportFilters();
          // Properly quote paths with single quotes
          return "-y -i '$videoPath' ${config.filtersCmd(filters)} -c:v h264_videotoolbox -b:v 2M -c:a aac '$outputPath'";
        },
      ).getExecuteConfig();

      print('FFmpeg command: ${config.command}');

      await ExportService.runFFmpegCommand(
        config.command,
        onProgress: (stats) {
          if (_isExporting.value) {
            _exportingProgress.value = stats.getTime() /
                _controller.video.value.duration.inMilliseconds;
          }
        },
        onError: (e, s) {
          print('Export error: $e');
          _showErrorSnackBar('Export failed: ${e.toString()}');
          _isExporting.value = false;
        },
        onCompleted: (file) {
          _isExporting.value = false;
          if (!mounted) return;

          if (file.existsSync()) {
            print('Export completed successfully: ${file.path}');
            Navigator.of(context).pop(file);
          } else {
            print('Export failed: output file does not exist');
            _showErrorSnackBar('Failed to save video: output file not found');
          }
        },
      );
    } catch (e) {
      print('Export error: $e');
      _showErrorSnackBar('Failed to export video: ${e.toString()}');
      _isExporting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trim Video'),
        actions: [
          if (!_isExporting.value)
            IconButton(
              onPressed: _exportVideo,
              icon: const Icon(Icons.check),
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
                          CropGridViewer.preview(controller: _controller),
                          AnimatedBuilder(
                            animation: _controller.video,
                            builder: (_, __) => AnimatedOpacity(
                              opacity: _controller.isPlaying ? 0 : 1,
                              duration: kThemeAnimationDuration,
                              child: GestureDetector(
                                onTap: _controller.video.play,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 200,
                      margin: const EdgeInsets.only(top: 10),
                      child: Column(
                        children: [
                          Container(
                            height: 100,
                            margin: const EdgeInsets.symmetric(horizontal: 15),
                            child: TrimSlider(
                              controller: _controller,
                              height: 60,
                              horizontalMargin: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder(
                  valueListenable: _isExporting,
                  builder: (_, bool export, Widget? child) => AnimatedSize(
                    duration: kThemeAnimationDuration,
                    child: export ? child : null,
                  ),
                  child: AlertDialog(
                    title: ValueListenableBuilder(
                      valueListenable: _exportingProgress,
                      builder: (_, double value, __) => Text(
                        "Exporting video ${(value * 100).ceil()}%",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
