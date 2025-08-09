import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';

class CustomStoryContent extends StatefulWidget {
  final PostEntity story;
  final VoidCallback? onLoadComplete;
  final VoidCallback? onContentReady;
  final VoidCallback? onContentPaused;
  final Function(Duration position, Duration duration)? onProgressUpdate;
  final bool isActive;

  const CustomStoryContent({
    super.key,
    required this.story,
    this.onLoadComplete,
    this.onContentReady,
    this.onContentPaused,
    this.onProgressUpdate,
    this.isActive = false,
  });

  @override
  State<CustomStoryContent> createState() => _CustomStoryContentState();
}

class _CustomStoryContentState extends State<CustomStoryContent> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasError = false;
  bool _hasCalledContentReady = false;
  bool _isVideoActuallyPlaying = false;
  Duration _lastPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeContent();
  }

  @override
  void didUpdateWidget(CustomStoryContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle video playback based on active state
    if (widget.story.videoUrl != null &&
        _videoController != null &&
        _isVideoInitialized) {
      if (widget.isActive && !_videoController!.value.isPlaying) {
        _videoController!.play();
      } else if (!widget.isActive && _videoController!.value.isPlaying) {
        _videoController!.pause();
      }
    }

    // Handle non-video content becoming active
    if (widget.isActive &&
        !oldWidget.isActive &&
        (widget.story.videoUrl == null || widget.story.videoUrl!.isEmpty) &&
        !_hasCalledContentReady) {
      // For images and text that become active, call onContentReady
      _hasCalledContentReady = true;
      widget.onContentReady?.call();
      // Tell controller to use timer-based progress for non-video content
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Use a callback to indicate this is not video content
        widget.onProgressUpdate?.call(Duration.zero, Duration.zero);
      });
    }

    // Reset the flags when widget becomes inactive
    if (!widget.isActive && oldWidget.isActive) {
      _hasCalledContentReady = false;
      _isVideoActuallyPlaying = false;
      _lastPosition = Duration.zero;
    }
  }

  void _videoListener() {
    if (_videoController != null && widget.isActive) {
      final currentPosition = _videoController!.value.position;
      final duration = _videoController!.value.duration;
      final isPlaying = _videoController!.value.isPlaying;
      final hasError = _videoController!.value.hasError;

      // Provide real-time progress updates for videos
      if (duration.inMilliseconds > 0) {
        widget.onProgressUpdate?.call(currentPosition, duration);
      }

      // Check if video is actually progressing (not frozen)
      final isProgressing = currentPosition != _lastPosition;
      final shouldBePlaying = isPlaying && !hasError && _isVideoInitialized;

      if (shouldBePlaying && isProgressing) {
        // Video is actually playing and progressing
        if (!_isVideoActuallyPlaying) {
          _isVideoActuallyPlaying = true;
          if (!_hasCalledContentReady) {
            _hasCalledContentReady = true;
            widget.onContentReady?.call();
          } else {
            // Video resumed after being paused/frozen
            widget.onContentReady?.call();
          }
        }
      } else if (_isVideoActuallyPlaying &&
          (!shouldBePlaying || !isProgressing)) {
        // Video was playing but now is frozen/paused/has error
        _isVideoActuallyPlaying = false;
        widget.onContentPaused?.call();
      }

      _lastPosition = currentPosition;
    }
  }

  void _initializeContent() {
    if (widget.story.videoUrl != null && widget.story.videoUrl!.isNotEmpty) {
      _initializeVideo();
    } else {
      // For images and text, consider them loaded immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onLoadComplete?.call();
        // For non-video content, also call onContentReady if active
        if (widget.isActive && !_hasCalledContentReady) {
          _hasCalledContentReady = true;
          widget.onContentReady?.call();
          // Tell controller to use timer-based progress for non-video content
          widget.onProgressUpdate?.call(Duration.zero, Duration.zero);
        }
      });
    }
  }

  void _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.story.videoUrl!),
      );

      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        // Set video to loop and add listener to detect when it starts playing
        _videoController!.setLooping(true);
        _videoController!.addListener(_videoListener);

        if (widget.isActive) {
          _videoController!.play();
        }

        widget.onLoadComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
        widget.onLoadComplete?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.story.videoUrl != null && widget.story.videoUrl!.isNotEmpty) {
      return _buildVideoContent();
    } else if (widget.story.imageUrl != null &&
        widget.story.imageUrl!.isNotEmpty) {
      return _buildImageContent();
    } else {
      return _buildTextContent();
    }
  }

  Widget _buildVideoContent() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isVideoInitialized) {
      return _buildLoadingWidget();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Center(
          key: ValueKey(widget.story.videoUrl),
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Image.network(
          widget.story.imageUrl!,
          key: ValueKey(widget.story.imageUrl),
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _buildLoadingWidget();
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Center(
          key: ValueKey(widget.story.caption),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              widget.story.caption ?? 'No content',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Failed to load content',
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

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }
}
