import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/core/common/entities/comment_entity.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/utils/time_formatter.dart';

import '../../../../core/common/global_comments/presentation/widgets/global_comment_input.dart';
import '../../../../core/common/global_comments/presentation/widgets/global_comment_tile.dart';

class BookmarkCommentBottomSheet extends StatefulWidget {
  final String postId;
  final String userId;
  final String posterUserName;

  const BookmarkCommentBottomSheet({
    super.key,
    required this.postId,
    required this.userId,
    required this.posterUserName,
  });

  @override
  State<BookmarkCommentBottomSheet> createState() =>
      _BookmarkCommentBottomSheetState();
}

class _BookmarkCommentBottomSheetState
    extends State<BookmarkCommentBottomSheet> {
  Timer? _timer;
  List<CommentEntity> _comments = [];

  @override
  void initState() {
    super.initState();
    // Comments should already be loaded by the parent screen, so no need to fetch again
    // context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());

    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimeAgo(DateTime dateTime) {
    return TimeFormatter.formatTimeAgo(dateTime);
  }

  void _handleCommentSubmit(String comment) {
    if (comment.trim().isNotEmpty) {
      try {
        context.read<GlobalCommentsBloc>().add(
              AddGlobalCommentEvent(
                posterId: widget.postId,
                userId: widget.userId,
                comment: comment.trim(),
              ),
            );
        // Show loading indicator or feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adding comment...'),
            duration: Duration(seconds: 1),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Network error. Please check your internet connection and try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleCommentSubmit(comment),
            ),
          ),
        );
      }
    }
  }

  void _handleCommentDelete(String commentId, String userId) {
    context.read<GlobalCommentsBloc>().add(
          DeleteGlobalCommentEvent(
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
      child: BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
        listener: (context, state) {
          if (state is GlobalCommentsDeleteFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GlobalCommentsDisplaySuccess ||
              state is GlobalPostsAndCommentsSuccess) {
            List<CommentEntity> comments = [];
            if (state is GlobalCommentsDisplaySuccess) {
              comments = state.comments;
            } else if (state is GlobalPostsAndCommentsSuccess) {
              comments = state.comments;
            }

            final postComments = comments
                .where((comment) => comment.posterId == widget.postId)
                .toList();
            setState(() {
              _comments = postComments;
            });
          } else if (state is GlobalCommentsDeleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Comment deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            // Get all comments again without showing loading state
            context.read<GlobalCommentsBloc>().add(
                  const GetAllGlobalCommentsEvent(isBackgroundRefresh: true),
                );
          } else if (state is GlobalCommentsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load comments: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: [
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
            Expanded(
              child: BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
                buildWhen: (previous, current) {
                  // Only rebuild for comment-related states
                  return current is GlobalCommentsLoading ||
                      current is GlobalCommentsFailure ||
                      current is GlobalCommentsDisplaySuccess ||
                      current is GlobalPostsAndCommentsSuccess;
                },
                builder: (context, state) {
                  // Get comments from the appropriate state
                  List<CommentEntity> comments = [];
                  if (state is GlobalCommentsDisplaySuccess) {
                    comments = state.comments;
                  } else if (state is GlobalPostsAndCommentsSuccess) {
                    comments = state.comments;
                  } else {
                    // Show loading for other states
                    return const Center(child: Loader());
                  }

                  final postComments = comments
                      .where((comment) => comment.posterId == widget.postId)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: postComments.length,
                    itemBuilder: (context, index) {
                      final comment = postComments[index];
                      return GlobalCommentsTile(
                        comment: comment,
                        currentUserId: widget.userId,
                        formatTimeAgo: _formatTimeAgo,
                        onDelete: _handleCommentDelete,
                      );
                    },
                  );
                },
              ),
            ),
            GlobalCommentsInput(
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
