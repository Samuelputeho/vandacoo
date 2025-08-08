import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';
import 'package:vandacoo/core/common/cubits/stories_viewed/stories_viewed_cubit.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_comment_bottomsheet.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/core/common/widgets/error_widgets.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/following_bloc/following_bloc.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/features/explore_page/presentation/pages/story_view_screen.dart';
import 'package:vandacoo/features/explore_page/presentation/widgets/status_circle.dart';

class _FollowingPostTileWrapper extends StatefulWidget {
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
  final VoidCallback onNameTap;
  final VoidCallback onVideoPlay;
  final VoidCallback onVideoPause;

  const _FollowingPostTileWrapper({
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
    required this.onNameTap,
    required this.onVideoPlay,
    required this.onVideoPause,
  });

  @override
  State<_FollowingPostTileWrapper> createState() =>
      _FollowingPostTileWrapperState();
}

class _FollowingPostTileWrapperState extends State<_FollowingPostTileWrapper> {
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
            if (mounted) {
              setState(() {
                _localBookmarkState = null;
              });
            }
          },
        ),
        BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
          listenWhen: (previous, current) {
            if (current is GlobalPostsDisplaySuccess &&
                previous is GlobalPostsDisplaySuccess) {
              try {
                final prevPost = previous.posts.firstWhere(
                    (p) => p.id == widget.post.id && p.isFromFollowed);
                final currPost = current.posts.firstWhere(
                    (p) => p.id == widget.post.id && p.isFromFollowed);
                final shouldListen = _localLikeState != null &&
                    (prevPost.isLiked != currPost.isLiked ||
                        prevPost.likesCount != currPost.likesCount);
                return shouldListen;
              } catch (_) {
                return false;
              }
            }
            return false;
          },
          listener: (context, state) {
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
            onUpdateCaption: widget.onUpdateCaption,
            onDelete: widget.onDelete,
            onReport: widget.onReport,
            isCurrentUser: widget.user.id == widget.post.userId,
            onNameTap: widget.onNameTap,
            onVideoPlay: widget.onVideoPlay,
            onVideoPause: widget.onVideoPause,
          );
        },
      ),
    );
  }
}

class FollowingScreen extends StatefulWidget {
  final List<PostEntity> stories;
  final Function(String) onStoryViewed;
  final UserEntity user;
  final bool forceShowLoader;
  final VoidCallback onLoaderDisplayed;

  const FollowingScreen({
    super.key,
    required this.stories,
    required this.onStoryViewed,
    required this.user,
    required this.forceShowLoader,
    required this.onLoaderDisplayed,
  });

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<PostEntity> _followedPosts = [];
  bool _isOpeningStory = false;
  DateTime? _lastStoryNavAt;

  // Video management
  String? _currentPlayingVideoId;
  final Map<String, GlobalKey> _postKeys = {};

  // Notification deduplication
  String? _lastShownNotification;
  DateTime? _lastNotificationTime;

