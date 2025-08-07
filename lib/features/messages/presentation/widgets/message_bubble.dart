import 'package:flutter/material.dart';
import 'package:vandacoo/core/utils/time_formatter.dart';
import 'package:vandacoo/core/common/entities/message_entity.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isFromMe;
  final Function(String)? onDelete;
  final String senderName;
  final String? senderAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromMe,
    this.onDelete,
    required this.senderName,
    this.senderAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () {
        if (isFromMe && onDelete != null) {
          _showDeleteDialog(context);
        }
      },
      child: Container(
        margin: EdgeInsets.only(
          left: isFromMe ? 64.0 : 16.0,
          right: isFromMe ? 16.0 : 64.0,
          top: 8.0,
          bottom: 8.0,
        ),
        child: Column(
          crossAxisAlignment:
              isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isFromMe) _buildSenderInfo(context, isDarkMode),
            _buildMessageBubble(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderInfo(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 8),
          Text(
            senderName,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: Colors.blue.shade400,
        backgroundImage: (senderAvatar != null && senderAvatar!.isNotEmpty)
            ? NetworkImage(senderAvatar!)
            : null,
        child: (senderAvatar == null || senderAvatar!.isEmpty)
            ? Text(
                senderName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, bool isDarkMode) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isFromMe ? 20 : 4),
          bottomRight: Radius.circular(isFromMe ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        gradient: isFromMe
            ? LinearGradient(
                colors: [
                  Colors.blue.shade500,
                  Colors.blue.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isFromMe
            ? null
            : isDarkMode
                ? Colors.grey[800]
                : Colors.grey[100],
        border: !isFromMe
            ? Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.messageType != MessageType.text)
            _buildMediaContent(context),
          if (message.content.isNotEmpty)
            _buildMessageContent(context, isDarkMode),
          _buildMessageFooter(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        message.content,
        style: TextStyle(
          color: isFromMe
              ? Colors.white
              : isDarkMode
                  ? Colors.grey[100]
                  : Colors.grey[800],
          fontSize: 16,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildMessageFooter(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            _formatTime(message.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: isFromMe
                  ? Colors.white.withOpacity(0.8)
                  : isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isFromMe) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                message.readAt != null
                    ? Icons.done_all_rounded
                    : Icons.done_rounded,
                size: 12,
                color: message.readAt != null
                    ? Colors.white
                    : Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    if (message.mediaUrl == null) return const SizedBox();

    switch (message.messageType) {
      case MessageType.image:
        return GestureDetector(
          onTap: () => _showFullScreenImage(context),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: message.mediaUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: const Center(
                      child: Loader(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case MessageType.video:
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: VideoMessagePlayer(videoUrl: message.mediaUrl!),
        );
      default:
        return const SizedBox();
    }
  }

  String _formatTime(DateTime dateTime) {
    return TimeFormatter.formatTimeAgo(dateTime);
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Message',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete!(message.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              'Image',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: message.mediaUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: Loader(
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VideoMessagePlayer extends StatefulWidget {
  final String videoUrl;

  const VideoMessagePlayer({
    super.key,
    required this.videoUrl,
  });

  @override
  State<VideoMessagePlayer> createState() => _VideoMessagePlayerState();
}

class _VideoMessagePlayerState extends State<VideoMessagePlayer> {
  late VideoPlayerController _videoPlayerController;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    try {
      await _videoPlayerController.initialize();
      _videoPlayerController.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _videoPlayerController.value.isPlaying;
          });
        }
      });
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      // Error initializing video
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoPlayerController.value.isPlaying) {
        _videoPlayerController.pause();
      } else {
        _videoPlayerController.play();
      }
    });
  }

  void _showFullScreenVideo(BuildContext context) {
    // Pause the current video before opening fullscreen
    if (_videoPlayerController.value.isPlaying) {
      _videoPlayerController.pause();
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPlayer(
          videoUrl: widget.videoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Loader(),
              SizedBox(height: 12),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: _videoPlayerController.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController),
          ),
          // Play/Pause overlay
          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: !_isPlaying ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Fullscreen button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _showFullScreenVideo(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          // Progress indicator
          if (_isPlaying)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                child: VideoProgressIndicator(
                  _videoPlayerController,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.blue,
                    backgroundColor: Colors.grey,
                    bufferedColor: Colors.lightBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const FullScreenVideoPlayer({
    super.key,
    required this.videoUrl,
  });

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _hideControlsAfterDelay();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    try {
      await _videoPlayerController.initialize();
      _videoPlayerController.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _videoPlayerController.value.isPlaying;
          });
        }
      });
      setState(() {
        _isInitialized = true;
      });
      // Auto-play when entering fullscreen
      _videoPlayerController.play();
    } catch (e) {
      // Error initializing fullscreen video
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoPlayerController.value.isPlaying) {
        _videoPlayerController.pause();
      } else {
        _videoPlayerController.play();
      }
    });
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _hideControlsAfterDelay();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _onScreenTap() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player
          Center(
            child: _isInitialized
                ? GestureDetector(
                    onTap: _onScreenTap,
                    child: AspectRatio(
                      aspectRatio: _videoPlayerController.value.aspectRatio,
                      child: VideoPlayer(_videoPlayerController),
                    ),
                  )
                : const Loader(
                    color: Colors.white,
                  ),
          ),
          // Top controls (back button)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
            ),
          ),
          // Bottom controls
          if (_isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar
                      VideoProgressIndicator(
                        _videoPlayerController,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          backgroundColor: Colors.grey,
                          bufferedColor: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Controls row
                      Row(
                        children: [
                          // Play/Pause button
                          IconButton(
                            onPressed: _togglePlayPause,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Time display
                          Text(
                            '${_formatDuration(_videoPlayerController.value.position)} / ${_formatDuration(_videoPlayerController.value.duration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          // Volume button (placeholder)
                          IconButton(
                            onPressed: () {
                              // Toggle mute/unmute if needed
                            },
                            icon: const Icon(
                              Icons.volume_up,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Center play button overlay (when paused)
          if (_isInitialized && !_isPlaying)
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }
}
