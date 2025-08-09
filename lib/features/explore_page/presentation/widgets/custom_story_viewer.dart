import 'package:flutter/material.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'custom_story_controller.dart';
import 'custom_story_progress_indicator.dart';
import 'custom_story_content.dart';

class CustomStoryViewer extends StatefulWidget {
  final List<PostEntity> stories;
  final int initialIndex;
  final CustomStoryController controller;
  final VoidCallback? onComplete;
  final Function(int index)? onStoryChanged;
  final VoidCallback? onVerticalSwipeDown;
  final Function(String storyId)? onStoryViewed;

  const CustomStoryViewer({
    super.key,
    required this.stories,
    required this.controller,
    this.initialIndex = 0,
    this.onComplete,
    this.onStoryChanged,
    this.onVerticalSwipeDown,
    this.onStoryViewed,
  });

  @override
  State<CustomStoryViewer> createState() => _CustomStoryViewerState();
}

class _CustomStoryViewerState extends State<CustomStoryViewer> {
  late PageController _pageController;
  DateTime? _lastLeftTap;
  bool _isInitialized = false;
  int _restartTrigger = 0; // Used to trigger rebuilds for video restart
  final Set<String> _viewedInSession =
      {}; // Track stories viewed in this session

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: 1.0,
      keepPage: true,
    );

    // Set up controller callbacks
    widget.controller.onComplete = () {
      widget.onComplete?.call();
    };

    widget.controller.onStoryChanged = (index) {
      _animateToPage(index);
      widget.onStoryChanged?.call(index);
      // Mark the new story as viewed when navigating to it
      _markCurrentStoryAsViewed();
    };

    // Initialize controller with correct index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialIndex != 0) {
        widget.controller.goToStory(widget.initialIndex);
      }
      setState(() {
        _isInitialized = true;
      });
      // Mark the initial story as viewed
      _markCurrentStoryAsViewed();

      // Auto-start playing when there are multiple stories
      if (widget.stories.length > 1) {
        widget.controller.play();
      }
    });

    // Listen to controller changes
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      // Defer setState to avoid calling it during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _markCurrentStoryAsViewed() {
    final currentIndex = widget.controller.currentIndex;
    if (currentIndex >= 0 && currentIndex < widget.stories.length) {
      final storyId = widget.stories[currentIndex].id;
      if (!_viewedInSession.contains(storyId)) {
        _viewedInSession.add(storyId);
        widget.onStoryViewed?.call(storyId);
      }
    }
  }

  void _animateToPage(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleTap(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;
    final isLeftSide = tapPosition < screenWidth * 0.5;

    final now = DateTime.now();
    final timeSinceLastTap = _lastLeftTap != null
        ? now.difference(_lastLeftTap!).inMilliseconds
        : 2000;

    if (isLeftSide) {
      _lastLeftTap = now;

      // Special case: if there's only one story, always restart on first tap
      if (widget.stories.length == 1) {
        _restartCurrentStory();
        return;
      }

      // Check if we're at the beginning of the current story (progress < 0.1 means roughly at start)
      final isAtStart = widget.controller.progress < 0.1;

      // If tapped within 800ms, consider it a quick successive tap - always restart
      if (timeSinceLastTap < 800) {
        // Quick successive taps should restart the current story
        _restartCurrentStory();
      } else if (isAtStart && widget.controller.currentIndex > 0) {
        // If at the start and there's a previous story, go to previous
        widget.controller.previous();
      } else {
        // Otherwise restart current story
        _restartCurrentStory();
      }
    } else {
      // Right side tap - go to next story
      widget.controller.next();
    }
  }

  void _handleLongPressStart() {
    widget.controller.pause();
  }

  void _handleLongPressEnd() {
    widget.controller.play();
  }

  void _handleLongPressCancel() {
    // Resume playing if long press is cancelled
    widget.controller.play();
  }

  void _restartCurrentStory() {
    widget.controller.restart();
    // Trigger a rebuild to restart video content
    setState(() {
      _restartTrigger++;
    });
  }

  void _handleVerticalDrag(DragEndDetails details) {
    // Handle swipe down to close
    if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
      widget.onVerticalSwipeDown?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTapUp: _handleTap,
      onLongPressStart: (_) => _handleLongPressStart(),
      onLongPressEnd: (_) => _handleLongPressEnd(),
      onLongPressCancel: _handleLongPressCancel,
      onVerticalDragEnd: _handleVerticalDrag,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Story Content
            PageView.builder(
              controller: _pageController,
              itemCount: widget.stories.length,
              physics: const ClampingScrollPhysics(),
              pageSnapping: true,
              onPageChanged: (index) {
                widget.controller.goToStory(index);
              },
              itemBuilder: (context, index) {
                return CustomStoryContent(
                  key: ValueKey(
                      '${index}_${_restartTrigger}'), // Force rebuild on restart
                  story: widget.stories[index],
                  isActive: index == widget.controller.currentIndex,
                  isPaused: widget.controller.isPaused,
                  onLoadComplete: () {
                    // Start playing when content is loaded and this is the current story
                    // Only auto-play if there's only one story (single story mode)
                    if (index == widget.controller.currentIndex &&
                        !widget.controller.isPlaying &&
                        widget.stories.length == 1) {
                      widget.controller.play();
                    }
                  },
                  onContentReady: () {
                    // Start/resume progress timer when content is actually ready to play
                    if (index == widget.controller.currentIndex) {
                      if (widget.controller.isPlaying) {
                        widget.controller.startProgressWhenReady();
                      } else {
                        widget.controller.resumeProgressFromContent();
                      }
                      // Mark story as viewed when content is ready and actively displayed
                      _markCurrentStoryAsViewed();
                    }
                  },
                  onContentPaused: () {
                    // Pause progress timer when content freezes or has issues
                    if (index == widget.controller.currentIndex) {
                      widget.controller.pauseProgressDueToContent();
                    }
                  },
                  onProgressUpdate: (position, duration) {
                    // Update progress bar with real-time video position
                    if (index == widget.controller.currentIndex) {
                      widget.controller
                          .updateRealTimeProgress(position, duration);
                    }
                  },
                );
              },
            ),

            // Progress Indicator
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: widget.controller,
                  builder: (context, child) {
                    return CustomStoryProgressIndicator(
                      totalStories: widget.stories.length,
                      currentIndex: widget.controller.currentIndex,
                      currentProgress: widget.controller.progress,
                    );
                  },
                ),
              ),
            ),

            // Tap Areas (Invisible overlay for better gesture handling)
            Positioned.fill(
              child: Row(
                children: [
                  // Left tap area (50% of screen)
                  Expanded(
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                  // Right tap area (50% of screen)
                  Expanded(
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _pageController.dispose();
    super.dispose();
  }
}
