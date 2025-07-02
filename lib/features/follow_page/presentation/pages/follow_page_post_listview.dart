import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';

import '../../../../core/common/global_comments/presentation/widgets/global_comment_bottomsheet.dart';

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
  // Stable post list - set once and maintained
  late final List<PostEntity> _stablePosts;

  // Local state for optimistic updates
  final Map<String, bool> _localLikeStates = {};
  final Map<String, int> _localLikeCounts = {};
  final Map<String, bool> _localBookmarkStates = {};
  final Map<String, int> _commentCounts = {};

  // Track which posts have pending optimistic updates
  final Map<String, DateTime> _pendingLikeUpdates = {};
  final Map<String, DateTime> _pendingBookmarkUpdates = {};

  // Video management
  String? _currentPlayingVideoId;
  final Map<String, GlobalKey> _postKeys = {};

  @override
  void initState() {
    super.initState();

    // Create stable, ordered post list once
    _initializeStablePosts();

    // Load comments and posts to get latest state
    _loadLatestState();

    // Initialize video keys
    for (final post in _stablePosts) {
      _postKeys[post.id] = GlobalKey();
    }
  }

  void _initializeStablePosts() {
    final posts = List<PostEntity>.from(widget.userPosts);
    posts.removeWhere((post) => post.id == widget.selectedPost.id);
    _stablePosts = [widget.selectedPost, ...posts];

    // Initialize local states from post data
    for (final post in _stablePosts) {
      _localLikeStates[post.id] = post.isLiked;
      _localLikeCounts[post.id] = post.likesCount;
      _localBookmarkStates[post.id] = false; // Will be updated by BookmarkCubit
      _commentCounts[post.id] = 0; // Will be updated when comments load
    }
  }

  void _loadLatestState() {
    // Load comments
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());

    // Load latest posts to sync with server state
    context.read<GlobalCommentsBloc>().add(
          GetAllGlobalPostsEvent(
            userId: widget.userId,
            screenType: 'explore',
          ),
        );
  }

  void _syncWithGlobalState(List<PostEntity> globalPosts) {
    final now = DateTime.now();
    bool stateChanged = false;

    for (final globalPost in globalPosts) {
      final postId = globalPost.id;

      // Only sync posts that are in our stable list
      if (!_stablePosts.any((p) => p.id == postId)) continue;

      // Sync like state if no recent pending update
      final lastLikeUpdate = _pendingLikeUpdates[postId];
      if (lastLikeUpdate == null ||
          now.difference(lastLikeUpdate).inSeconds > 3) {
        if (_localLikeStates[postId] != globalPost.isLiked ||
            _localLikeCounts[postId] != globalPost.likesCount) {
          _localLikeStates[postId] = globalPost.isLiked;
          _localLikeCounts[postId] = globalPost.likesCount;
          _pendingLikeUpdates.remove(postId); // Clear pending flag
          stateChanged = true;
        }
      }

      // Sync bookmark state if no recent pending update
      final lastBookmarkUpdate = _pendingBookmarkUpdates[postId];
      if (lastBookmarkUpdate == null ||
          now.difference(lastBookmarkUpdate).inSeconds > 3) {
        // Bookmark state will be handled by BookmarkCubit, so we don't need to sync here
        _pendingBookmarkUpdates.remove(postId); // Clear pending flag
      }
    }

    // Update UI if state changed, but without rebuilding everything
    if (stateChanged && mounted) {
      setState(() {});
    }
  }

  // Handle user interactions
  void _handleLike(String postId) {
    final now = DateTime.now();

    setState(() {
      final currentLiked = _localLikeStates[postId] ?? false;
      final currentCount = _localLikeCounts[postId] ?? 0;

      _localLikeStates[postId] = !currentLiked;
      _localLikeCounts[postId] =
          currentLiked ? currentCount - 1 : currentCount + 1;
      _pendingLikeUpdates[postId] = now; // Mark as pending
    });

    // Send to backend
    context.read<GlobalCommentsBloc>().add(
          GlobalToggleLikeEvent(
            postId: postId,
            userId: widget.userId,
          ),
        );
  }

  void _handleBookmark(String postId) {
    final now = DateTime.now();

    setState(() {
      final currentBookmarked = _localBookmarkStates[postId] ?? false;
      _localBookmarkStates[postId] = !currentBookmarked;
      _pendingBookmarkUpdates[postId] = now; // Mark as pending
    });

    // Update global state
    final bookmarkCubit = context.read<BookmarkCubit>();
    final currentState = bookmarkCubit.isPostBookmarked(postId);
    bookmarkCubit.setBookmarkState(postId, !currentState);

    context.read<GlobalCommentsBloc>().add(
          ToggleGlobalBookmarkEvent(postId: postId),
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
          child: GlobalCommentBottomSheet(
            postId: postId,
            userId: widget.userId,
            posterUserName: posterUserName,
          ),
        ),
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
          DeleteGlobalPostEvent(postId: postId),
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

  // Video management
  void _handleVideoPlay(String postId) {
    if (_currentPlayingVideoId != null && _currentPlayingVideoId != postId) {
      _pauseVideo(_currentPlayingVideoId!);
    }
    _currentPlayingVideoId = postId;
  }

  void _handleVideoPause(String postId) {
    if (_currentPlayingVideoId == postId) {
      _currentPlayingVideoId = null;
    }
  }

  void _pauseVideo(String postId) {
    final key = _postKeys[postId];
    if (key?.currentState != null) {
      try {
        final postTileState = key!.currentState as dynamic;
        if (postTileState != null && postTileState.mounted) {
          postTileState.pauseVideo();
        }
      } catch (e) {
        // Handle case where pauseVideo method doesn't exist
      }
    }
  }

  void _onPostVisibilityChanged(String postId, VisibilityInfo info) {
    if (info.visibleFraction < 0.5) {
      if (_currentPlayingVideoId == postId) {
        _pauseVideo(postId);
        _currentPlayingVideoId = null;
      }
    }
  }

  Widget _buildPostTile(PostEntity post) {
    return VisibilityDetector(
      key: Key('follow_page_post_${post.id}'),
      onVisibilityChanged: (info) => _onPostVisibilityChanged(post.id, info),
      child: BlocBuilder<BookmarkCubit, Map<String, bool>>(
        buildWhen: (previous, current) => previous[post.id] != current[post.id],
        builder: (context, bookmarkState) {
          // Use local state for immediate updates, fall back to global state
          final isBookmarked = _localBookmarkStates[post.id] ??
              (bookmarkState[post.id] ?? false);
          final isLiked = _localLikeStates[post.id] ?? post.isLiked;
          final likeCount = _localLikeCounts[post.id] ?? post.likesCount;
          final commentCount = _commentCounts[post.id] ?? 0;

          return GlobalCommentsPostTile(
            key: _postKeys[post.id],
            region: post.region,
            proPic: post.posterProPic?.trim() ?? '',
            name: post.user?.name ?? post.posterName ?? 'Anonymous',
            postPic: post.imageUrl?.trim() ?? '',
            description: post.caption ?? '',
            id: post.id,
            userId: post.userId,
            videoUrl: post.videoUrl?.trim(),
            createdAt: post.createdAt,
            isLiked: isLiked,
            isBookmarked: isBookmarked,
            likeCount: likeCount,
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
            onVideoPlay: () => _handleVideoPlay(post.id),
            onVideoPause: () => _handleVideoPause(post.id),
          );
        },
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
      body: Column(
        children: [
          // Global state sync listener - updates local state from server
          BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
            listenWhen: (previous, current) =>
                current is GlobalPostsDisplaySuccess,
            listener: (context, state) {
              if (state is GlobalPostsDisplaySuccess) {
                _syncWithGlobalState(state.posts);
              }
            },
            child: const SizedBox.shrink(),
          ),

          // Comments listener - only updates comment counts
          BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
            listenWhen: (previous, current) =>
                current is GlobalCommentsDisplaySuccess,
            listener: (context, state) {
              if (state is GlobalCommentsDisplaySuccess) {
                setState(() {
                  for (final post in _stablePosts) {
                    final count = state.comments
                        .where((comment) => comment.posterId == post.id)
                        .length;
                    _commentCounts[post.id] = count;
                  }
                });
              }
            },
            child: const SizedBox.shrink(),
          ),

          // Success/Error message listener
          BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
            listener: (context, state) {
              if (state is GlobalLikeError) {
                // Revert optimistic update on error
                final postId = state.error.contains('post')
                    ? _pendingLikeUpdates.keys.lastOrNull
                    : null;
                if (postId != null) {
                  setState(() {
                    final currentLiked = _localLikeStates[postId] ?? false;
                    final currentCount = _localLikeCounts[postId] ?? 0;
                    _localLikeStates[postId] = !currentLiked;
                    _localLikeCounts[postId] =
                        currentLiked ? currentCount + 1 : currentCount - 1;
                    _pendingLikeUpdates.remove(postId);
                  });
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to like post: ${state.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is GlobalPostDeleteSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is GlobalPostDeleteFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete post: ${state.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is GlobalPostUpdateSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Caption updated successfully'),
                    backgroundColor: Colors.green,
                  ),
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
                // Revert optimistic bookmark update on error
                final postId = _pendingBookmarkUpdates.keys.lastOrNull;
                if (postId != null) {
                  setState(() {
                    final currentBookmarked =
                        _localBookmarkStates[postId] ?? false;
                    _localBookmarkStates[postId] = !currentBookmarked;
                    _pendingBookmarkUpdates.remove(postId);
                  });
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update bookmark: ${state.error}'),
                    backgroundColor: Colors.red,
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
            child: const SizedBox.shrink(),
          ),

          // Main content - stable post list
          Expanded(
            child: ListView.builder(
              itemCount: _stablePosts.length,
              itemBuilder: (context, index) {
                final post = _stablePosts[index];
                return _buildPostTile(post);
              },
            ),
          ),
        ],
      ),
    );
  }
}
