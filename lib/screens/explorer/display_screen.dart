import 'package:flutter/material.dart';

class StatusDisplayScreen extends StatefulWidget {
  final List<String> images;

  const StatusDisplayScreen({super.key, required this.images});

  @override
  _StatusDisplayScreenState createState() => _StatusDisplayScreenState();
}

class _StatusDisplayScreenState extends State<StatusDisplayScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Duration for each image
    );

    // Start the animation
    _animationController.forward();

    // Automatically navigate through the images every 15 seconds
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextImage();
      }
    });
  }

  void _nextImage() {
    if (_currentIndex < widget.images.length - 1) {
      _currentIndex++;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animationController.reset(); // Reset the animation
      _animationController.forward(); // Start the animation again
    } else {
      Navigator.pop(context); // Close the status display when done
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Center(
                child: Image.asset(
                  widget.images[index],
                  fit: BoxFit.cover,
                ),
              );
            },
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _animationController
                    .reset(); // Reset the animation when the page changes
                _animationController.forward(); // Start the animation again
              });
            },
          ),
          // Progress bar
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _animationController.value,
                  backgroundColor: Colors.white.withOpacity(0.5),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.orange),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
