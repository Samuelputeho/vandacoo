import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
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

  // Video management
  String? _currentPlayingVideoId;
  final Map<String, GlobalKey> _postKeys = {};

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

    // Load comments first to ensure they're available when posts are displayed
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());

    // Load posts after a short delay to ensure comments are loaded first
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.read<GlobalCommentsBloc>().add(
              GetAllGlobalPostsEvent(
                userId: widget.userId,
                screenType: widget.screenType,
              ),
            );
      }
    });
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
    print(
        '🔄 Profile Posts: _updatePosts called with ${updatedPosts.length} posts');

    // Create a map of updated posts for easy lookup
    final updatedPostsMap = {for (var post in updatedPosts) post.id: post};

    // Update local posts while preserving order
    final oldPostsCount = _localPosts.length;
    _localPosts = _localPosts.map((post) {
      final updatedPost = updatedPostsMap[post.id];
      if (updatedPost != null && updatedPost != post) {
        print(
            '🔄 Updating post ${post.id}: "${post.caption}" -> "${updatedPost.caption}"');
      }
      return updatedPost ?? post;
    }).toList();

    // Reorder posts with the updated data
    _orderedPosts = _reorderPosts();

    print(
        '🔄 Profile Posts: Updated ${oldPostsCount} local posts, now have ${_orderedPosts.length} ordered posts');

    // Clean up unused post keys
    final currentPostIds = _orderedPosts.map((post) => post.id).toSet();
    _postKeys.removeWhere((postId, key) => !currentPostIds.contains(postId));
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Posts'),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
            listener: (context, state) {
              if (state is GlobalCommentsDisplaySuccess) {
                _latestComments = state.comments;
              } else if (state is GlobalPostsDisplaySuccess) {
                print(
                    '🔄 Profile Posts: Received GlobalPostsDisplaySuccess with ${state.posts.length} posts');

                // Find matching posts from the state
                final updatedPosts = state.posts
                    .where((post) =>
                        _localPosts.any((localPost) => localPost.id == post.id))
                    .toList();

                print(
                    '🔄 Profile Posts: Found ${updatedPosts.length} matching posts to update');

                // Only update if we have posts and they've actually changed
                if (updatedPosts.isNotEmpty) {
                  // Check if posts have actually changed to avoid unnecessary setState
                  bool hasChanges = false;
                  for (final updatedPost in updatedPosts) {
                    final currentPost = _localPosts.firstWhere(
                      (p) => p.id == updatedPost.id,
                      orElse: () => updatedPost,
                    );

                    // Check if any important properties have changed
                    if (currentPost.likesCount != updatedPost.likesCount ||
                        currentPost.isLiked != updatedPost.isLiked ||
                        currentPost.caption != updatedPost.caption ||
                        currentPost.imageUrl != updatedPost.imageUrl ||
                        currentPost.videoUrl != updatedPost.videoUrl) {
                      print(
                          '🔄 Profile Posts: Detected changes in post ${updatedPost.id}');
                      print(
                          '   Caption: "${currentPost.caption}" -> "${updatedPost.caption}"');
                      print(
                          '   Likes: ${currentPost.likesCount} -> ${updatedPost.likesCount}');
                      print(
                          '   IsLiked: ${currentPost.isLiked} -> ${updatedPost.isLiked}');
                      hasChanges = true;
                      break;
                    }
                  }

                  if (hasChanges) {
                    print(
                        '🔄 Profile Posts: Updating posts and triggering setState');
                    setState(() {
                      _updatePosts(updatedPosts);
                    });
                  } else {
                    print(
                        '🔄 Profile Posts: No changes detected, skipping setState');
                  }
                }
              } else if (state is GlobalPostsAndCommentsSuccess) {
                print(
                    '🔄 Profile Posts: Received GlobalPostsAndCommentsSuccess with ${state.posts.length} posts');

                // Find matching posts from the state
                final updatedPosts = state.posts
                    .where((post) =>
                        _localPosts.any((localPost) => localPost.id == post.id))
                    .toList();

                print(
                    '🔄 Profile Posts: Found ${updatedPosts.length} matching posts to update');

                // Only update if we have posts and they've actually changed
                if (updatedPosts.isNotEmpty) {
                  // Check if posts have actually changed to avoid unnecessary setState
                  bool hasChanges = false;
                  for (final updatedPost in updatedPosts) {
                    final currentPost = _localPosts.firstWhere(
                      (p) => p.id == updatedPost.id,
                      orElse: () => updatedPost,
                    );

                    // Check if any important properties have changed
                    if (currentPost.likesCount != updatedPost.likesCount ||
                        currentPost.isLiked != updatedPost.isLiked ||
                        currentPost.caption != updatedPost.caption ||
                        currentPost.imageUrl != updatedPost.imageUrl ||
                        currentPost.videoUrl != updatedPost.videoUrl) {
                      print(
                          '🔄 Profile Posts: Detected changes in post ${updatedPost.id}');
                      print(
                          '   Caption: "${currentPost.caption}" -> "${updatedPost.caption}"');
                      hasChanges = true;
                      break;
                    }
                  }

                  if (hasChanges) {
                    print(
                        '🔄 Profile Posts: Updating posts and triggering setState');
                    setState(() {
                      _updatePosts(updatedPosts);
                    });
                  } else {
                    print(
                        '🔄 Profile Posts: No changes detected, skipping setState');
                  }
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Reload posts to show the updated changes
                context.read<GlobalCommentsBloc>().add(
                      GetAllGlobalPostsEvent(
                        userId: widget.userId,
                        screenType: widget.screenType,
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
          ),
        ],
        child: BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
          buildWhen: (previous, current) {
            // Always rebuild for loading and failure states
            if (current is GlobalPostsLoading ||
                current is GlobalPostsFailure) {
              return true;
            }

            // For success states, rebuild if we don't have posts yet
            if (current is GlobalPostsDisplaySuccess && _orderedPosts.isEmpty) {
              return true;
            }

            // Also rebuild if we have a post update success followed by new posts
            if (current is GlobalPostsDisplaySuccess &&
                previous is GlobalPostsLoading) {
              return true;
            }

            return false;
          },
          builder: (context, state) {
            return ListView.builder(
              itemCount: _orderedPosts.length,
              itemBuilder: (context, index) {
                final post = _orderedPosts[index];

                // Only create GlobalKey if it doesn't exist
                if (!_postKeys.containsKey(post.id)) {
                  _postKeys[post.id] = GlobalKey();
                }

                // Calculate comment count using latest comments
                return BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
                  buildWhen: (previous, current) {
                    return current is GlobalCommentsDisplaySuccess ||
                        current is GlobalPostsAndCommentsSuccess;
                  },
                  builder: (context, commentState) {
                    int commentCount = 0;
                    print(
                        '🧑‍💼 Profile post: Calculating comment count for post ${post.id}');
                    print('🧑‍💼 Comment state: ${commentState.runtimeType}');

                    if (commentState is GlobalCommentsDisplaySuccess) {
                      final comments = commentState.comments
                          .where((comment) => comment.posterId == post.id)
                          .toList();
                      commentCount = comments.length;
                      print(
                          '🧑‍💼 Post ${post.id}: Found ${commentCount} comments from ${commentState.comments.length} total comments (comments only state)');
                      if (commentCount > 0) {
                        print('🧑‍💼 Comment details for post ${post.id}:');
                        for (int i = 0; i < comments.length && i < 3; i++) {
                          print(
                              '   - Comment ${i + 1}: ${comments[i].comment}');
                        }
                      }
                    } else if (commentState is GlobalPostsAndCommentsSuccess) {
                      final comments = commentState.comments
                          .where((comment) => comment.posterId == post.id)
                          .toList();
                      commentCount = comments.length;
                      print(
                          '🧑‍💼 Post ${post.id}: Found ${commentCount} comments from ${commentState.comments.length} total comments (combined state)');
                      if (commentCount > 0) {
                        print('🧑‍💼 Comment details for post ${post.id}:');
                        for (int i = 0; i < comments.length && i < 3; i++) {
                          print(
                              '   - Comment ${i + 1}: ${comments[i].comment}');
                        }
                      }
                    } else {
                      print(
                          '🧑‍💼 Post ${post.id}: No comments state available');
                    }

                    return VisibilityDetector(
                      key: Key('profile_post_${post.id}'),
                      onVisibilityChanged: (info) =>
                          _onPostVisibilityChanged(post.id, info),
                      child: BlocBuilder<BookmarkCubit, Map<String, bool>>(
                        buildWhen: (previous, current) =>
                            previous[post.id] != current[post.id],
                        builder: (context, bookmarkState) {
                          final isBookmarked = bookmarkState[post.id] ?? false;

                          return GlobalCommentsPostTile(
                            key: _postKeys[post.id],
                            region: post.region,
                            proPic: post.posterProPic?.trim() ?? '',
                            name: post.user?.name ??
                                post.posterName ??
                                'Loading...',
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
                            onVideoPlay: () => _handleVideoPlay(post.id),
                            onVideoPause: () => _handleVideoPause(post.id),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
