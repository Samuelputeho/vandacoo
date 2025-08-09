import 'package:flutter/material.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/utils/time_formatter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/entities/message_entity.dart';
import '../bloc/send_message_comment_bloc/send_message_comment_bloc.dart';
import '../widgets/custom_story_viewer.dart';
import '../widgets/custom_story_controller.dart';

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

class _StoryViewScreenState extends State<StoryViewScreen>
    with TickerProviderStateMixin {
  late CustomStoryController _storyController;
  final TextEditingController _commentController = TextEditingController();
  int currentIndex = 0;
  bool _isCommentVisible = false;
  int _wordCount = 0;
  bool _isCaptionExpanded = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _commentController.addListener(_updateWordCount);

    // Initialize custom story controller
    _storyController = CustomStoryController(
      totalStories: widget.stories.length,
      storyDuration: const Duration(seconds: 60),
      onComplete: () {
        Navigator.pop(context);
      },
      onStoryChanged: (index) {
        _onStoryChanged(index);
      },
    );

    // Initialize animation controller for comments
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create slide animation from bottom to middle
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Start from bottom (off-screen)
      end: const Offset(0.0, 0.0), // End at normal position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _onStoryChanged(int pageIndex) {
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

  String get displayCaption {
    final currentStory = widget.stories[currentIndex];
    if (currentStory.caption == null || currentStory.caption!.isEmpty) {
      return "";
    }
    return currentStory.caption!.length > 70 && !_isCaptionExpanded
        ? "${currentStory.caption!.substring(0, 70)}..."
        : currentStory.caption!;
  }

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

  void _closeReplyInterface() {
    // Immediately close without animation
    setState(() {
      _isCommentVisible = false;
    });
    _animationController.reset(); // Reset animation to initial state
    _storyController.play();
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

    // Immediately close without animation after sending
    _commentController.clear();
    _closeReplyInterface();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth > 600;

    return BlocListener<SendMessageCommentBloc, SendMessageCommentState>(
      listener: (context, state) {
        if (state is SendMessageCommentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Message sent'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else if (state is SendMessageCommentFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send: ${state.error}'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate safe heights with proper validation
              final availableHeight = constraints.maxHeight;
              final minStoryHeight = availableHeight * 0.5;
              final maxStoryHeight = availableHeight * 0.75;

              // Calculate story height based on available space - reduced to bring media closer to caption
              final storyHeight = isSmallScreen
                  ? (availableHeight * 0.55)
                      .clamp(minStoryHeight, maxStoryHeight)
                  : isTablet
                      ? (availableHeight * 0.58)
                          .clamp(minStoryHeight, maxStoryHeight)
                      : (availableHeight * 0.57)
                          .clamp(minStoryHeight, maxStoryHeight);

              return Stack(
                children: [
                  // Main Content Column
                  Column(
                    children: [
                      // Story Content Area with padding for centering
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(
                              top:
                                  15), // Add top margin to push progress indicator down
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: SizedBox(
                            height: storyHeight,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Custom Story View
                                CustomStoryViewer(
                                  stories: widget.stories,
                                  initialIndex: widget.initialIndex,
                                  controller: _storyController,
                                  onComplete: () {
                                    Navigator.pop(context);
                                  },
                                  onStoryChanged: _onStoryChanged,
                                  onVerticalSwipeDown: () {
                                    Navigator.pop(context);
                                  },
                                  onStoryViewed: widget.onStoryViewed,
                                ),

                                // Top Gradient Overlay
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: 100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.6),
                                          Colors.black.withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Top Bar with User Info - Fixed at very top of screen
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          // Back Arrow
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // User Avatar
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundImage:
                                  widget.stories[currentIndex].posterProPic !=
                                              null &&
                                          widget.stories[currentIndex]
                                              .posterProPic!.isNotEmpty
                                      ? NetworkImage(widget
                                          .stories[currentIndex].posterProPic!)
                                      : null,
                              backgroundColor: Colors.grey[700],
                              child:
                                  widget.stories[currentIndex].posterProPic ==
                                              null ||
                                          widget.stories[currentIndex]
                                              .posterProPic!.isEmpty
                                      ? Text(
                                          (widget.stories[currentIndex]
                                                      .posterName ??
                                                  'A')[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // User Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.stories[currentIndex].posterName ??
                                      'Anonymous',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  TimeFormatter.formatTimeAgo(
                                      widget.stories[currentIndex].createdAt),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Three Dots Menu
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                if (widget.stories[currentIndex].userId ==
                                    widget.userId) {
                                  _showDeleteConfirmation(
                                      widget.stories[currentIndex].id);
                                } else {
                                  // Show more options for other users
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Caption and Reply Section - Fixed at bottom
                  if (!_isCommentVisible)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Caption
                            if (widget.stories[currentIndex].caption != null &&
                                widget
                                    .stories[currentIndex].caption!.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.fromLTRB(20, 16, 20, 12),
                                child: GestureDetector(
                                  onTap: () {
                                    if (widget.stories[currentIndex].caption!
                                            .length >
                                        70) {
                                      setState(() {
                                        _isCaptionExpanded =
                                            !_isCaptionExpanded;
                                      });
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayCaption,
                                        style: TextStyle(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 16,
                                          height: 1.4,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      if (widget.stories[currentIndex].caption!
                                              .length >
                                          70)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            _isCaptionExpanded
                                                ? 'Show less'
                                                : 'Read more',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                            // Reply Interface (directly below caption)
                            if (widget.stories[currentIndex].userId !=
                                widget.userId)
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: Row(
                                  children: [
                                    // Reply Text Field
                                    Expanded(
                                      child: Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF2A2A2A)
                                              : const Color(0xFFF5F5F5),
                                          borderRadius:
                                              BorderRadius.circular(28),
                                          border: Border.all(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[700]!
                                                    : Colors.grey[300]!,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                            onTap: () {
                                              _storyController.pause();
                                              setState(() {
                                                _isCommentVisible = true;
                                              });
                                              _animationController.forward();
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'Reply',
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.grey[400]
                                                            : Colors.grey[600],
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // Heart Icon
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(25),
                                        onTap: () => _handleLike(
                                            widget.stories[currentIndex].id),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          child: Icon(
                                            widget.stories[currentIndex].isLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: widget.stories[currentIndex]
                                                    .isLiked
                                                ? Colors.red
                                                : (Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600]),
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Bottom padding for own stories (when no reply interface)
                            if (widget.stories[currentIndex].userId ==
                                widget.userId)
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: const SizedBox(height: 20),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Reply Overlay (when commenting)
                  if (_isCommentVisible &&
                      widget.stories[currentIndex].userId != widget.userId)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: GestureDetector(
                          onTap: () {
                            // Close immediately when tapping outside the modal
                            _closeReplyInterface();
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Bottom positioned animated container
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: constraints.maxHeight * 0.75,
                                child: ClipRect(
                                  child: SlideTransition(
                                    position: _slideAnimation,
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Container(
                                        height: constraints.maxHeight * 0.75,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[850]
                                              : Colors.white,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, -10),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            // Drag handle
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  top: 12),
                                              width: 40,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[600]
                                                    : Colors.grey[400],
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),

                                            // Header with close button
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 16),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'Reply to story',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black87,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    icon: Icon(
                                                      Icons.close,
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black87,
                                                      size: 24,
                                                    ),
                                                    onPressed: () {
                                                      _closeReplyInterface();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Text input area - Expanded to take more space
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        20, 0, 20, 20),
                                                child: Column(
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        width: double.infinity,
                                                        child: TextField(
                                                          controller:
                                                              _commentController,
                                                          autofocus: true,
                                                          maxLines: null,
                                                          expands: true,
                                                          textAlignVertical:
                                                              TextAlignVertical
                                                                  .top,
                                                          textCapitalization:
                                                              TextCapitalization
                                                                  .sentences,
                                                          style: TextStyle(
                                                            color: Theme.of(context)
                                                                        .brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? Colors.white
                                                                : Colors
                                                                    .black87,
                                                            fontSize: 16,
                                                            height: 1.5,
                                                          ),
                                                          decoration:
                                                              InputDecoration(
                                                            hintText:
                                                                'Write your reply here...',
                                                            hintStyle:
                                                                TextStyle(
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .dark
                                                                  ? Colors.white
                                                                      .withOpacity(
                                                                          0.6)
                                                                  : Colors
                                                                      .black54,
                                                              fontSize: 16,
                                                            ),
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              borderSide:
                                                                  BorderSide(
                                                                color: Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors.grey[
                                                                        700]!
                                                                    : Colors.grey[
                                                                        300]!,
                                                              ),
                                                            ),
                                                            enabledBorder:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              borderSide:
                                                                  BorderSide(
                                                                color: Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors.grey[
                                                                        700]!
                                                                    : Colors.grey[
                                                                        300]!,
                                                              ),
                                                            ),
                                                            focusedBorder:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              borderSide:
                                                                  BorderSide(
                                                                color: Theme.of(
                                                                        context)
                                                                    .primaryColor,
                                                                width: 2,
                                                              ),
                                                            ),
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .all(16),
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
                                                                  .split(RegExp(
                                                                      r'\s+'));
                                                              if (words.length >
                                                                  120) {
                                                                _commentController
                                                                        .text =
                                                                    words
                                                                        .take(
                                                                            120)
                                                                        .join(
                                                                            ' ');
                                                                _commentController
                                                                        .selection =
                                                                    TextSelection
                                                                        .fromPosition(
                                                                  TextPosition(
                                                                      offset: _commentController
                                                                          .text
                                                                          .length),
                                                                );
                                                              }
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ),

                                                    const SizedBox(height: 16),

                                                    // Bottom row with word count and send button
                                                    Row(
                                                      children: [
                                                        if (_wordCount > 0)
                                                          Text(
                                                            '$_wordCount/120 words',
                                                            style: TextStyle(
                                                              color: _canAddMoreWords
                                                                  ? (Theme.of(context)
                                                                              .brightness ==
                                                                          Brightness
                                                                              .dark
                                                                      ? Colors
                                                                          .white60
                                                                      : Colors
                                                                          .black54)
                                                                  : Colors
                                                                      .redAccent,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        const Spacer(),
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: _canAddMoreWords
                                                                ? Theme.of(
                                                                        context)
                                                                    .primaryColor
                                                                : (Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors.grey[
                                                                        700]
                                                                    : Colors.grey[
                                                                        400]),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        25),
                                                          ),
                                                          child: Material(
                                                            color: Colors
                                                                .transparent,
                                                            child: InkWell(
                                                              onTap: _canAddMoreWords
                                                                  ? _sendComment
                                                                  : null,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          25),
                                                              child: Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        24,
                                                                    vertical:
                                                                        12),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    const Icon(
                                                                      Icons
                                                                          .send,
                                                                      color: Colors
                                                                          .white,
                                                                      size: 18,
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            8),
                                                                    const Text(
                                                                      'Send',
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.removeListener(_updateWordCount);
    _storyController.dispose();
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
