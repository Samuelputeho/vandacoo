import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
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

class ExplorerScreen extends StatefulWidget {
  final UserEntity user;
  const ExplorerScreen({
    super.key,
    required this.user,
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Set current user for StoriesViewedCubit
    context.read<StoriesViewedCubit>().setCurrentUser(widget.user.id);

    // Initialize viewed stories from database
    _initializeViewedStories();

    _initializeExploreTab();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      if (_tabController.index == 0) {
        _initializeExploreTab();
      } else {
        Future.microtask(() {
          if (mounted) {
            context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
            _initializeFollowingTab();
          }
        });
      }
    }
  }

  void _initializeExploreTab() {
    Future.microtask(() {
      if (mounted) {
        context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
        context.read<GlobalCommentsBloc>().add(GetAllGlobalPostsEvent(
              userId: widget.user.id,
              screenType: 'explore',
            ));
      }
    });
  }

  void _initializeFollowingTab() {
    context
        .read<FollowingBloc>()
        .add(GetFollowingPostsEvent(userId: widget.user.id));

    Future.microtask(() {
      if (mounted) {
        context.read<GlobalCommentsBloc>().add(GetAllGlobalPostsEvent(
              userId: widget.user.id,
              screenType: 'following',
            ));
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
                setState(() {
                  _stories = state.stories;
                });
              } else if (state is GlobalLikeError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Failed to like post: ${state.error}'),
                      backgroundColor: Colors.red),
                );
              } else if (state is GlobalBookmarkSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Bookmark updated successfully'),
                      backgroundColor: Colors.green),
                );
              } else if (state is GlobalBookmarkFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Failed to update bookmark: ${state.error}'),
                      backgroundColor: Colors.red),
                );
                if (_tabController.index == 0) {
                  context.read<GlobalCommentsBloc>().add(GetAllGlobalPostsEvent(
                        userId: widget.user.id,
                        screenType: 'explore',
                      ));
                } else {
                  context.read<GlobalCommentsBloc>().add(GetAllGlobalPostsEvent(
                        userId: widget.user.id,
                        screenType: 'following',
                      ));
                }
              } else if (state is GlobalStoryViewFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to sync story view: ${state.error}'),
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
                _refreshCurrentTab();
              }
            },
          ),
        ],
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildExploreContent(),
            FollowingScreen(
              stories: _stories,
              onStoryViewed: _onStoryViewed,
              user: widget.user,
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
        return current is GlobalPostsLoading ||
            current is GlobalPostsFailure ||
            current is GlobalPostsDisplaySuccess ||
            current is GlobalPostsLoadingCache;
      },
      builder: (context, state) {
        List<PostEntity> displayPosts = [];

        if (state is GlobalPostsDisplaySuccess) {
          if (state.stories.isNotEmpty) {
            _stories = state.stories;
          }
          displayPosts = _filterExplorerPosts(state.posts)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        } else if (state is GlobalPostsLoadingCache) {
          displayPosts = _filterExplorerPosts(state.posts)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        if (displayPosts.isEmpty && state is GlobalPostsLoading) {
          return const Center(child: Loader());
        } else if (state is GlobalPostsFailure) {
          return const Center(child: Text('Failed to load posts'));
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
          return current is CommentDisplaySuccess ||
              current is CommentLoadingCache;
        },
        builder: (context, commentState) {
          int commentCount = 0;
          if (commentState is CommentDisplaySuccess ||
              commentState is CommentLoadingCache) {
            final comments = (commentState is CommentDisplaySuccess
                    ? commentState.comments
                    : (commentState as CommentLoadingCache).comments)
                .where((comment) => comment.posterId == post.id)
                .toList();
            commentCount = comments.length;
          }

          return BlocBuilder<BookmarkCubit, Map<String, bool>>(
            buildWhen: (previous, current) =>
                previous[post.id] != current[post.id],
            builder: (context, bookmarkState) {
              return PostTile(
                key: _postKeys[post.id],
                userPost: post,
                proPic: (post.posterProPic ?? '').trim(),
                name: post.user?.name ?? post.posterName ?? 'Anonymous',
                postPic: (post.imageUrl ?? '').trim(),
                description: post.caption ?? '',
                id: post.id,
                region: post.region,
                userId: post.userId,
                videoUrl: post.videoUrl?.trim(),
                createdAt: post.createdAt,
                isLiked: post.isLiked,
                likeCount: post.likesCount,
                commentCount: commentCount,
                onLike: () => _handleLike(post.id),
                onComment: () => _handleComment(post.id, post.posterName ?? ''),
                onUpdateCaption: (newCaption) =>
                    _handleUpdateCaption(post.id, newCaption),
                onDelete: () => _handleDelete(post.id),
                onReport: (reason, description) =>
                    _handleReport(post.id, reason, description),
                isCurrentUser: widget.user.id == post.userId,
                isBookmarked: bookmarkState[post.id] ?? false,
                onBookmark: () => _handleBookmark(post.id),
                onNameTap: () => _handleNameTap(post, displayPosts),
                onVideoPlay: () => _handleVideoPlay(post.id),
                onVideoPause: () => _handleVideoPause(post.id),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNameTap(PostEntity post, List<PostEntity> displayPosts) {
    if (widget.user.id == post.userId) {
      Navigator.pushNamed(
        context,
        '/profile',
        arguments: {'user': _updatedUserInfo ?? widget.user},
      ).then((_) => _initializeExploreTab());
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load viewed stories: $e'),
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
