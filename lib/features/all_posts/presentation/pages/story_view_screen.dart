import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';

class StoryViewScreen extends StatefulWidget {
  final List<PostEntity> stories;
  final int initialIndex;
  final Function(String) onStoryViewed;
  final String userId;

  const StoryViewScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.onStoryViewed,
    required this.userId,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStoryViewed(widget.stories[_currentIndex].id);
      _progressController.forward();
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _progressController.reset();
    _progressController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStoryViewed(widget.stories[index].id);
    });
  }

  void _onTapDown(TapDownDetails details) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;

    if (dx < screenWidth / 2) {
      _previousStory();
    } else {
      _nextStory();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: _onTapDown,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return Stack(
                  children: [
                    if (story.imageUrl != null)
                      Center(
                        child: Image.network(
                          story.imageUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.error, color: Colors.white),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Progress bar
                Row(
                  children: List.generate(
                    widget.stories.length,
                    (index) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            double progress = 0.0;
                            if (index < _currentIndex) {
                              progress = 1.0;
                            } else if (index == _currentIndex) {
                              progress = _progressController.value;
                            }
                            return LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.withOpacity(0.5),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              minHeight: 2,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // User info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          widget.stories[_currentIndex].posterProPic != null &&
                                  widget.stories[_currentIndex].posterProPic!
                                      .isNotEmpty
                              ? NetworkImage(
                                  widget.stories[_currentIndex].posterProPic!)
                              : null,
                      child:
                          (widget.stories[_currentIndex].posterProPic == null ||
                                  widget.stories[_currentIndex].posterProPic!
                                      .isEmpty)
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.stories[_currentIndex].posterName ?? 'Anonymous',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
