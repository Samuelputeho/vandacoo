import 'package:flutter/material.dart';

class CustomStoryProgressIndicator extends StatelessWidget {
  final int totalStories;
  final int currentIndex;
  final double currentProgress;
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final EdgeInsets padding;

  const CustomStoryProgressIndicator({
    super.key,
    required this.totalStories,
    required this.currentIndex,
    required this.currentProgress,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white38,
    this.height = 3.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Row(
        children: List.generate(totalStories, (index) {
          return Expanded(
            child: Container(
              height: height,
              margin: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 1.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height / 2),
                child: LinearProgressIndicator(
                  value: _getProgressForIndex(index),
                  backgroundColor: inactiveColor,
                  valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  double _getProgressForIndex(int index) {
    if (index < currentIndex) {
      return 1.0; // Completed stories
    } else if (index == currentIndex) {
      return currentProgress; // Current story progress
    } else {
      return 0.0; // Future stories
    }
  }
}
