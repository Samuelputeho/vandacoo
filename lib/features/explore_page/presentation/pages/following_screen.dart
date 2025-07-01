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

class FollowingScreen extends StatefulWidget {
  final List<PostEntity> stories;
  final Function(String) onStoryViewed;
  final UserEntity user;

  const FollowingScreen({
    super.key,
    required this.stories,
    required this.onStoryViewed,
    required this.user,
  });

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<PostEntity> _followedPosts = [];
  String? _lastLikedPostId;
  PostEntity? _lastLikedPost;
  String? _lastBookmarkedPostId;
  bool? _lastBookmarkState;

  // Video management
  String? _currentPlayingVideoId;
  final Map<String, GlobalKey> _postKeys = {};

  @override
  void initState() {
    super.initState();
    context.read<StoriesViewedCubit>().setCurrentUser(widget.user.id);
    _initializeViewedStories();
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
    context.read<FollowingBloc>().add(
          GetFollowingPostsEvent(userId: widget.user.id),
        );

    Future.microtask(() {
      if (mounted) {
        context.read<GlobalCommentsBloc>().add(
              GetAllGlobalPostsEvent(
                userId: widget.user.id,
                screenType: 'following',
              ),
            );
      }
    });
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

  void _handleLike(String postId) {
    PostEntity? post;
    try {
      post = _followedPosts.firstWhere((p) => p.id == postId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to like post: Post not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final originalLikeState = post.isLiked;
    final originalLikeCount = post.likesCount;

    setState(() {
      final index = _followedPosts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _followedPosts[index] = post!.copyWith(
          isLiked: !post.isLiked,
          likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
        );
      }
    });

    _lastLikedPostId = postId;
    _lastLikedPost = post.copyWith(
      isLiked: originalLikeState,
      likesCount: originalLikeCount,
    );

    context.read<GlobalCommentsBloc>().add(
          GlobalToggleLikeEvent(
            postId: postId,
            userId: widget.user.id,
          ),
        );
  }

  void _handleBookmark(String postId) {
    PostEntity? post;
    try {
      post = _followedPosts.firstWhere((p) => p.id == postId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to bookmark post: Post not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bookmarkCubit = context.read<BookmarkCubit>();
    final originalBookmarkState = bookmarkCubit.isPostBookmarked(postId);

    _lastBookmarkedPostId = postId;
    _lastBookmarkState = originalBookmarkState;

    bookmarkCubit.setBookmarkState(postId, !originalBookmarkState);

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
    context.read<GlobalCommentsBloc>().add(
          DeleteGlobalPostEvent(
            postId: storyId,
          ),
        );
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
    final region = stories[0].region;
    final allRegionStories = widget.stories
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
              widget.onStoryViewed(storyId);
            }
          },
          userId: widget.user.id,
          senderName: widget.user.name,
          onDelete: null,
        ),
      ),
    );
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
        } else if (state is FollowingLoadingCache) {
          setState(() {
            _followedPosts = state.posts;
          });
        }
      },
      builder: (context, state) {
        if (state is FollowingLoading && _followedPosts.isEmpty) {
          return const Center(child: Loader());
        }

        if (state is FollowingError && _followedPosts.isEmpty) {
          if (ErrorUtils.isNetworkError(state.message)) {
            return NetworkErrorWidget(onRetry: _retryLoadData);
          } else {
            return GenericErrorWidget(
              onRetry: _retryLoadData,
              message: 'Unable to load content',
            );
          }
        }

        if (_followedPosts.isEmpty) {
          return const Center(
            child: Text(''),
          );
        }

        return MultiBlocListener(
          listeners: [
            BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
              listener: (context, state) {
                if (state is GlobalLikeError) {
                  if (_lastLikedPostId != null && _lastLikedPost != null) {
                    setState(() {
                      final index = _followedPosts
                          .indexWhere((p) => p.id == _lastLikedPostId);
                      if (index != -1) {
                        _followedPosts[index] = _lastLikedPost!;
                      }
                    });
                    _lastLikedPostId = null;
                    _lastLikedPost = null;
                  }

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
                  if (_lastBookmarkedPostId != null &&
                      _lastBookmarkState != null) {
                    context.read<BookmarkCubit>().setBookmarkState(
                          _lastBookmarkedPostId!,
                          _lastBookmarkState!,
                        );
                    _lastBookmarkedPostId = null;
                    _lastBookmarkState = null;
                  }

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
                  _lastLikedPostId = null;
                  _lastLikedPost = null;
                  _lastBookmarkedPostId = null;
                  _lastBookmarkState = null;

                  final followedPosts = state.posts
                      .where((post) => post.isFromFollowed)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (followedPosts.isNotEmpty || _followedPosts.isEmpty) {
                    setState(() {
                      _followedPosts = followedPosts;
                    });
                  }

                  context
                      .read<GlobalCommentsBloc>()
                      .add(GetAllGlobalCommentsEvent());
                } else if (state is GlobalLikeSuccess ||
                    state is GlobalBookmarkSuccess) {
                  _lastLikedPostId = null;
                  _lastLikedPost = null;
                  _lastBookmarkedPostId = null;
                  _lastBookmarkState = null;
                } else if (state is GlobalPostDeleteSuccess) {
                  context.read<GlobalCommentsBloc>().add(
                        GetAllGlobalPostsEvent(
                          userId: widget.user.id,
                          screenType: 'following',
                        ),
                      );
                } else if (state is GlobalPostDeleteFailure) {
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
                } else if (state is GlobalPostUpdateSuccess) {
                  context.read<GlobalCommentsBloc>().add(
                        GetAllGlobalPostsEvent(
                          userId: widget.user.id,
                          screenType: 'following',
                        ),
                      );
                } else if (state is GlobalPostUpdateFailure) {
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
                } else if (state is GlobalPostReportSuccess) {
                  context.read<GlobalCommentsBloc>().add(
                        GetAllGlobalPostsEvent(
                          userId: widget.user.id,
                          screenType: 'following',
                        ),
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post reported successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (state is GlobalPostReportFailure) {
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
                } else if (state is GlobalPostAlreadyReportedState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have already reported this post'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else if (state is GlobalPostsFailure) {
                  if (ErrorUtils.isNetworkError(state.message)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.wifi_off, color: Colors.white),
                            SizedBox(width: 8),
                            Text('No internet connection'),
                          ],
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Failed to load posts: Unable to connect'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
          child: BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
            buildWhen: (previous, current) {
              return current is GlobalCommentsDisplaySuccess ||
                  current is GlobalCommentsLoadingCache ||
                  current is GlobalPostsDisplaySuccess;
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

                  if (state is GlobalCommentsDisplaySuccess ||
                      state is GlobalCommentsLoadingCache) {
                    final comments = (state is GlobalCommentsDisplaySuccess)
                        ? (state).comments
                        : (state as GlobalCommentsLoadingCache).comments;

                    commentCount = comments
                        .where((comment) => comment.posterId == post.id)
                        .length;
                  }

                  return _buildPostTile(post, commentCount);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPostTile(PostEntity post, int commentCount) {
    _postKeys[post.id] = GlobalKey();

    return VisibilityDetector(
      key: Key('following_post_${post.id}'),
      onVisibilityChanged: (info) => _onPostVisibilityChanged(post.id, info),
      child: BlocBuilder<BookmarkCubit, Map<String, bool>>(
        buildWhen: (previous, current) => previous[post.id] != current[post.id],
        builder: (context, bookmarkState) {
          return BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
            buildWhen: (previous, current) {
              if (current is GlobalPostsDisplaySuccess) {
                if (previous is GlobalPostsDisplaySuccess) {
                  try {
                    final prevPost =
                        previous.posts.firstWhere((p) => p.id == post.id);
                    final currPost =
                        current.posts.firstWhere((p) => p.id == post.id);
                    return prevPost.isLiked != currPost.isLiked ||
                        prevPost.likesCount != currPost.likesCount;
                  } catch (_) {
                    return false;
                  }
                }
                return true;
              }
              return current is GlobalLikeSuccess ||
                  current is GlobalBookmarkSuccess ||
                  current is GlobalPostsDisplaySuccess;
            },
            builder: (context, postState) {
              PostEntity currentPost = post;
              if (postState is GlobalPostsDisplaySuccess) {
                try {
                  currentPost = postState.posts.firstWhere(
                    (p) => p.id == post.id && p.isFromFollowed,
                  );
                } catch (e) {
                  // Post not found, use existing post
                }
              }

              return GlobalCommentsPostTile(
                key: _postKeys[post.id],
                region: currentPost.region,
                proPic: currentPost.posterProPic?.trim() ?? '',
                name: currentPost.user?.name ??
                    currentPost.posterName ??
                    'Anonymous',
                postPic: currentPost.imageUrl?.trim() ?? '',
                description: currentPost.caption ?? '',
                id: currentPost.id,
                userId: currentPost.userId,
                videoUrl: currentPost.videoUrl?.trim(),
                createdAt: currentPost.createdAt,
                isLiked: currentPost.isLiked,
                isBookmarked: bookmarkState[currentPost.id] ?? false,
                likeCount: currentPost.likesCount,
                commentCount: commentCount,
                onLike: () => _handleLike(currentPost.id),
                onComment: () => _handleComment(
                    currentPost.id, currentPost.posterName ?? 'Anonymous'),
                onBookmark: () => _handleBookmark(currentPost.id),
                onUpdateCaption: (newCaption) =>
                    _handleUpdateCaption(currentPost.id, newCaption),
                onDelete: () => _handleDelete(currentPost.id),
                onReport: (reason, description) =>
                    _handleReport(currentPost.id, reason, description),
                isCurrentUser: widget.user.id == currentPost.userId,
                onNameTap: () => _handleNameTap(currentPost),
                onVideoPlay: () => _handleVideoPlay(currentPost.id),
                onVideoPause: () => _handleVideoPause(currentPost.id),
              );
            },
          );
        },
      ),
    );
  }
}
