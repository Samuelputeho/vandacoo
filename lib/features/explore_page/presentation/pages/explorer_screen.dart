import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/core/common/widgets/error_widgets.dart';
import 'package:vandacoo/core/constants/colors.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';
import 'package:vandacoo/core/common/cubits/stories_viewed/stories_viewed_cubit.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/features/explore_page/presentation/widgets/post_tile.dart';
import 'package:vandacoo/features/explore_page/presentation/widgets/status_circle.dart';
import 'package:vandacoo/features/explore_page/presentation/pages/story_view_screen.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/comments_bloc/comment_bloc.dart';
import 'package:vandacoo/features/explore_page/presentation/pages/comment_bottom_sheet.dart';
import 'package:vandacoo/features/explore_page/presentation/pages/following_screen.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/following_bloc/following_bloc.dart';

class _PostTileWrapper extends StatefulWidget {
  final PostEntity post;
  final int commentCount;
  final List<PostEntity> displayPosts;
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

  const _PostTileWrapper({
    super.key,
    required this.post,
    required this.commentCount,
    required this.displayPosts,
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
  State<_PostTileWrapper> createState() => _PostTileWrapperState();
}

class _PostTileWrapperState extends State<_PostTileWrapper> {
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

          return PostTile(
            key: widget.postKey,
            userPost: widget.post,
            proPic: (widget.post.posterProPic ?? '').trim(),
            name:
                widget.post.user?.name ?? widget.post.posterName ?? 'Anonymous',
            postPic: (widget.post.imageUrl ?? '').trim(),
            description: widget.post.caption ?? '',
            id: widget.post.id,
            region: widget.post.region,
            userId: widget.post.userId,
            videoUrl: widget.post.videoUrl?.trim(),
            createdAt: widget.post.createdAt,
            isLiked: isLiked,
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
            onUpdateCaption: widget.onUpdateCaption,
            onDelete: widget.onDelete,
            onReport: widget.onReport,
            isCurrentUser: widget.user.id == widget.post.userId,
            isBookmarked: isBookmarked,
            onBookmark: () {
              setState(() {
                _localBookmarkState = !isBookmarked;
              });
              widget.onBookmark();
            },
            onNameTap: widget.onNameTap,
            onVideoPlay: widget.onVideoPlay,
            onVideoPause: widget.onVideoPause,
          );
        },
      ),
    );
  }
}

class ExplorerScreen extends StatefulWidget {
  final UserEntity user;
  final VoidCallback? onNavigateToProfile;
  const ExplorerScreen({
    super.key,
    required this.user,
    this.onNavigateToProfile,
  });

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserEntity? _updatedUserInfo;
  List<PostEntity> _stories = [];

  // Video management
  String? _currentPlayingVideoId;
  final Map<String, GlobalKey> _postKeys = {};

  // Tab refresh management
  bool _forceShowLoader = false;
  bool _isInitializing = false;
  Timer? _initializationTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Set current user for StoriesViewedCubit
    context.read<StoriesViewedCubit>().setCurrentUser(widget.user.id);

    // Initialize viewed stories from database
    _initializeViewedStories();

    _initializeExploreTab(isInitialLoad: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _initializationTimer?.cancel();
    super.dispose();
  }