  @override
  void initState() {
    super.initState();
    _loadViewedStories();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadViewedStories() async {
    try {
      context.read<StoriesViewedCubit>().setCurrentUser(widget.user.id);
      final viewedStories = await context
          .read<GlobalCommentsBloc>()
          .getViewedStories(widget.user.id);
      context.read<StoriesViewedCubit>().initializeFromDatabase(viewedStories);
    } catch (e) {
      // Failed to load viewed stories
    }
  }

  void _showNotificationOnce(String message, Color backgroundColor) {
    final now = DateTime.now();

    // Only show if it's a different message or more than 2 seconds have passed
    if (_lastShownNotification != message ||
        _lastNotificationTime == null ||
        now.difference(_lastNotificationTime!).inSeconds > 2) {
      _lastShownNotification = message;
      _lastNotificationTime = now;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  Future<void> _initializeViewedStories() async {
    try {
      final viewedStories = await context
          .read<GlobalCommentsBloc>()
          .getViewedStories(widget.user.id);
    } catch (e) {
      // Failed to load viewed stories
    }
  }

  void _handleLike(String postId) {
    context.read<GlobalCommentsBloc>().add(
          GlobalToggleLikeEvent(
            postId: postId,
            userId: widget.user.id,
          ),
        );
  }

  void _handleBookmark(String postId) {
    final bookmarkCubit = context.read<BookmarkCubit>();
    final currentState = bookmarkCubit.isPostBookmarked(postId);
    bookmarkCubit.setBookmarkState(postId, !currentState);

    context.read<GlobalCommentsBloc>().add(
          ToggleGlobalBookmarkEvent(
            postId: postId,
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
          child: GlobalCommentBottomSheet(
            postId: postId,
            userId: widget.user.id,
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
          DeleteGlobalPostEvent(
            postId: postId,
          ),
        );
  }

  void _handleStoryDelete(String storyId) {
    setState(() {
      widget.stories.removeWhere((story) => story.id == storyId);
    });
  }

  void _handleReport(String postId, String reason, String? description) {
    context.read<GlobalCommentsBloc>().add(
          GlobalReportPostEvent(
            postId: postId,
            reporterId: widget.user.id,
            reason: reason,
            description: description,
          ),
        );
  }

  void _handleNameTap(PostEntity post) {
    if (widget.user.id == post.userId) {
      Navigator.pushNamed(
        context,
        '/profile',
        arguments: {
          'user': widget.user,
        },
      );
    } else {
      final userPosts =
          _followedPosts.where((p) => p.userId == post.userId).toList();

      Navigator.pushNamed(
        context,
        '/follow',
        arguments: {
          'userId': widget.user.id,
          'userName': post.user?.name ?? post.posterName ?? 'Anonymous',
          'userPost': post,
          'userEntirePosts': userPosts,
          'currentUser': widget.user,
        },
      );
    }
  }

  void _viewStory(List<PostEntity> stories, int initialIndex) {
    // Debounce to prevent double navigation
    final now = DateTime.now();
    if (_isOpeningStory ||
        (_lastStoryNavAt != null &&
            now.difference(_lastStoryNavAt!) <
                const Duration(milliseconds: 600))) {
      return;
    }
    _isOpeningStory = true;
    _lastStoryNavAt = now;

    if (!mounted || stories.isEmpty) {
      _isOpeningStory = false;
      return;
    }

    final region = stories[0].region;
    final allRegionStories = widget.stories
        .where((s) =>
            s.region == region &&
            DateTime.now().difference(s.createdAt).inHours <= 24)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (allRegionStories.isEmpty) {
      _isOpeningStory = false;
      return;
    }

    final safeIndex = initialIndex.clamp(0, allRegionStories.length - 1);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewScreen(
          stories: allRegionStories,
          initialIndex: safeIndex,
          onStoryViewed: (String storyId) {
            if (!context.read<StoriesViewedCubit>().state.contains(storyId)) {
              widget.onStoryViewed(storyId);
            }
          },
          userId: widget.user.id,
          senderName: widget.user.name,
          onDelete: null,
        ),
      ),
    ).whenComplete(() {
      _isOpeningStory = false;
    });
  }

  List<PostEntity> _sortStories(List<PostEntity> stories) {
    final now = DateTime.now();
    final activeStories = stories.where((story) {
      final age = now.difference(story.createdAt).inHours;
      return age <= 24;
    }).toList();

    final Map<String, List<PostEntity>> storiesByRegion = {};
    for (var story in activeStories) {
      if (!storiesByRegion.containsKey(story.region)) {
        storiesByRegion[story.region] = [];
      }
      storiesByRegion[story.region]!.add(story);
    }

    final List<PostEntity> regionRepresentatives =
        storiesByRegion.entries.map((entry) {
      final regionStories = entry.value;
      regionStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return regionStories.first;
    }).toList();

    final viewedStories = context.read<StoriesViewedCubit>().state;
    final sortedStories = regionRepresentatives
      ..sort((a, b) {
        final aRegionStories = storiesByRegion[a.region]!;
        final bRegionStories = storiesByRegion[b.region]!;

        final aAllViewed =
            aRegionStories.every((story) => viewedStories.contains(story.id));
        final bAllViewed =
            bRegionStories.every((story) => viewedStories.contains(story.id));

        if (aAllViewed && !bAllViewed) return 1;
        if (!aAllViewed && bAllViewed) return -1;
        return b.createdAt.compareTo(a.createdAt);
      });

    return sortedStories;
  }

  Widget _buildStoriesSection() {
    if (widget.stories.isEmpty) {
      return const SizedBox.shrink();
    }

    final uniqueRegionStories = _sortStories(widget.stories);

    if (uniqueRegionStories.isEmpty) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<StoriesViewedCubit, Set<String>>(
      builder: (context, viewedStories) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.12,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: uniqueRegionStories.length,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemBuilder: (context, index) {
                  final regionStory = uniqueRegionStories[index];
                  final regionStories = widget.stories
                      .where((s) =>
                          s.region == regionStory.region &&
                          DateTime.now().difference(s.createdAt).inHours <= 24)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  final allStoriesViewed = regionStories
                      .every((story) => viewedStories.contains(story.id));

                  return StatusCircle(
                    story: regionStory,
                    isViewed: allStoriesViewed,
                    onTap: () => _viewStory(regionStories, 0),
                    totalStories: regionStories.length,
                    displayRegion: true,
                  );
                },
              ),
            ),
            const Divider(),
          ],
        );
      },
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

