import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/features/comments/presentation/bloc/bloc/comment_bloc.dart';

class CommentBottomSheet extends StatefulWidget {
  final String postId;
  final String userId;

  const CommentBottomSheet({
    super.key,
    required this.postId,
    required this.userId,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;
  static const int maxCommentLength = 500;
  final Map<String, bool> _expandedComments = {};

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _commentController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    if (_commentController.text.isNotEmpty) {
      if (_commentController.text.length > maxCommentLength) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment cannot exceed $maxCommentLength characters'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      context.read<CommentBloc>().add(
            AddCommentEvent(
              posterId: widget.postId,
              userId: widget.userId,
              comment: _commentController.text,
            ),
          );
      _commentController.clear();
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now().toUtc();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 0) {
      return 'Just now';
    }

    final seconds = difference.inSeconds;
    final minutes = difference.inMinutes;
    final hours = difference.inHours;
    final days = difference.inDays;

    if (seconds < 5) {
      return 'Just now';
    } else if (seconds < 60) {
      return '$seconds second${seconds == 1 ? '' : 's'} ago';
    } else if (minutes < 60) {
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (hours < 24) {
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else {
      return '$days day${days == 1 ? '' : 's'} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Comments header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Comment input
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      maxLength: maxCommentLength,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _isComposing
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400],
                    ),
                    onPressed: _isComposing ? _submitComment : null,
                  ),
                ],
              ),
            ),
          ),

          // Comments list
          Expanded(
            child: BlocBuilder<CommentBloc, CommentState>(
              builder: (context, state) {
                if (state is CommentLoading) {
                  return const Center(child: Loader());
                }

                if (state is CommentFailure) {
                  return Center(
                    child: Text('Error: ${state.error}'),
                  );
                }

                if (state is CommentDisplaySuccess) {
                  final postComments = state.comments
                      .where((comment) => comment.posterId == widget.postId)
                      .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: postComments.length,
                    itemBuilder: (context, index) {
                      final comment = postComments[index];
                      final bool isExpanded =
                          _expandedComments[comment.id] ?? false;
                      final String displayText =
                          comment.comment.length > 100 && !isExpanded
                              ? '${comment.comment.substring(0, 100)}...'
                              : comment.comment;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: comment.userProPic != null &&
                                      comment.userProPic!.isNotEmpty
                                  ? NetworkImage(comment.userProPic!
                                      .trim()
                                      .replaceAll(RegExp(r'\s+'), ''))
                                  : const AssetImage('assets/user1.jpeg')
                                      as ImageProvider,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.userName ?? 'Anonymous',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      if (comment.comment.length > 100) {
                                        setState(() {
                                          _expandedComments[comment.id] =
                                              !isExpanded;
                                        });
                                      }
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayText,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        if (comment.comment.length > 100)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              isExpanded
                                                  ? 'Show less'
                                                  : 'Show more',
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
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatTimeAgo(comment.createdAt),
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
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