  void _handleTabTap(int index) {
    if (index == _tabController.index) {
      // Tapping the same tab - force refresh with loader
      _forceShowLoader = true;
      if (index == 0) {
        _initializeExploreTab(forceLoader: true);
      } else {
        _initializeFollowingTab(forceLoader: true);
      }
    } else {
      // Tapping a different tab - normal behavior
      _tabController.animateTo(index);
      if (index == 0) {
        _initializeExploreTab();
      } else {
        // Load comments first, then initialize following tab
        Future.microtask(() {
          if (mounted) {
            context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());

            // Initialize following tab after comments are loaded
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _initializeFollowingTab();
              }
            });
          }
        });
      }
    }
  }

  void _initializeExploreTab(
      {bool forceLoader = false, bool isInitialLoad = false}) {
    setState(() {
      _isInitializing = true;
      if (forceLoader) {
        _forceShowLoader = true;
      }
    });

    // Cancel any existing timer
    _initializationTimer?.cancel();

    // Set a timeout to reset initialization flag after 10 seconds
    _initializationTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isInitializing) {
        setState(() {
          _isInitializing = false;
        });
      }
    });

    // Only clear posts if this is not the initial load
    if (!isInitialLoad) {
      context.read<GlobalCommentsBloc>().add(ClearGlobalPostsEvent());
    }

    // Load comments first, then posts after a short delay
    Future.microtask(() {
      if (mounted) {
        print('🗺️ ExploreTab: Loading comments first...');
        context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());

        // Load posts after comments to ensure comment counts are available
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            print('🗺️ ExploreTab: Loading posts after 100ms delay...');
            context.read<GlobalCommentsBloc>().add(GetAllGlobalPostsEvent(
                  userId: widget.user.id,
                  screenType: 'explore',
                ));
          }
        });
      }
    });
  }

  void _initializeFollowingTab({bool forceLoader = false}) {
    setState(() {
      _isInitializing = true;
      if (forceLoader) {
        _forceShowLoader = true;
      }
    });

    // Clear any stale posts immediately
    context.read<GlobalCommentsBloc>().add(ClearGlobalPostsEvent());

    context
        .read<FollowingBloc>()
        .add(GetFollowingPostsEvent(userId: widget.user.id));

    // Load comments first, then posts after a short delay
    Future.microtask(() {
      if (mounted) {
        print('👥 FollowingTab: Loading comments first...');
        context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());

        // Load posts after comments to ensure comment counts are available
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            print('👥 FollowingTab: Loading posts after 100ms delay...');
            context.read<GlobalCommentsBloc>().add(GetAllGlobalPostsEvent(
                  userId: widget.user.id,
                  screenType: 'following',
                ));
          }
        });
      }
    });
  }

  void _onStoryViewed(String storyId) {
    context.read<StoriesViewedCubit>().markStoryAsViewed(storyId);
    context.read<GlobalCommentsBloc>().add(
          MarkStoryAsViewedEvent(
            storyId: storyId,
            userId: widget.user.id,
          ),
        );
  }

  void _handleStoryDelete(String storyId) {
    context
        .read<GlobalCommentsBloc>()
        .add(DeleteGlobalPostEvent(postId: storyId));
    context.read<StoriesViewedCubit>().removeStory(storyId);
    setState(() {
      _stories.removeWhere((story) => story.id == storyId);
    });
  }

  void _viewStory(List<PostEntity> stories, int initialIndex) {
    final region = stories[0].region;
    final allRegionStories = _stories
        .where((s) =>
            s.region == region &&
            DateTime.now().difference(s.createdAt).inHours <= 24)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewScreen(
          stories: allRegionStories,
          initialIndex: initialIndex,
          onStoryViewed: (String storyId) {
            if (!context.read<StoriesViewedCubit>().state.contains(storyId)) {
              _onStoryViewed(storyId);
            }
          },
          userId: widget.user.id,
          senderName: widget.user.name,
          onDelete: (String storyId) {
            if (allRegionStories
                .any((story) => story.userId == widget.user.id)) {
              _handleStoryDelete(storyId);
            }
          },
        ),
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
          value: context.read<CommentBloc>(),
          child: CommentBottomSheet(
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
    context
        .read<GlobalCommentsBloc>()
        .add(DeleteGlobalPostEvent(postId: postId));
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
    final isCurrentlyBookmarked = bookmarkCubit.isPostBookmarked(postId);
    bookmarkCubit.setBookmarkState(postId, !isCurrentlyBookmarked);
    context
        .read<GlobalCommentsBloc>()
        .add(ToggleGlobalBookmarkEvent(postId: postId));
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
    return regionRepresentatives
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
  }

  Widget _buildStoriesSection(List<PostEntity> stories) {
    if (stories.isEmpty) {
      return const SizedBox.shrink();
    }

    final uniqueRegionStories = _sortStories(stories);

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
                  final regionStories = stories
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        title: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: _handleTabTap,
          tabs: const [
            Tab(text: 'Explore'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
            listener: (context, state) {
              if (state is GlobalPostsDisplaySuccess) {
                final isExploreTab = _tabController.index == 0;
                final explorePostsExist =
                    _filterExplorerPosts(state.posts).isNotEmpty;
                final hasPosts = state.posts.isNotEmpty;

                setState(() {
                  _stories = state.stories;
                  _forceShowLoader = false; // Reset force loader flag

                  // Only reset initializing flag when we have meaningful data
                  if (isExploreTab) {
                    // For explore tab, reset only if we have explore posts OR we have posts but no explore posts (confirmed empty)
                    if (explorePostsExist || (hasPosts && !explorePostsExist)) {
                      _isInitializing = false;
                      _initializationTimer?.cancel(); // Cancel timeout timer
                    }
                    // Don't reset if state.posts is empty (might be from clear event)
                  } else {
                    // For following tab, always reset
                    _isInitializing = false;
                    _initializationTimer?.cancel(); // Cancel timeout timer
                  }
                });
              } else if (state is GlobalPostsAndCommentsSuccess) {
                final isExploreTab = _tabController.index == 0;
                final explorePostsExist =
                    _filterExplorerPosts(state.posts).isNotEmpty;
                final hasPosts = state.posts.isNotEmpty;

                setState(() {
                  _stories = state.stories;
                  _forceShowLoader = false; // Reset force loader flag

                  // Only reset initializing flag when we have meaningful data
                  if (isExploreTab) {
                    // For explore tab, reset only if we have explore posts OR we have posts but no explore posts (confirmed empty)
                    if (explorePostsExist || (hasPosts && !explorePostsExist)) {
                      _isInitializing = false;
                      _initializationTimer?.cancel(); // Cancel timeout timer
                    }
                    // Don't reset if state.posts is empty (might be from clear event)
                  } else {
                    // For following tab, always reset
                    _isInitializing = false;
                    _initializationTimer?.cancel(); // Cancel timeout timer
                  }
                });
              } else if (state is GlobalLikeError) {
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
                // No auto-refresh - let user manually refresh if needed
              } else if (state is GlobalStoryViewFailure) {
                final errorMessage = ErrorUtils.isNetworkError(state.error)
                    ? 'No internet connection'
                    : 'Failed to sync story view';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          ErrorUtils.isNetworkError(state.error)
                              ? Icons.wifi_off
                              : Icons.warning,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(errorMessage),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else if (state is GlobalPostDeleteSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Post deleted successfully'),
                      backgroundColor: Colors.green),
                );
                _refreshCurrentTab();
              } else if (state is GlobalPostUpdateSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Caption updated successfully'),
                      backgroundColor: Colors.green),
                );
                _refreshCurrentTab();
              } else if (state is GlobalPostReportSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Post reported successfully'),
                      backgroundColor: Colors.green),
                );
              }
            },
          ),
        ],
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(), // Disable swiping
          children: [
            _buildExploreContent(),
            FollowingScreen(
              stories: _stories,
              onStoryViewed: _onStoryViewed,
              user: widget.user,
              forceShowLoader: _forceShowLoader,
              onLoaderDisplayed: () {
                setState(() {
                  _forceShowLoader = false;
                  _isInitializing = false;
                });
                _initializationTimer?.cancel();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _refreshCurrentTab() {
    if (_tabController.index == 0) {
      _initializeExploreTab();
    } else {
      _initializeFollowingTab();
    }
  }

  List<PostEntity> _filterExplorerPosts(List<PostEntity> posts) {
    return posts
        .where((post) =>
            post.category != 'Feeds' &&
            post.postType == 'Post' &&
            !post.isFromFollowed)
        .toList();
  }

  Widget _buildExploreContent() {
    return BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
      buildWhen: (previous, current) {
        // Only rebuild for meaningful state changes
        if (previous.runtimeType == current.runtimeType) {
          // Same state type - check if content actually changed
          if (current is GlobalPostsDisplaySuccess &&
              previous is GlobalPostsDisplaySuccess) {
            final prevExplorePosts =
                previous.posts.where((p) => !p.isFromFollowed).length;
            final currExplorePosts =
                current.posts.where((p) => !p.isFromFollowed).length;
            final shouldBuild = prevExplorePosts != currExplorePosts;
            print(
                '💬 GlobalCommentsBloc buildWhen - Previous explore: $prevExplorePosts, Current explore: $currExplorePosts, Should build: $shouldBuild');
            return shouldBuild;
          }
          // For comment states, only rebuild if comments actually changed
          if (current is GlobalCommentsDisplaySuccess &&
              previous is GlobalCommentsDisplaySuccess) {
            final shouldBuild =
                previous.comments.length != current.comments.length;
            print(
                '💬 GlobalCommentsBloc buildWhen - Previous comments: ${previous.comments.length}, Current comments: ${current.comments.length}, Should build: $shouldBuild');
            return shouldBuild;
          }
          // For combined states, check both posts and comments
          if (current is GlobalPostsAndCommentsSuccess &&
              previous is GlobalPostsAndCommentsSuccess) {
            final prevExplorePosts =
                previous.posts.where((p) => !p.isFromFollowed).length;
            final currExplorePosts =
                current.posts.where((p) => !p.isFromFollowed).length;
            final shouldBuild = prevExplorePosts != currExplorePosts ||
                previous.comments.length != current.comments.length;
            print(
                '💬 GlobalCommentsBloc buildWhen - Combined state: Previous explore: $prevExplorePosts, Current explore: $currExplorePosts, Previous comments: ${previous.comments.length}, Current comments: ${current.comments.length}, Should build: $shouldBuild');
            return shouldBuild;
          }
          return false; // Same state type with no meaningful change
        }

        final shouldBuild = current is GlobalCommentsDisplaySuccess ||
            current is GlobalPostsDisplaySuccess ||
            current is GlobalPostsAndCommentsSuccess;
        print(
            '💬 GlobalCommentsBloc buildWhen - Previous: ${previous.runtimeType}, Current: ${current.runtimeType}, Should build: $shouldBuild');
        return shouldBuild;
      },
      builder: (context, state) {
        // Always show loading when initializing, posts are being fetched, or when forced
        if (_isInitializing ||
            state is GlobalPostsLoading ||
            _forceShowLoader) {
          return const Center(child: Loader());
        }

        if (state is GlobalPostsFailure) {
          // Reset initializing flag on error
          if (_isInitializing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isInitializing = false;
                });
                _initializationTimer?.cancel();
              }
            });
          }

          if (ErrorUtils.isNetworkError(state.message)) {
            return NetworkErrorWidget(
              onRetry: _initializeExploreTab,
              title: 'No Internet Connection',
              message: 'Please check your internet connection\nand try again',
            );
          } else {
            return GenericErrorWidget(
              onRetry: _initializeExploreTab,
              message: 'Unable to load explore posts',
            );
          }
        }

        if (state is GlobalPostsDisplaySuccess) {
          if (state.stories.isNotEmpty) {
            _stories = state.stories;
          }
          final displayPosts = _filterExplorerPosts(state.posts)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // If we're still initializing and this might not be explore posts, show loader
          if (_isInitializing &&
              displayPosts.isEmpty &&
              state.posts.isNotEmpty) {
            // We have posts but no explore posts - might be wrong posts, keep loading
            return const Center(child: Loader());
          }

          return _buildExplorePostsList(displayPosts);
        }

        if (state is GlobalPostsAndCommentsSuccess) {
          if (state.stories.isNotEmpty) {
            _stories = state.stories;
          }
          final displayPosts = _filterExplorerPosts(state.posts)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // If we're still initializing and this might not be explore posts, show loader
          if (_isInitializing &&
              displayPosts.isEmpty &&
              state.posts.isNotEmpty) {
            // We have posts but no explore posts - might be wrong posts, keep loading
            return const Center(child: Loader());
          }

          return _buildExplorePostsList(displayPosts);
        }

        // For any other state, show loader to prevent flashing
        return const Center(child: Loader());
      },
    );
  }

  Widget _buildExplorePostsList(List<PostEntity> displayPosts) {
    if (displayPosts.isEmpty) {
      return Column(
        children: [
          _buildStoriesSection(_stories),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.explore_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No posts to explore',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check back later for new content',
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
    }

    return ListView.builder(
      itemCount: displayPosts.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildStoriesSection(_stories);
        }

        final post = displayPosts[index - 1];
        return _buildPostTile(post, displayPosts);
      },
    );
  }

  Widget _buildPostTile(PostEntity post, List<PostEntity> displayPosts) {
    _postKeys[post.id] = GlobalKey();

    return VisibilityDetector(
      key: Key('post_${post.id}'),
      onVisibilityChanged: (info) => _onPostVisibilityChanged(post.id, info),
      child: BlocBuilder<CommentBloc, CommentState>(
        buildWhen: (previous, current) {
          if (previous is CommentDisplaySuccess &&
              current is CommentDisplaySuccess) {
            final prevCount =
                previous.comments.where((c) => c.posterId == post.id).length;
            final currCount =
                current.comments.where((c) => c.posterId == post.id).length;
            return prevCount != currCount;
          }
          return current is CommentDisplaySuccess;
        },
        builder: (context, commentState) {
          int commentCount = 0;
          if (commentState is CommentDisplaySuccess) {
            commentCount = commentState.comments
                .where((comment) => comment.posterId == post.id)
                .length;
          }

          return _PostTileWrapper(
            key: ValueKey('post_wrapper_${post.id}'),
            post: post,
            commentCount: commentCount,
            displayPosts: displayPosts,
            postKey: _postKeys[post.id]!,
            user: widget.user,
            onLike: () => _handleLike(post.id),
            onComment: () => _handleComment(post.id, post.posterName ?? ''),
            onUpdateCaption: (newCaption) =>
                _handleUpdateCaption(post.id, newCaption),
            onDelete: () => _handleDelete(post.id),
            onReport: (reason, description) =>
                _handleReport(post.id, reason, description),
            onBookmark: () => _handleBookmark(post.id),
            onNameTap: () => _handleNameTap(post, displayPosts),
            onVideoPlay: () => _handleVideoPlay(post.id),
            onVideoPause: () => _handleVideoPause(post.id),
          );
        },
      ),
    );
  }

  void _handleNameTap(PostEntity post, List<PostEntity> displayPosts) {
    if (widget.user.id == post.userId) {
      // Navigate to profile tab via bottom navigation
      if (widget.onNavigateToProfile != null) {
        widget.onNavigateToProfile!();
      } else {
        // Fallback to direct navigation if callback not provided
        Navigator.pushNamed(
          context,
          '/profile',
          arguments: {'user': _updatedUserInfo ?? widget.user},
        ).then((_) => _initializeExploreTab());
      }
    } else {
      final userPosts = displayPosts
          .where((p) => p.userId == post.userId && p.category != 'Feeds')
          .toList();
      Navigator.pushNamed(
        context,
        '/follow',
        arguments: {
          'userId': widget.user.id,
          'userName': post.user?.name ?? post.posterName ?? 'Anonymous',
          'userPost': post,
          'userEntirePosts': userPosts,
          'currentUser': _updatedUserInfo ?? widget.user,
        },
      ).then((_) => _initializeExploreTab());
    }
  }

  Future<void> _initializeViewedStories() async {
    try {
      final viewedStories = await context
          .read<GlobalCommentsBloc>()
          .getViewedStories(widget.user.id);

      context.read<StoriesViewedCubit>().initializeFromDatabase(viewedStories);
    } catch (e) {
      final errorMessage = ErrorUtils.isNetworkError(e.toString())
          ? 'No internet connection'
          : 'Failed to load viewed stories';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                ErrorUtils.isNetworkError(e.toString())
                    ? Icons.wifi_off
                    : Icons.warning,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(errorMessage),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
      // Try to pause the video through the PostTile state
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
}
