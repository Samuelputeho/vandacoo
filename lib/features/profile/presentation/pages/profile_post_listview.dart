import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/features/profile/presentation/pages/profile_comment_bottomsheet.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';

class ProfilePostListView extends StatefulWidget {
  final String userId;
  final List<PostEntity> userPosts;
  final PostEntity selectedPost;
  final String screenType;

  const ProfilePostListView({
    super.key,
    required this.userId,
    required this.userPosts,
    required this.selectedPost,
    required this.screenType,
  });

  @override
  State<ProfilePostListView> createState() => _ProfilePostListViewState();
}

class _ProfilePostListViewState extends State<ProfilePostListView> {
  late List<PostEntity> _orderedPosts;
  // Keep a local copy of posts to avoid modifying widget.userPosts
  late List<PostEntity> _localPosts;
  // Keep track of the latest comments
  List<dynamic> _latestComments = [];

  @override
  void initState() {
    super.initState();

    // Get the current state
    final currentState = context.read<GlobalCommentsBloc>().state;

    // Initialize posts with latest state if available
    if (currentState is GlobalPostsDisplaySuccess) {
      // Create a map of current state posts for quick lookup
      final statePostsMap = {
        for (var post in currentState.posts) post.id: post
      };

      // Initialize local posts with latest state data
      _localPosts = widget.userPosts.map((post) {
        final latestPost = statePostsMap[post.id];
        return latestPost ?? post;
      }).toList();
    } else {
      _localPosts = List<PostEntity>.from(widget.userPosts);
    }

    _orderedPosts = _reorderPosts();

    // Always request fresh data to ensure we have the latest
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
    context.read<GlobalCommentsBloc>().add(
          GetAllGlobalPostsEvent(
            userId: widget.userId,
            screenType: widget.screenType,
          ),
        );
  }

  List<PostEntity> _reorderPosts() {
    // Create a new list from local posts
    final posts = List<PostEntity>.from(_localPosts);

    // Find the selected post in the list
    final selectedPostIndex =
        posts.indexWhere((post) => post.id == widget.selectedPost.id);

    if (selectedPostIndex != -1) {
      // If found, remove it and add it to the front
      final selectedPost = posts.removeAt(selectedPostIndex);
      posts.insert(0, selectedPost);
    } else {
      // Find the selected post in the current state
      final currentState = context.read<GlobalCommentsBloc>().state;
      if (currentState is GlobalPostsDisplaySuccess) {
        final latestSelectedPost = currentState.posts.firstWhere(
          (post) => post.id == widget.selectedPost.id,
          orElse: () => widget.selectedPost,
        );
        posts.insert(0, latestSelectedPost);
      } else {
        posts.insert(0, widget.selectedPost);
      }
    }

    return posts;
  }

  void _updatePosts(List<PostEntity> updatedPosts) {
    // Create a map of updated posts for easy lookup
    final updatedPostsMap = {for (var post in updatedPosts) post.id: post};

    // Update local posts while preserving order
    _localPosts = _localPosts.map((post) {
      final updatedPost = updatedPostsMap[post.id];
      return updatedPost ?? post;
    }).toList();

    // Reorder posts with the updated data
    _orderedPosts = _reorderPosts();
  }

  void _handleLike(String postId) {
    // Optimistically update the local state
    setState(() {
      _localPosts = _localPosts.map((p) {
        if (p.id == postId) {
          return p.copyWith(
            isLiked: !p.isLiked,
            likesCount: p.isLiked ? p.likesCount - 1 : p.likesCount + 1,
          );
        }
        return p;
      }).toList();
      _orderedPosts = _reorderPosts();
    });

    // Toggle the like without reloading posts
    context.read<GlobalCommentsBloc>().add(
          GlobalToggleLikeEvent(
            postId: postId,
            userId: widget.userId,
          ),
        );
  }

  void _handleBookmark(String postId) {
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
          child: ProfileCommentBottomSheet(
            postId: postId,
            userId: widget.userId,
            posterUserName: posterUserName,
          ),
        ),
      ),
    );
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
          if (state is GlobalCommentsDisplaySuccess) {
            _latestComments = state.comments;
          } else if (state is GlobalPostsDisplaySuccess) {
            // Find matching posts from the state
            final updatedPosts = state.posts
                .where((post) =>
                    _localPosts.any((localPost) => localPost.id == post.id))
                .toList();

            if (updatedPosts.isNotEmpty) {
              setState(() {
                _updatePosts(updatedPosts);
              });
            }
          } else if (state is GlobalPostDeleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true);
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
          } else if (state is GlobalPostReportSuccess) {
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
          // Only rebuild for new comments or initial posts load
          return current is GlobalCommentsDisplaySuccess ||
              (current is GlobalPostsDisplaySuccess &&
                  previous is GlobalCommentsLoadingCache);
        },
        builder: (context, state) {
          return ListView.builder(
            itemCount: _orderedPosts.length,
            itemBuilder: (context, index) {
              final post = _orderedPosts[index];

              // Calculate comment count using latest comments
              final commentCount = _latestComments
                  .where((comment) => comment.posterId == post.id)
                  .length;

              return BlocBuilder<BookmarkCubit, Map<String, bool>>(
                builder: (context, bookmarkState) {
                  final isBookmarked = bookmarkState[post.id] ?? false;

                  return GlobalCommentsPostTile(
                    region: post.region,
                    proPic: post.posterProPic?.trim() ?? '',
                    name: post.user?.name ?? post.posterName ?? 'Loading...',
                    postPic: post.imageUrl?.trim() ?? '',
                    description: post.caption ?? '',
                    id: post.id,
                    userId: post.userId,
                    videoUrl: post.videoUrl?.trim(),
                    createdAt: post.createdAt,
                    isLiked: post.isLiked,
                    isBookmarked: isBookmarked,
                    likeCount: post.likesCount,
                    commentCount: commentCount,
                    onLike: () => _handleLike(post.id),
                    onComment: () =>
                        _handleComment(post.id, post.posterName ?? ''),
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
      ),
    );
  }
}
