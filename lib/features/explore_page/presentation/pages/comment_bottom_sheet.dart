import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/comments_bloc/comment_bloc.dart';
import 'package:vandacoo/features/explore_page/presentation/widgets/comment_tile.dart';
import 'package:vandacoo/features/explore_page/presentation/widgets/comment_input.dart';
import 'package:vandacoo/core/utils/time_formatter.dart';

class CommentBottomSheet extends StatefulWidget {
  final String postId;
  final String userId;
  final String posterUserName;
  const CommentBottomSheet({
    super.key,
    required this.postId,
    required this.userId,
    required this.posterUserName,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    //get all comments
    context.read<CommentBloc>().add(GetAllCommentsEvent());
    // Start a timer that updates the UI every minute
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {}); // Trigger rebuild to update time displays
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when disposing
    super.dispose();
  }

  String _formatTimeAgo(DateTime dateTime) {
    return TimeFormatter.formatTimeAgo(dateTime);
  }

  void _handleCommentSubmit(String comment) {
    context.read<CommentBloc>().add(
          AddCommentEvent(
            posterId: widget.postId,
            userId: widget.userId,
            comment: comment,
          ),
        );
  }

  void _handleCommentDelete(String commentId, String userId) {
    context.read<CommentBloc>().add(
          DeleteCommentEvent(
            commentId: commentId,
            userId: userId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: BlocListener<CommentBloc, CommentState>(
        listener: (context, state) {
          if (state is CommentDeleteFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is CommentDisplaySuccess) {
            // Show success message only if the state change was due to deletion
            final previousState = context.read<CommentBloc>().state;
            if (previousState is CommentDisplaySuccess &&
                state.comments.length < previousState.comments.length) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Comment deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else if (state is CommentDeleteFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is CommentDeleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Comment deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            //get all comments again
            context.read<CommentBloc>().add(GetAllCommentsEvent());
          }
        },
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
                        .toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: postComments.length,
                      itemBuilder: (context, index) {
                        final comment = postComments[index];
                        return CommentTile(
                          comment: comment,
                          currentUserId: widget.userId,
                          formatTimeAgo: _formatTimeAgo,
                          onDelete: _handleCommentDelete,
                        );
                      },
                    );
                  }

                  if (state is CommentLoadingCache) {
                    final postComments = state.comments
                        .where((comment) => comment.posterId == widget.postId)
                        .toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    return Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(
                            child: Text(
                              'Loading comments...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: postComments.length,
                            itemBuilder: (context, index) {
                              final comment = postComments[index];
                              return CommentTile(
                                comment: comment,
                                currentUserId: widget.userId,
                                formatTimeAgo: _formatTimeAgo,
                                onDelete: _handleCommentDelete,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Comment input
            CommentInput(
              postId: widget.postId,
              userId: widget.userId,
              posterUserName: widget.posterUserName,
              onSubmit: _handleCommentSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
