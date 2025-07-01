import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_comment_bottomsheet.dart';
import 'package:vandacoo/features/home/presentation/bloc/feeds_bloc/feeds_bloc.dart';

import '../../../../core/common/entities/user_entity.dart';
import '../../../../core/common/entities/post_entity.dart';

class _FeedPostTileWrapper extends StatefulWidget {
  final PostEntity post;
  final int commentCount;
  final GlobalKey postKey;
  final UserEntity user;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final Function(String) onUpdateCaption;
  final VoidCallback onDelete;
  final Function(String, String?) onReport;
  final VoidCallback onBookmark;
  final VoidCallback onVideoPlay;
  final VoidCallback onVideoPause;

  const _FeedPostTileWrapper({
    super.key,
    required this.post,
    required this.commentCount,
    required this.postKey,
    required this.user,
    required this.onLike,
    required this.onComment,
    required this.onUpdateCaption,
    required this.onDelete,
    required this.onReport,
    required this.onBookmark,
    required this.onVideoPlay,
    required this.onVideoPause,
  });

  @override
  State<_FeedPostTileWrapper> createState() => _FeedPostTileWrapperState();
}

class _FeedPostTileWrapperState extends State<_FeedPostTileWrapper> {
  bool? _localBookmarkState;
  bool? _localLikeState;
  int? _localLikeCount;

