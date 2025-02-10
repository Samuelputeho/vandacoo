import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_comment_input.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_comment_tile.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/features/follow_page/presentation/pages/follow_page_comment_bottomsheet.dart';

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
        builder: (_, scrollController) => BlocProvider.value(
          value: context.read<GlobalCommentsBloc>(),
          child: FollowPageCommentBottomSheet(
            postId: postId,
            userId: widget.userId,
            posterUserName: posterUserName,
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
      body: BlocConsumer<GlobalCommentsBloc, GlobalCommentsState>(
        listener: (context, state) {
          if (state is GlobalLikeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to like post: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GlobalPostDeleteSuccess) {
            context.read<GlobalCommentsBloc>().add(
                  GetAllGlobalPostsEvent(userId: widget.userId),
                );
          } else if (state is GlobalPostDeleteFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete post: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GlobalPostUpdateSuccess) {
            context.read<GlobalCommentsBloc>().add(
                  GetAllGlobalPostsEvent(userId: widget.userId),
                );
          } else if (state is GlobalPostUpdateFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update post: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GlobalBookmarkSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bookmark updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is GlobalBookmarkFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update bookmark: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GlobalPostReportSuccess) {
            context.read<GlobalCommentsBloc>().add(
                  GetAllGlobalPostsEvent(userId: widget.userId),
                );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post reported successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is GlobalPostReportFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to report post: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GlobalPostAlreadyReportedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You have already reported this post'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        buildWhen: (previous, current) {
          return current is GlobalPostsLoading ||
              current is GlobalPostsFailure ||
              current is GlobalPostsDisplaySuccess ||
              current is GlobalPostsLoadingCache;
        },
        builder: (context, state) {
          if (state is GlobalPostsLoading) {
            return const Center(child: Loader());
          }

          final displayPosts = (state is GlobalPostsDisplaySuccess)
              ? state.posts
                  .where((post) => widget.userPosts
                      .any((userPost) => userPost.id == post.id))
                  .toList()
              : _orderedPosts;

          return ListView.builder(
            itemCount: displayPosts.length,
            itemBuilder: (context, index) {
              final post = displayPosts[index];
              return BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
                buildWhen: (previous, current) {
                  return current is GlobalCommentsDisplaySuccess ||
                      current is GlobalCommentsLoadingCache;
                },
                builder: (context, commentState) {
                  int commentCount = 0;

                  if (commentState is GlobalCommentsDisplaySuccess ||
                      commentState is GlobalCommentsLoadingCache) {
                    final comments = (commentState
                            is GlobalCommentsDisplaySuccess)
                        ? commentState.comments
                        : (commentState as GlobalCommentsLoadingCache).comments;

                    commentCount = comments
                        .where((comment) => comment.posterId == post.id)
                        .length;
                  }

                  return GlobalCommentsPostTile(
                    proPic: post.posterProPic?.trim() ?? '',
                    name: post.user?.name ?? post.posterName ?? 'Anonymous',
                    postPic: post.imageUrl?.trim() ?? '',
                    description: post.caption ?? '',
                    id: post.id,
                    userId: post.userId,
                    videoUrl: post.videoUrl?.trim(),
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
          );
        },
      ),
    );
  }
}
