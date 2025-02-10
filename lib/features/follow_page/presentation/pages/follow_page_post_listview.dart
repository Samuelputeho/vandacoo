import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/features/follow_page/presentation/pages/follow_page_comment_bottomsheet.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';

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

  void _handleLike(String postId) {
    context.read<GlobalCommentsBloc>().add(
          GlobalToggleLikeEvent(
            postId: postId,
            userId: widget.userId,
          ),
        );
  }

  void _handleBookmark(String postId) {
    // First, update the UI immediately through BookmarkCubit
    final bookmarkCubit = context.read<BookmarkCubit>();
    final isCurrentlyBookmarked = bookmarkCubit.isPostBookmarked(postId);
    bookmarkCubit.setBookmarkState(postId, !isCurrentlyBookmarked);

    context.read<GlobalCommentsBloc>().add(
          ToggleGlobalBookmarkEvent(
            postId: postId,
          ),
        );
  }

  void _handleUpdateCaption(String postId, String newCaption) {
    context.read<GlobalCommentsBloc>().add(
          UpdateGlobalPostCaptionEvent(
            postId: postId,
            caption: newCaption,
          ),
        );
  }

  void _handleDelete(String postId) {
    context.read<GlobalCommentsBloc>().add(
          DeleteGlobalPostEvent(
            postId: postId,
          ),
        );
  }

  void _handleReport(String postId, String reason, String? description) {
    context.read<GlobalCommentsBloc>().add(
          GlobalReportPostEvent(
            postId: postId,
            reporterId: widget.userId,
            reason: reason,
            description: description,
          ),
        );
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
            context.read<GlobalCommentsBloc>().add(
                  GetAllGlobalPostsEvent(userId: widget.userId),
                );
          } else if (state is GlobalBookmarkFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update bookmark: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
            context.read<GlobalCommentsBloc>().add(
                  GetAllGlobalPostsEvent(userId: widget.userId),
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

                  return BlocBuilder<BookmarkCubit, Map<String, bool>>(
                    builder: (context, bookmarkState) {
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
                        isBookmarked: bookmarkState[post.id] ?? false,
                        likeCount: post.likesCount,
                        commentCount: commentCount,
                        onLike: () => _handleLike(post.id),
                        onComment: () => _handleComment(
                          post.id,
                          post.posterName ?? 'Anonymous',
                        ),
                        onBookmark: () => _handleBookmark(post.id),
                        onUpdateCaption: (newCaption) =>
                            _handleUpdateCaption(post.id, newCaption),
                        onDelete: () => _handleDelete(post.id),
                        onReport: (reason, description) =>
                            _handleReport(post.id, reason, description),
                        isCurrentUser: widget.userId == post.userId,
                      );
                    },
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