  @override
  void initState() {
    super.initState();
    _localBookmarkState = null;
    _localLikeState = null;
    _localLikeCount = null;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BookmarkCubit, Map<String, bool>>(
          listenWhen: (previous, current) =>
              previous[widget.post.id] != current[widget.post.id],
          listener: (context, state) {
            // Reset local bookmark state when global state changes
            if (mounted) {
              setState(() {
                _localBookmarkState = null;
              });
            }
          },
        ),
        BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
          listenWhen: (previous, current) {
            if (current is GlobalPostsDisplaySuccess) {
              final updatedPost = current.posts
                  .where((p) => p.id == widget.post.id)
                  .firstOrNull;
              if (updatedPost != null) {
                return _localLikeState != null &&
                    (updatedPost.isLiked != widget.post.isLiked ||
                        updatedPost.likesCount != widget.post.likesCount);
              }
            }
            return false;
          },
          listener: (context, state) {
            // Reset local like state when global state changes
            if (mounted && state is GlobalPostsDisplaySuccess) {
              setState(() {
                _localLikeState = null;
                _localLikeCount = null;
              });
            }
          },
        ),
      ],
      child: BlocBuilder<BookmarkCubit, Map<String, bool>>(
        buildWhen: (previous, current) =>
            _localBookmarkState == null &&
            previous[widget.post.id] != current[widget.post.id],
        builder: (context, bookmarkState) {
          final isBookmarked =
              _localBookmarkState ?? (bookmarkState[widget.post.id] ?? false);
          final isLiked = _localLikeState ?? widget.post.isLiked;
          final likeCount = _localLikeCount ?? widget.post.likesCount;

          return GlobalCommentsPostTile(
            key: widget.postKey,
            region: widget.post.region,
            proPic: widget.post.posterProPic?.trim() ?? '',
            name:
                widget.post.user?.name ?? widget.post.posterName ?? 'Anonymous',
            postPic: widget.post.imageUrl?.trim() ?? '',
            description: widget.post.caption ?? '',
            id: widget.post.id,
            userId: widget.post.userId,
            videoUrl: widget.post.videoUrl?.trim(),
            createdAt: widget.post.createdAt,
            isLiked: isLiked,
            isBookmarked: isBookmarked,
            likeCount: likeCount,
            commentCount: widget.commentCount,
            onLike: () {
              setState(() {
                _localLikeState = !isLiked;
                _localLikeCount = isLiked ? likeCount - 1 : likeCount + 1;
              });
              widget.onLike();
            },
            onComment: widget.onComment,
            onBookmark: () {
              setState(() {
                _localBookmarkState = !isBookmarked;
              });
              widget.onBookmark();
            },
            onDelete: widget.onDelete,
            onReport: widget.onReport,
            onUpdateCaption: widget.onUpdateCaption,
            isCurrentUser: widget.user.id == widget.post.userId,
            showBookmark: false,
            onVideoPlay: widget.onVideoPlay,
            onVideoPause: widget.onVideoPause,
          );
        },
      ),
    );
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    super.key,
    required this.user,
  });
  final UserEntity user;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // Video management
  String? _currentPlayingVideoId;
  final Map<String, GlobalKey> _postKeys = {};

  @override
  void initState() {
    super.initState();
    _loadFeedPosts();
  }

  void _loadFeedPosts() {
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;

    // Load both feed posts and comments
    context.read<GlobalCommentsBloc>().add(
          GetAllGlobalPostsEvent(
            userId: userId,
            isFeedsScreen: true,
            screenType: 'feed',
          ),
        );

    // Load all comments
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleLike(String postId) {
    final userId = widget.user.id;
    context.read<GlobalCommentsBloc>().add(
          GlobalToggleLikeEvent(
            postId: postId,
            userId: userId,
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

  void _handleComment(String postId, String posterUserName) {
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;

    // Fetch comments before showing bottom sheet
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());

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
            userId: userId,
            posterUserName: posterUserName,
          ),
        ),
      ),
    ).then((_) {
      // Refresh comments when bottom sheet is closed
      context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
    });
  }

  void _handleDelete(String postId) {
    context.read<GlobalCommentsBloc>().add(
          DeleteGlobalPostEvent(
            postId: postId,
          ),
        );
  }

  void _handleReport(String postId, String reason, String? description) {
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
    context.read<GlobalCommentsBloc>().add(
          GlobalReportPostEvent(
            postId: postId,
            reporterId: userId,
            reason: reason,
            description: description,
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

  void _handleVideoPlay(String postId) {
    if (_currentPlayingVideoId != null && _currentPlayingVideoId != postId) {
      // Pause the currently playing video
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
      // Try to pause the video through the GlobalCommentsPostTile state
      final postTileState = key!.currentState as dynamic;
      if (postTileState != null && postTileState.mounted) {
        try {
          postTileState.pauseVideo();
        } catch (e) {
          // Handle case where pauseVideo method doesn't exist
        }
      }
    }
  }

  void _onPostVisibilityChanged(String postId, VisibilityInfo info) {
    if (info.visibleFraction < 0.5) {
      // Post is mostly out of view, pause if it's playing
      if (_currentPlayingVideoId == postId) {
        _pauseVideo(postId);
        _currentPlayingVideoId = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          "Advertisements",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Ads',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/payment',
                        arguments: {'user': widget.user},
                      );
                      if (result == true) {
                        final uploadResult =
                            await Navigator.pushNamed(context, '/upload-feeds');
                        // Refresh feed posts after returning from upload, regardless of upload result
                        _loadFeedPosts();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange.shade400
                              : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 20,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.orange.shade400
                                    : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Post Ad',
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.orange.shade400
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: MultiBlocListener(
                listeners: [
                  BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
                    listener: (context, state) {
                      if (state is GlobalPostDeleteSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Post deleted successfully')),
                        );
                        _loadFeedPosts();
                      } else if (state is GlobalPostUpdateSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Caption updated successfully')),
                        );
                        _loadFeedPosts();
                      } else if (state is GlobalPostReportSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Report submitted successfully')),
                        );
                      } else if (state is GlobalPostReportFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Failed to submit report: ${state.error}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else if (state is GlobalPostAlreadyReportedState) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('You have already reported this post')),
                        );
                      }
                    },
                  ),
                  BlocListener<FeedsBloc, FeedsState>(
                    listener: (context, state) {
                      if (state is FeedsPostSuccess) {
                        _loadFeedPosts(); // Refresh the feed
                      }
                    },
                  ),
                ],
                child: BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
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

                    if (state is GlobalPostsFailure) {
                      return const Center(child: Text('Failed to load posts'));
                    }

                    if (state is GlobalPostsDisplaySuccess ||
                        state is GlobalPostsLoadingCache) {
                      final posts = (state is GlobalPostsDisplaySuccess)
                          ? state.posts
                          : (state as GlobalPostsLoadingCache).posts;

                      // Filter out expired posts
                      final activePosts = posts.where((post) {
                        if (post.isExpired) return false;
                        if (post.expiresAt == null) return true;
                        return DateTime.now().isBefore(post.expiresAt!);
                      }).toList();

                      if (activePosts.isEmpty) {
                        return const Center(
                          child: Text(
                            'No active advertisements',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: activePosts.length,
                        itemBuilder: (context, index) {
                          final post = activePosts[index];
                          _postKeys[post.id] = GlobalKey();

                          return VisibilityDetector(
                            key: Key('feed_post_${post.id}'),
                            onVisibilityChanged: (info) =>
                                _onPostVisibilityChanged(post.id, info),
                            child: BlocBuilder<GlobalCommentsBloc,
                                GlobalCommentsState>(
                              buildWhen: (previous, current) {
                                return current
                                        is GlobalCommentsDisplaySuccess ||
                                    current is GlobalCommentsLoadingCache ||
                                    current is GlobalCommentsDeleteSuccess;
                              },
                              builder: (context, commentState) {
                                int commentCount = 0;
                                if (commentState
                                        is GlobalCommentsDisplaySuccess ||
                                    commentState
                                        is GlobalCommentsLoadingCache) {
                                  final comments = (commentState
                                          is GlobalCommentsDisplaySuccess)
                                      ? commentState.comments
                                      : (commentState
                                              as GlobalCommentsLoadingCache)
                                          .comments;
                                  commentCount = comments
                                      .where((comment) =>
                                          comment.posterId == post.id)
                                      .length;
                                }

                                return _FeedPostTileWrapper(
                                  key: ValueKey('feed_post_wrapper_${post.id}'),
                                  post: post,
                                  commentCount: commentCount,
                                  postKey: _postKeys[post.id]!,
                                  user: widget.user,
                                  onLike: () => _handleLike(post.id),
                                  onComment: () => _handleComment(
                                      post.id, post.posterName ?? ''),
                                  onUpdateCaption: (newCaption) =>
                                      _handleUpdateCaption(post.id, newCaption),
                                  onDelete: () => _handleDelete(post.id),
                                  onReport: (reason, description) =>
                                      _handleReport(
                                          post.id, reason, description),
                                  onBookmark: () => _handleBookmark(post.id),
                                  onVideoPlay: () => _handleVideoPlay(post.id),
                                  onVideoPause: () =>
                                      _handleVideoPause(post.id),
                                );
                              },
                            ),
                          );
                        },
                      );
                    }

                    return const Center(
                        child: Text('No advertisements available'));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
