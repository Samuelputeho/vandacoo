import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vandacoo/features/explore_page/presentation/widgets/edit_post_widget.dart';
import 'dart:async';

import '../../../../core/constants/colors.dart';

class PostTile extends StatefulWidget {
  final String proPic;
  final String name;
  final String postPic;
  final String description;
  final String id;
  final String userId;
  final String? videoUrl;
  final DateTime createdAt;
  final bool isLiked;
  final bool isBookmarked;
  final int likeCount;
  final int commentCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onBookmark;
  final Function(String) onUpdateCaption;
  final VoidCallback onDelete;
  final bool isCurrentUser;

  const PostTile({
    super.key,
    required this.proPic,
    required this.name,
    required this.postPic,
    required this.description,
    required this.id,
    required this.userId,
    this.videoUrl,
    required this.createdAt,
    required this.isLiked,
    required this.isBookmarked,
    required this.likeCount,
    required this.commentCount,
    required this.onLike,
    required this.onComment,
    required this.onBookmark,
    required this.onUpdateCaption,
    required this.onDelete,
    required this.isCurrentUser,
  });

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _commentController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  Timer? _timeUpdateTimer;
  final FocusNode _focusNode = FocusNode();

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 2));
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 0) {
      return 'Just now';
    }

    final seconds = difference.inSeconds;
    final minutes = difference.inMinutes;
    final hours = difference.inHours;
    final days = difference.inDays;

    if (seconds < 5) {
      return 'Just now';
    } else if (seconds < 60) {
      return '$seconds second${seconds == 1 ? '' : 's'} ago';
    } else if (minutes < 60) {
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (hours < 24) {
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else {
      return '$days day${days == 1 ? '' : 's'} ago';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _commentController.addListener(_onTextChanged);

    // Update times every second
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // This will refresh all timestamps
      }
    });
  }

  void _onTextChanged() {
    setState(() {});
  }

  Future<void> _initializeVideo() async {
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      try {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl!),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
          httpHeaders: const {
            'Accept': 'video/*',
            'Range': 'bytes=0-',
          },
        );

        await _videoController!.initialize();

        if (mounted) {
          setState(() {});
          await _videoController!.setVolume(1.0);
          _videoController!.addListener(_onVideoStateChanged);
        }
      } catch (e) {
        if (_videoController != null) {
          await _videoController!.dispose();
          _videoController = null;
          if (mounted) {
            setState(() {});
          }
        }
      }
    }
  }

  void _onVideoStateChanged() {
    if (!mounted) return;
    setState(() {
      _isPlaying = _videoController!.value.isPlaying;
    });
  }

  void _toggleVideo() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
          _isPlaying = false;
        } else {
          _videoController!.play();
          _isPlaying = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _videoController?.dispose();
    _timeUpdateTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _showEditOptions() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const EditPostWidget(),
    );

    if (result != null && mounted) {
      switch (result) {
        case 'share':
          _handleShare();
          break;
        case 'edit':
          _showEditCaptionDialog();
          break;
        case 'delete':
          _showDeleteConfirmation();
          break;
      }
    }
  }

  void _showEditCaptionDialog() {
    final TextEditingController captionController =
        TextEditingController(text: widget.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: captionController,
          decoration: const InputDecoration(
            hintText: 'Enter new caption',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (captionController.text.trim().isNotEmpty) {
                widget.onUpdateCaption(captionController.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(child: Text('Delete Post')),
        content: const Text(
          'Are you sure you want to delete this post?',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  widget.onDelete();
                  Navigator.pop(context);
                },
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleShare() async {
    String shareText =
        '${widget.name} shared a post:\n\n${widget.description}\n\n';
    if (widget.postPic.isNotEmpty) {
      shareText += 'Image: ${widget.postPic}\n\n';
    }
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      shareText += 'Video: ${widget.videoUrl}\n\n';
    }
    shareText += 'Shared via Vandacoo';

    await Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    super.build(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: _buildProfileImage(),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(widget.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (widget.isCurrentUser)
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: _showEditOptions,
                  ),
              ],
            ),
          ),

          // Post Media (Image or Video)
          if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty)
            _buildVideoPlayer()
          else if (widget.postPic.isNotEmpty)
            _buildNetworkImage(widget.postPic.trim()),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            widget.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: widget.isLiked ? Colors.red : null,
                          ),
                          onPressed: widget.onLike,
                        ),
                        Text(
                          '${widget.likeCount}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.comment_outlined),
                          onPressed: widget.onComment,
                        ),
                        Text(
                          '${widget.commentCount}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: _handleShare,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        widget.isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color:
                            widget.isBookmarked ? AppColors.primaryColor : null,
                      ),
                      onPressed: widget.onBookmark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Description
          if (widget.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                widget.description,
                style: const TextStyle(fontSize: 14),
              ),
            ),

          const Divider(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return GestureDetector(
        onTap: _toggleVideo,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoPlayer(_videoController!),
                  if (_videoController!.value.hasError)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              'Error playing video\n${_videoController!.value.errorDescription}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!_isPlaying && widget.postPic.isNotEmpty)
              _buildThumbnailOverlay(),
            if (!_isPlaying) _buildPlayButton(),
          ],
        ),
      );
    }
    return _buildLoadingVideoPlayer();
  }

  Widget _buildThumbnailOverlay() {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _isPlaying ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: CachedNetworkImage(
          imageUrl: widget.postPic.trim(),
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildShimmer(),
          errorWidget: (context, url, error) => Container(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return AnimatedOpacity(
      opacity: _isPlaying ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 50,
        ),
      ),
    );
  }

  Widget _buildLoadingVideoPlayer() {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.postPic.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.postPic.trim(),
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildShimmer(),
              errorWidget: (context, url, error) => Container(
                color: Colors.black,
              ),
            ),
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 300,
        color: Colors.white,
      ),
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    if (imageUrl.isEmpty) return _buildShimmer();

    final cleanUrl = imageUrl.trim().replaceAll(RegExp(r'\s+'), '');

    return CachedNetworkImage(
      imageUrl: cleanUrl,
      width: double.infinity,
      height: 300,
      memCacheWidth: 1080,
      maxWidthDiskCache: 1080,
      maxHeightDiskCache: 1350,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 500),
      fadeOutDuration: const Duration(milliseconds: 500),
      cacheKey: cleanUrl,
      placeholder: (context, url) => _buildShimmer(),
      errorWidget: (context, url, error) {
        print('Image error: $error for URL: $url');
        return Container(
          width: double.infinity,
          height: 300,
          color: Colors.grey[300],
          child: const Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildProfileImage() {
    if (widget.proPic.isEmpty) {
      return const Icon(Icons.person, color: Colors.grey);
    }

    final cleanUrl = widget.proPic.trim().replaceAll(RegExp(r'\s+'), '');

    return CachedNetworkImage(
      imageUrl: cleanUrl,
      fit: BoxFit.cover,
      width: 40,
      height: 40,
      memCacheWidth: 80,
      maxWidthDiskCache: 80,
      maxHeightDiskCache: 80,
      cacheKey: cleanUrl,
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) {
        print('Image error: $error for URL: $url');
        return const Icon(Icons.person, color: Colors.grey);
      },
    );
  }
}
