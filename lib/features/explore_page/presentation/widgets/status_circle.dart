import 'package:flutter/material.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StatusCircle extends StatelessWidget {
  final PostEntity story;
  final bool isViewed;
  final VoidCallback onTap;
  final int totalStories;
  final bool displayRegion;

  const StatusCircle({
    super.key,
    required this.story,
    required this.isViewed,
    required this.onTap,
    required this.totalStories,
    this.displayRegion = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isStoryExpired =
        DateTime.now().difference(story.createdAt).inHours > 24;
    final mediaSize = MediaQuery.maybeOf(context)?.size;
    final double size = (mediaSize?.height ?? 700) * 0.06;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size + 24, // Fixed width for consistent spacing
      child: GestureDetector(
        onTap: isStoryExpired ? null : onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: size + 8,
              width: size + 8,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isViewed || isStoryExpired
                    ? null
                    : LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade900,
                        ],
                      ),
                color: isViewed || isStoryExpired
                    ? isDarkMode
                        ? Colors.grey[800]
                        : Colors.grey[300]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Story sections
                  if (totalStories > 1)
                    SizedBox(
                      width: size + 8,
                      height: size + 8,
                      child: CustomPaint(
                        painter: StoryArcPainter(
                          totalSections: totalStories,
                          color: isViewed || isStoryExpired
                              ? Colors.grey
                              : Colors.orange,
                        ),
                      ),
                    ),
                  Container(
                    height: size,
                    width: size,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: Colors.grey[200],
                        child: displayRegion
                            ? Center(
                                child: Text(
                                  story.region.substring(0, 2).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : story.posterProPic != null &&
                                    story.posterProPic!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: story.posterProPic!
                                        .trim()
                                        .replaceAll(RegExp(r'\s+'), ''),
                                    fit: BoxFit.cover,
                                    width: size,
                                    height: size,
                                    memCacheWidth: 160,
                                    maxWidthDiskCache: 160,
                                    maxHeightDiskCache: 160,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) {
                                      return const Icon(Icons.person,
                                          color: Colors.grey);
                                    },
                                  )
                                : const Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: size + 16,
              child: Text(
                displayRegion
                    ? story.region
                    : (story.posterName ?? 'Anonymous'),
                style: TextStyle(
                  fontSize: 11,
                  color: isStoryExpired
                      ? Colors.grey
                      : isDarkMode
                          ? Colors.white
                          : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryArcPainter extends CustomPainter {
  final int totalSections;
  final Color color;

  StoryArcPainter({
    required this.totalSections,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;

    for (int i = 0; i < totalSections; i++) {
      final double startAngle = (i * 2 * 3.14159) / totalSections;
      final double sweepAngle = (2 * 3.14159) / totalSections - 0.05;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
