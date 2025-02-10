import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_comment_input.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_comment_tile.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';

class FollowPageListView extends StatefulWidget {
  final String userId;
  final List<PostEntity> userPosts;
  final PostEntity selectedPost;

  const FollowPageListView({
    super.key,
    required this.userId,
    required this.userPosts,
    required this.selectedPost,
  });

  @override
  State<FollowPageListView> createState() => _FollowPageListViewState();
}

class _FollowPageListViewState extends State<FollowPageListView> {
  late List<PostEntity> _orderedPosts;

  @override
  void initState() {
    super.initState();
    // Reorder posts to show selected post first
    _orderedPosts = _reorderPosts();

    // Initialize comments for all posts
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
    context.read<GlobalCommentsBloc>().add(
          GetAllGlobalPostsEvent(userId: widget.userId),
        );
  }

  List<PostEntity> _reorderPosts() {
    final posts = List<PostEntity>.from(widget.userPosts);
    posts.removeWhere((post) => post.id == widget.selectedPost.id);
    return [widget.selectedPost, ...posts];
  }

  void _handleComment(String postId, String posterUserName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
                  builder: (context, state) {
                    if (state is GlobalCommentsLoading) {
                      return const Center(child: Loader());
                    }

                    final comments = (state is GlobalCommentsDisplaySuccess)
                        ? state.comments
                            .where((comment) => comment.posterId == postId)
                            .toList()
                        : [];

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return GlobalCommentsTile(
                          comment: comment,
                          currentUserId: widget.userId,
                          formatTimeAgo: _formatTimeAgo,
                          onDelete: (commentId, userId) {
                            context.read<GlobalCommentsBloc>().add(
                                  DeleteGlobalCommentEvent(
                                    commentId: commentId,
                                    userId: userId,
                                  ),
                                );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              GlobalCommentsInput(
                postId: postId,
                userId: widget.userId,
                posterUserName: posterUserName,
                onSubmit: (comment) {
                  context.read<GlobalCommentsBloc>().add(
                        AddGlobalCommentEvent(
                          posterId: postId,
                          userId: widget.userId,
                          comment: comment,
                        ),
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 2));
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 0) return 'Just now';

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Posts'),
      ),
      body: BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
        builder: (context, state) {
          if (state is GlobalPostsLoading) {
            return const Center(child: Loader());
          }

          return ListView.builder(
            itemCount: _orderedPosts.length,
            itemBuilder: (context, index) {
              final post = _orderedPosts[index];
              final commentState = context.watch<GlobalCommentsBloc>().state;
              int commentCount = 0;

              if (commentState is GlobalCommentsDisplaySuccess) {
                commentCount = commentState.comments
                    .where((comment) => comment.posterId == post.id)
                    .length;
              }

              return GlobalCommentsPostTile(
                proPic: post.posterProPic?.trim().isNotEmpty == true
                    ? post.posterProPic!.trim()
                    : 'https://example.com/dummy.jpg',
                name: post.user?.name ?? post.posterName ?? 'Anonymous',
                postPic: post.imageUrl?.trim().isNotEmpty == true
                    ? post.imageUrl!.trim()
                    : 'https://example.com/dummy.jpg',
                description: post.caption ?? '',
                id: post.id,
                userId: post.userId,
                videoUrl: post.videoUrl?.trim().isNotEmpty == true
                    ? post.videoUrl!.trim()
                    : null,
                createdAt: post.createdAt,
                isLiked: post.isLiked,
                isBookmarked: post.isBookmarked,
                likeCount: post.likesCount,
                commentCount: commentCount,
                onLike: () {
                  context.read<GlobalCommentsBloc>().add(
                        GlobalToggleLikeEvent(
                          postId: post.id,
                          userId: widget.userId,
                        ),
                      );
                },
                onComment: () => _handleComment(
                  post.id,
                  post.posterName ?? 'Anonymous',
                ),
                onBookmark: () {
                  context.read<GlobalCommentsBloc>().add(
                        ToggleGlobalBookmarkEvent(
                          postId: post.id,
                        ),
                      );
                },
                onUpdateCaption: (newCaption) {
                  context.read<GlobalCommentsBloc>().add(
                        UpdateGlobalPostCaptionEvent(
                          postId: post.id,
                          caption: newCaption,
                        ),
                      );
                },
                onDelete: () {
                  context.read<GlobalCommentsBloc>().add(
                        DeleteGlobalPostEvent(
                          postId: post.id,
                        ),
                      );
                  Navigator.pop(context);
                },
                onReport: (reason, description) {
                  context.read<GlobalCommentsBloc>().add(
                        GlobalReportPostEvent(
                          postId: post.id,
                          reporterId: widget.userId,
                          reason: reason,
                          description: description,
                        ),
                      );
                },
                isCurrentUser: widget.userId == post.userId,
              );
            },
          );
        },
      ),
    );
  }
}
