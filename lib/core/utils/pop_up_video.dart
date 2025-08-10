import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class PopUpVideo {
  static void show(BuildContext context, String videoUrl,
      {VoidCallback? onComplete}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onComplete?.call();
                    },
                  ),
                ),
                Expanded(
                  child: VideoPlayerWidget(
                    videoUrl: videoUrl,
                    onComplete: onComplete,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onComplete;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.onComplete,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;

    try {
      // Create video controller
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      // Initialize the controller first
      await _videoPlayerController!.initialize();

      if (!mounted) {
        _disposeControllers();
        return;
      }

      // Add listener after initialization
      _videoPlayerController!.addListener(_videoListener);

      // Create Chewie controller
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        autoPlay: true,
        looping: false,
        allowFullScreen: false,
        allowMuting: true,
        showControls: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white,
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading video',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });

        // Don't manually start playback - let Chewie handle it
        // This prevents double audio issues
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading video: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      _disposeControllers();
    }
  }

  void _videoListener() {
    if (!mounted) return;

    final controller = _videoPlayerController;
    if (controller == null) return;

    // Debug information
    // print('Video state: initialized=${controller.value.isInitialized}, '
    //     'playing=${controller.value.isPlaying}, '
    //     'position=${controller.value.position}, '
    //     'duration=${controller.value.duration}, '
    //     'hasError=${controller.value.hasError}');

    // Check for errors
    if (controller.value.hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = controller.value.errorDescription ?? 'Unknown error';
      });
      return;
    }

    // Check if video has completed (only once)
    if (!_hasCompleted &&
        controller.value.isInitialized &&
        controller.value.position >= controller.value.duration &&
        controller.value.duration > Duration.zero) {
      // Video has completed, call onComplete callback only once
      _hasCompleted = true;
      // print('Video completed, calling onComplete callback');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    // print('Disposing video player widget');
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    // print('Disposing controllers');
    _chewieController?.dispose();
    _chewieController = null;
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _hasCompleted = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitialized = false;
                    _hasError = false;
                    _errorMessage = '';
                  });
                  _initializePlayer();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _videoPlayerController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Try to use Chewie first, fallback to basic VideoPlayer if needed
    if (_chewieController != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Chewie(controller: _chewieController!),
        ),
      );
    } else {
      // Fallback to basic VideoPlayer
      return Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          ),
        ),
      );
    }
  }
}
