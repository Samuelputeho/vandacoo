import 'package:flutter/material.dart';
import 'package:vandacoo/core/common/entities/comment_entity.dart';

class CommentTile extends StatefulWidget {
  final CommentEntity comment;
  final String currentUserId;
  final String Function(DateTime) formatTimeAgo;
  final Function(String, String) onDelete;

  const CommentTile({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.formatTimeAgo,
    required this.onDelete,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _isExpanded = false;
  bool _isPressed = false;

  String get displayText => widget.comment.comment.length > 100 && !_isExpanded
      ? '${widget.comment.comment.substring(0, 100)}...'
      : widget.comment.comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: GestureDetector(
        onLongPressStart: (_) {
          if (widget.comment.userId == widget.currentUserId) {
            setState(() {
              _isPressed = true;
            });
          }
        },
        onLongPressEnd: (_) {
          setState(() {
            _isPressed = false;
          });
        },
        onLongPressCancel: () {
          setState(() {
            _isPressed = false;
          });
        },
        onLongPress: () {
          if (widget.comment.userId == widget.currentUserId) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Comment'),
                content: const Text(
                  'Are you sure you want to delete this comment?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onDelete(widget.comment.id, widget.currentUserId);
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
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.comment.userProPic != null &&
                        widget.comment.userProPic!.isNotEmpty
                    ? NetworkImage(widget.comment.userProPic!
                        .trim()
                        .replaceAll(RegExp(r'\s+'), ''))
                    : const AssetImage('assets/user1.jpeg') as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.comment.userName ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        if (widget.comment.comment.length > 100) {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayText,
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (widget.comment.comment.length > 100)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _isExpanded ? 'Show less' : 'Show more',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.formatTimeAgo(widget.comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
