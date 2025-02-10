import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/features/explore_page/presentation/widgets/comment_tile.dart';
import 'package:vandacoo/features/explore_page/presentation/widgets/comment_input.dart';

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

  @override
  void initState() {
    super.initState();
    // Fetch comments when bottom sheet opens
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());

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
    final commentTime = dateTime;
    final now = DateTime.now().toUtc().add(const Duration(hours: 2));
    final difference = now.difference(commentTime);

    final seconds = difference.inSeconds;
    final minutes = difference.inMinutes;
    final hours = difference.inHours;
    final days = difference.inDays;
    final weeks = days ~/ 7;
    final months = days ~/ 30;
    final years = days ~/ 365;

    if (seconds < 0) {
      return 'Just now';
    } else if (seconds < 30) {
      return 'Just now';
    } else if (seconds < 60) {
      return '$seconds seconds ago';
    } else if (minutes < 60) {
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (hours < 24) {
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (days < 7) {
      return '$days day${days == 1 ? '' : 's'} ago';
    } else if (weeks < 4) {
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (months < 12) {
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      return '$years year${years == 1 ? '' : 's'} ago';
    }
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
          if (state is GlobalCommentsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GlobalCommentsDisplaySuccess) {
            // Show success message only if the state change was due to deletion
            final previousState = context.read<GlobalCommentsBloc>().state;
            if (previousState is GlobalCommentsDisplaySuccess &&
                state.comments.length < previousState.comments.length) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Comment deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else if (state is GlobalCommentsDeleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Comment deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            //get all comments again
            context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
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
                builder: (context, state) {
                  if (state is GlobalCommentsLoading) {
                    return const Center(child: Loader());
                  }

                  if (state is GlobalCommentsFailure) {
                    return Center(
                      child: Text('Error: ${state.error}'),
                    );
                  }

                  if (state is GlobalCommentsDisplaySuccess) {
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

                  if (state is GlobalCommentsLoadingCache) {
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
                  return const SizedBox.shrink();
                },
              ),
            ),
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
