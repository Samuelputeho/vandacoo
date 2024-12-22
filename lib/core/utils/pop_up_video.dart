import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PopUpVideo {
  static void show(BuildContext context, String videoUrl) {
    // Extract video ID from URL
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);

    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid YouTube URL'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    bool isFullScreen = false;

    // Configure the YouTube player
    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        useHybridComposition: true,
        forceHD: true,
        enableCaption: false,
        hideControls: false,
        hideThumbnail: false,
        disableDragSeek: false,
        loop: false,
      ),
    );

    // Show dialog with video player
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(isFullScreen ? 0 : 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate dimensions based on screen size
                final maxWidth = isFullScreen
                    ? constraints.maxWidth
                    : constraints.maxWidth * 0.9;
                final maxHeight = isFullScreen
                    ? constraints.maxHeight
                    : constraints.maxHeight * 0.4;

                return Container(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              isFullScreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              setState(() {
                                isFullScreen = !isFullScreen;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              controller.pause();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      Flexible(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: YoutubePlayer(
                            controller: controller,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Colors.red,
                            progressColors: const ProgressBarColors(
                              playedColor: Colors.red,
                              handleColor: Colors.redAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