  void _retryLoadData() {
    context.read<FollowingBloc>().add(
          GetFollowingPostsEvent(userId: widget.user.id),
        );
    context.read<GlobalCommentsBloc>().add(
          GetAllGlobalPostsEvent(
            userId: widget.user.id,
            screenType: 'following',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FollowingBloc, FollowingState>(
      listenWhen: (previous, current) {
        // Only listen to meaningful state changes
        if (previous.runtimeType == current.runtimeType) {
          // Same state type - check if content actually changed
          if (current is FollowingPostsLoaded &&
              previous is FollowingPostsLoaded) {
            final shouldListen = previous.posts.length != current.posts.length;
            return shouldListen;
          }
          return false; // Same state type, no meaningful change
        }
        return true; // Different state types, always listen
      },
      listener: (context, state) {
        if (state is FollowingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is FollowingPostsLoaded) {
          setState(() {
            _followedPosts = state.posts;
          });
        }
      },
      buildWhen: (previous, current) {
        // Only rebuild for state type changes or meaningful content changes
        if (previous.runtimeType == current.runtimeType) {
          if (current is FollowingPostsLoaded &&
              previous is FollowingPostsLoaded) {
            final shouldBuild = previous.posts.length != current.posts.length;
            return shouldBuild;
          }
          return false; // Same state type, no meaningful change
        }
        return true; // Different state types, always rebuild
      },
      builder: (context, state) {
        // Always show loading when data is being fetched or when forced
        if (state is FollowingLoading || widget.forceShowLoader) {
          if (widget.forceShowLoader) {
            // Call the callback to reset the flag in parent
            Future.microtask(() {
              widget.onLoaderDisplayed();
            });
          }
          return const Center(child: Loader());
        }

        if (state is FollowingError) {
          if (ErrorUtils.isNetworkError(state.message)) {
            return NetworkErrorWidget(
              onRetry: _retryLoadData,
              title: 'No Internet Connection',
              message: 'Please check your internet connection\nand try again',
            );
          } else {
            return GenericErrorWidget(
              onRetry: _retryLoadData,
              message: 'Unable to load following posts',
            );
          }
        }

        // Show proper content based on state
        return _buildFollowingContent(state);
      },
    );
  }

  Widget _buildFollowingContent(FollowingState state) {
    // If no posts available, check what to show
    if (_followedPosts.isEmpty) {
      // Show loader if we're still loading initially
      if (state is FollowingLoading) {
        return const Center(child: Loader());
      }

      // Show empty state if data has been loaded but no posts exist
      return BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
        builder: (context, globalState) {
          // If global posts are still loading, show loader
          if (globalState is GlobalPostsLoading) {
            return const Center(child: Loader());
          }

          // Handle global posts failure
          if (globalState is GlobalPostsFailure) {
            if (ErrorUtils.isNetworkError(globalState.message)) {
              return NetworkErrorWidget(
                onRetry: _retryLoadData,
                title: 'No Internet Connection',
                message:
                    'Unable to load posts from followed users\nPlease check your connection and try again',
              );
            } else {
              return GenericErrorWidget(
                onRetry: _retryLoadData,
                message: 'Unable to load posts from followed users',
              );
            }
          }

          // Show empty state
          return Column(
            children: [
              _buildStoriesSection(), // Always show stories section if available
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No posts from followed users',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Follow some users to see their posts here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
          listenWhen: (previous, current) {
            // Only listen for specific success/error states to prevent duplicates
            final shouldListen = current is GlobalLikeError ||
                current is GlobalBookmarkFailure ||
                current is GlobalPostsDisplaySuccess ||
                current is GlobalPostsAndCommentsSuccess ||
                current is GlobalPostDeleteSuccess ||
                current is GlobalPostUpdateSuccess ||
                current is GlobalPostReportSuccess ||
                current is GlobalBookmarkSuccess;

            return shouldListen;
          },
          listener: (context, state) {
            if (state is GlobalLikeError) {
              final errorMessage =
                  ErrorUtils.getNetworkErrorMessage(state.error);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        ErrorUtils.isNetworkError(state.error)
                            ? Icons.wifi_off
                            : Icons.error,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(errorMessage),
                    ],
                  ),
                  backgroundColor: ErrorUtils.isNetworkError(state.error)
                      ? Colors.orange
                      : Colors.red,
                ),
              );
            } else if (state is GlobalBookmarkFailure) {
              final errorMessage =
                  ErrorUtils.getNetworkErrorMessage(state.error);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        ErrorUtils.isNetworkError(state.error)
                            ? Icons.wifi_off
                            : Icons.error,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(errorMessage),
                    ],
                  ),
                  backgroundColor: ErrorUtils.isNetworkError(state.error)
                      ? Colors.orange
                      : Colors.red,
                ),
              );
            } else if (state is GlobalPostsDisplaySuccess) {
              final followedPosts = state.posts
                  .where((post) => post.isFromFollowed)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (followedPosts.isNotEmpty || _followedPosts.isEmpty) {
                setState(() {
                  _followedPosts = followedPosts;
                });
              }
            } else if (state is GlobalPostsAndCommentsSuccess) {
              final followedPosts = state.posts
                  .where((post) => post.isFromFollowed)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (followedPosts.isNotEmpty || _followedPosts.isEmpty) {
                setState(() {
                  _followedPosts = followedPosts;
                });
              }
            } else if (state is GlobalPostDeleteSuccess) {
              _showNotificationOnce('Post deleted successfully', Colors.green);
            } else if (state is GlobalPostUpdateSuccess) {
              _showNotificationOnce(
                  'Caption updated successfully', Colors.green);
            } else if (state is GlobalPostReportSuccess) {
              _showNotificationOnce('Post reported successfully', Colors.green);
            } else if (state is GlobalBookmarkSuccess) {
              _showNotificationOnce(
                  'Bookmark updated successfully', Colors.green);
            }
          },
        ),
      ],
      child: BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
        buildWhen: (previous, current) {
          // Only rebuild for meaningful state changes
          if (previous.runtimeType == current.runtimeType) {
            // Same state type - check if content actually changed
            if (current is GlobalPostsDisplaySuccess &&
                previous is GlobalPostsDisplaySuccess) {
              final prevFollowedPosts =
                  previous.posts.where((p) => p.isFromFollowed).length;
              final currFollowedPosts =
                  current.posts.where((p) => p.isFromFollowed).length;
              final shouldBuild = prevFollowedPosts != currFollowedPosts;
              return shouldBuild;
            }
            // For comment states, only rebuild if comments actually changed
            if (current is GlobalCommentsDisplaySuccess &&
                previous is GlobalCommentsDisplaySuccess) {
              final shouldBuild =
                  previous.comments.length != current.comments.length;
              return shouldBuild;
            }
            // For combined states, check both posts and comments
            if (current is GlobalPostsAndCommentsSuccess &&
                previous is GlobalPostsAndCommentsSuccess) {
              final prevFollowedPosts =
                  previous.posts.where((p) => p.isFromFollowed).length;
              final currFollowedPosts =
                  current.posts.where((p) => p.isFromFollowed).length;
              final shouldBuild = prevFollowedPosts != currFollowedPosts ||
                  previous.comments.length != current.comments.length;
              return shouldBuild;
            }
            return false; // Same state type with no meaningful change
          }

          final shouldBuild = current is GlobalCommentsDisplaySuccess ||
              current is GlobalPostsDisplaySuccess ||
              current is GlobalPostsAndCommentsSuccess;
          return shouldBuild;
        },
        builder: (context, state) {
          return ListView.builder(
            itemCount: _followedPosts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildStoriesSection();
              }

              final post = _followedPosts[index - 1];
              int commentCount = 0;

              // Handle different state types
              if (state is GlobalPostsAndCommentsSuccess) {
                final commentsForPost = state.comments
                    .where((comment) => comment.posterId == post.id)
                    .toList();
                commentCount = commentsForPost.length;
                if (commentCount > 0) {
                  for (int i = 0; i < commentsForPost.length && i < 3; i++) {}
                }
              } else if (state is GlobalCommentsDisplaySuccess) {
                final commentsForPost = state.comments
                    .where((comment) => comment.posterId == post.id)
                    .toList();
                commentCount = commentsForPost.length;
                if (commentCount > 0) {
                  for (int i = 0; i < commentsForPost.length && i < 3; i++) {}
                }
              }

              return _buildPostTile(post, commentCount);
            },
          );
        },
      ),
    );
  }

  Widget _buildPostTile(PostEntity post, int commentCount) {
    _postKeys[post.id] = GlobalKey();

    return VisibilityDetector(
      key: Key('following_post_${post.id}'),
      onVisibilityChanged: (info) => _onPostVisibilityChanged(post.id, info),
      child: _FollowingPostTileWrapper(
        key: ValueKey('following_post_wrapper_${post.id}'),
        post: post,
        commentCount: commentCount,
        postKey: _postKeys[post.id]!,
        user: widget.user,
        onLike: () => _handleLike(post.id),
        onComment: () =>
            _handleComment(post.id, post.posterName ?? 'Anonymous'),
        onUpdateCaption: (newCaption) =>
            _handleUpdateCaption(post.id, newCaption),
        onDelete: () => _handleDelete(post.id),
        onReport: (reason, description) =>
            _handleReport(post.id, reason, description),
        onBookmark: () => _handleBookmark(post.id),
        onNameTap: () => _handleNameTap(post),
        onVideoPlay: () => _handleVideoPlay(post.id),
        onVideoPause: () => _handleVideoPause(post.id),
      ),
    );
  }
}
