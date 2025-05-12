import 'package:flutter/material.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:story_view/story_view.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/entities/message_entity.dart';
import '../bloc/send_message_comment_bloc/send_message_comment_bloc.dart';

class StoryViewScreen extends StatefulWidget {
  final List<PostEntity> stories;
  final int initialIndex;
  final Function(String) onStoryViewed;
  final String userId;
  final String senderName;
  final Function(String)? onDelete;

  const StoryViewScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.onStoryViewed,
    required this.userId,
    required this.senderName,
    this.onDelete,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  final StoryController controller = StoryController();
  final TextEditingController _commentController = TextEditingController();
  List<StoryItem> storyItems = [];
  int currentIndex = 0;
  bool _isCommentVisible = false;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _loadStories();
    _commentController.addListener(_updateWordCount);
  }

  void _loadStories() {
    storyItems = widget.stories.map((story) {
      if (story.videoUrl != null && story.videoUrl!.isNotEmpty) {
        return StoryItem.pageVideo(
          story.videoUrl!,
          controller: controller,
          duration: const Duration(seconds: 10),
        );
      } else if (story.imageUrl != null && story.imageUrl!.isNotEmpty) {
        return StoryItem.pageImage(
          url: story.imageUrl!,
          controller: controller,
        );
      } else {
        return StoryItem.text(
          title: story.caption ?? '',
          backgroundColor: Colors.black,
          textStyle: const TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        );
      }
    }).toList();
  }

  void _onStoryChanged(StoryItem storyItem, int pageIndex) {
    // Mark story as viewed both on initial show and when changing stories
    widget.onStoryViewed(widget.stories[pageIndex].id);

    // Update current index
    if (pageIndex != currentIndex) {
      setState(() {
        currentIndex = pageIndex;
      });
    }
  }

  void _updateWordCount() {
    setState(() {
      _wordCount = _commentController.text
          .trim()
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .length;
    });
  }

  bool get _canAddMoreWords => _wordCount < 120;

  void _handleLike(String storyId) {
    final currentStory = widget.stories[currentIndex];
    MessageType messageType = MessageType.text;
    String? mediaUrl;

    if (currentStory.videoUrl != null && currentStory.videoUrl!.isNotEmpty) {
      messageType = MessageType.video;
      mediaUrl = currentStory.videoUrl;
    } else if (currentStory.imageUrl != null &&
        currentStory.imageUrl!.isNotEmpty) {
      messageType = MessageType.image;
      mediaUrl = currentStory.imageUrl;
    }

    context.read<SendMessageCommentBloc>().add(
          SendMessageCommentRequestEvent(
            senderId: widget.userId,
            receiverId: currentStory.userId,
            content: "${widget.senderName} liked your story",
            messageType: messageType,
            mediaUrl: mediaUrl,
            mediaFile: null,
          ),
        );

    // Update UI to show liked state
    setState(() {
      widget.stories[currentIndex] = widget.stories[currentIndex].copyWith(
        isLiked: true,
      );
    });
  }

  Widget _buildHeader(PostEntity story) {
    final timeAgo = timeago.format(story.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundImage:
                  story.posterProPic != null && story.posterProPic!.isNotEmpty
                      ? NetworkImage(story.posterProPic!)
                      : null,
              backgroundColor: Colors.grey[800],
              child: story.posterProPic == null || story.posterProPic!.isEmpty
                  ? Text(
                      (story.posterName ?? 'A')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  story.posterName ?? 'Anonymous',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (story.userId !=
              widget.userId) // Only show like button for other people's stories
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                story.isLiked ? Icons.favorite : Icons.favorite_border,
                color: story.isLiked ? Colors.red : Colors.white,
                size: 24,
              ),
              onPressed: () => _handleLike(story.id),
            ),
        ],
      ),
    );
  }

  Widget _buildCaption(PostEntity story) {
    if (story.caption == null || story.caption!.isEmpty) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(
        story.caption!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
          shadows: [
            Shadow(
              color: Colors.black54,
              offset: Offset(1, 1),
              blurRadius: 4,
            ),
          ],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showDeleteConfirmation(String storyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story'),
        content: const Text('Are you sure you want to delete this story?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              widget.onDelete?.call(storyId);
              Navigator.pop(context); // Close story view
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _sendComment() {
    if (_commentController.text.trim().isEmpty) return;

    final currentStory = widget.stories[currentIndex];
    MessageType messageType = MessageType.text;
    String? mediaUrl;

    if (currentStory.videoUrl != null && currentStory.videoUrl!.isNotEmpty) {
      messageType = MessageType.video;
      mediaUrl = currentStory.videoUrl;
    } else if (currentStory.imageUrl != null &&
        currentStory.imageUrl!.isNotEmpty) {
      messageType = MessageType.image;
      mediaUrl = currentStory.imageUrl;
    }

    context.read<SendMessageCommentBloc>().add(
          SendMessageCommentRequestEvent(
            senderId: widget.userId,
            receiverId: currentStory.userId,
            content: _commentController.text.trim(),
            messageType: messageType,
            mediaUrl: mediaUrl,
            mediaFile: null,
          ),
        );

    setState(() {
      _isCommentVisible = false;
    });
    _commentController.clear();
    controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SendMessageCommentBloc, SendMessageCommentState>(
      listener: (context, state) {
        if (state is SendMessageCommentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Interaction sent'),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (state is SendMessageCommentFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send: ${state.error}'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Story View
              StoryView(
                storyItems: storyItems,
                controller: controller,
                onStoryShow: _onStoryChanged,
                onComplete: () => Navigator.pop(context),
                progressPosition: ProgressPosition.top,
                onVerticalSwipeComplete: (direction) {
                  if (direction == Direction.down) {
                    Navigator.pop(context);
                  }
                },
              ),

              // Top Gradient
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.25,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),

              // Content Overlay
              Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildHeader(widget.stories[currentIndex]),
                        ),
                        if (widget.stories[currentIndex].userId ==
                            widget.userId)
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.white, size: 24),
                            onPressed: () => _showDeleteConfirmation(
                                widget.stories[currentIndex].id),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Caption
                  _buildCaption(widget.stories[currentIndex]),
                  // Reply Interface
                  if (widget.stories[currentIndex].userId != widget.userId)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        maxHeight: 150,
                      ),
                      decoration: BoxDecoration(
                        color: _isCommentVisible
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black26,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: _isCommentVisible
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isCommentVisible = false;
                                    });
                                    controller.play();
                                  },
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 8,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Flexible(
                                          child: TextField(
                                            controller: _commentController,
                                            autofocus: true,
                                            maxLines: null,
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Reply to story...',
                                              hintStyle: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                              ),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 10,
                                              ),
                                              border: InputBorder.none,
                                            ),
                                            onSubmitted: (_) {
                                              if (_canAddMoreWords) {
                                                _sendComment();
                                              }
                                            },
                                            onChanged: (text) {
                                              if (!_canAddMoreWords) {
                                                final words = text
                                                    .trim()
                                                    .split(RegExp(r'\s+'));
                                                if (words.length > 120) {
                                                  _commentController.text =
                                                      words.take(120).join(' ');
                                                  _commentController.selection =
                                                      TextSelection
                                                          .fromPosition(
                                                    TextPosition(
                                                        offset:
                                                            _commentController
                                                                .text.length),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                        if (_wordCount > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 4, right: 4),
                                            child: Text(
                                              '$_wordCount/120 words',
                                              style: TextStyle(
                                                color: _canAddMoreWords
                                                    ? Colors.white60
                                                    : Colors.redAccent,
                                                fontSize: 11,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    Icons.send,
                                    color: _canAddMoreWords
                                        ? Colors.white
                                        : Colors.white38,
                                    size: 22,
                                  ),
                                  onPressed:
                                      _canAddMoreWords ? _sendComment : null,
                                ),
                              ],
                            )
                          : InkWell(
                              onTap: () {
                                controller.pause();
                                setState(() {
                                  _isCommentVisible = true;
                                });
                              },
                              child: const Center(
                                child: Text(
                                  'Tap to reply',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.removeListener(_updateWordCount);
    controller.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
