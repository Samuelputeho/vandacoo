import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:vandacoo/features/messages/domain/entity/message_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

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
    return GestureDetector(
      onLongPress: () {
        if (isFromMe && onDelete != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Message'),
              content:
                  const Text('Are you sure you want to delete this message?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    onDelete!(message.id);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment:
            isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isFromMe) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                children: [
                  if (senderAvatar != null && senderAvatar!.isNotEmpty)
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(senderAvatar!),
                    )
                  else
                    CircleAvatar(
                      radius: 12,
                      child: Text(
                        senderName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    senderName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Align(
            alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isFromMe
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: isFromMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (message.messageType != MessageType.text)
                    _buildMediaContent(context),
                  if (message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: isFromMe ? Colors.white : null,
                        ),
                      ),
                    ),
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 8, bottom: 4, left: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeago.format(message.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isFromMe
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey[600],
                          ),
                        ),
                        if (isFromMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.readAt != null
                                ? Icons.done_all
                                : Icons.done,
                            size: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: message.mediaUrl!,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              fit: BoxFit.cover,
            ),
          ),
        );
      case MessageType.video:
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: VideoMessagePlayer(videoUrl: message.mediaUrl!),
        );
      default:
        return const SizedBox();
    }
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: message.mediaUrl!,
                fit: BoxFit.contain,
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
  ChewieController? _chewieController;
  bool _isInitialized = false;

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
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        autoPlay: false,
        looping: false,
        placeholder: const Center(child: CircularProgressIndicator()),
      );
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AspectRatio(
      aspectRatio: _videoPlayerController.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
