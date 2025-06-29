import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
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
  late List<PostEntity> _orderedPosts;

  // Video management
  String? _currentPlayingVideoId;
  final Map<String, GlobalKey> _postKeys = {};

  @override
  void initState() {
    super.initState();
    print('FollowPageListView: initState called');
    print(
        'FollowPageListView: Initial posts count: ${widget.userPosts.length}');
    print('FollowPageListView: Selected post ID: ${widget.selectedPost.id}');

    // Reorder posts to show selected post first
    _orderedPosts = _reorderPosts();
    print('FollowPageListView: Reordered posts count: ${_orderedPosts.length}');

    // Initialize comments for all posts
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());

    // Use explore screenType to avoid following-specific filtering
    context.read<GlobalCommentsBloc>().add(
          GetAllGlobalPostsEvent(
            userId: widget.userId,
            screenType: 'explore',
          ),
        );
  }

  List<PostEntity> _reorderPosts() {
    print('FollowPageListView: Reordering posts');
    final posts = List<PostEntity>.from(widget.userPosts);
    posts.removeWhere((post) => post.id == widget.selectedPost.id);
    final orderedPosts = [widget.selectedPost, ...posts];
    print('FollowPageListView: Posts after reordering: ${orderedPosts.length}');
    print(
        'FollowPageListView: Posts categories: ${orderedPosts.map((p) => p.category).toSet()}');
    return orderedPosts;
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
          child: GlobalCommentBottomSheet(
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
                  GetAllGlobalPostsEvent(
                    userId: widget.userId,
                    screenType: 'explore',
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
            context.read<GlobalCommentsBloc>().add(
                  GetAllGlobalPostsEvent(
                    userId: widget.userId,
                    screenType: 'explore',
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
            context.read<GlobalCommentsBloc>().add(
                  GetAllGlobalPostsEvent(
                    userId: widget.userId,
                    screenType: 'explore',
                  ),
                );
          } else if (state is GlobalBookmarkFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update bookmark: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
            context.read<GlobalCommentsBloc>().add(
                  GetAllGlobalPostsEvent(
                    userId: widget.userId,
                    screenType: 'explore',
                  ),
                );
          } else if (state is GlobalPostReportSuccess) {
            context.read<GlobalCommentsBloc>().add(
                  GetAllGlobalPostsEvent(
                    userId: widget.userId,
                    screenType: 'explore',
                  ),
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
          print(
              'FollowPageListView: Building with state: ${state.runtimeType}');
          if (state is GlobalPostsLoading && _orderedPosts.isEmpty) {
            return const Center(child: Loader());
          }

          // Use the ordered posts if no GlobalPostsDisplaySuccess state
          final displayPosts = (state is GlobalPostsDisplaySuccess)
              ? state.posts
                  .where((post) => widget.userPosts
                      .any((userPost) => userPost.id == post.id))
                  .toList()
              : _orderedPosts;

          print(
              'FollowPageListView: Display posts count: ${displayPosts.length}');
          print(
              'FollowPageListView: Display posts categories: ${displayPosts.map((p) => p.category).toSet()}');

          // Always ensure the selected post is first in the list
          if (displayPosts.isNotEmpty) {
            final selectedPostIndex = displayPosts
                .indexWhere((post) => post.id == widget.selectedPost.id);
            if (selectedPostIndex > 0) {
              final selectedPost = displayPosts.removeAt(selectedPostIndex);
              displayPosts.insert(0, selectedPost);
              print('FollowPageListView: Reordered to put selected post first');
            }
          }

          return ListView.builder(
            itemCount: displayPosts.length,
            itemBuilder: (context, index) {
              final post = displayPosts[index];
              _postKeys[post.id] = GlobalKey();

              return VisibilityDetector(
                key: Key('follow_page_post_${post.id}'),
                onVisibilityChanged: (info) =>
                    _onPostVisibilityChanged(post.id, info),
                child: BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
                  buildWhen: (previous, current) {
                    return current is GlobalCommentsDisplaySuccess ||
                        current is GlobalCommentsLoadingCache;
                  },
                  builder: (context, commentState) {
                    int commentCount = 0;

                    if (commentState is GlobalCommentsDisplaySuccess ||
                        commentState is GlobalCommentsLoadingCache) {
                      final comments =
                          (commentState is GlobalCommentsDisplaySuccess)
                              ? commentState.comments
                              : (commentState as GlobalCommentsLoadingCache)
                                  .comments;

                      commentCount = comments
                          .where((comment) => comment.posterId == post.id)
                          .length;
                    }

                    return BlocBuilder<BookmarkCubit, Map<String, bool>>(
                      builder: (context, bookmarkState) {
                        return BlocBuilder<GlobalCommentsBloc,
                            GlobalCommentsState>(
                          buildWhen: (previous, current) {
                            if (previous is GlobalPostsDisplaySuccess &&
                                current is GlobalPostsDisplaySuccess) {
                              // Compare posts to check if likes have changed
                              for (var i = 0; i < previous.posts.length; i++) {
                                if (i >= current.posts.length) break;
                                if (previous.posts[i].isLiked !=
                                        current.posts[i].isLiked ||
                                    previous.posts[i].likesCount !=
                                        current.posts[i].likesCount) {
                                  return true;
                                }
                              }
                              return previous.posts.length !=
                                  current.posts.length;
                            }
                            return current is GlobalPostsDisplaySuccess ||
                                current is GlobalLikeSuccess;
                          },
                          builder: (context, postState) {
                            // Get the latest post data if available
                            PostEntity currentPost = post;
                            if (postState is GlobalPostsDisplaySuccess) {
                              try {
                                currentPost = postState.posts.firstWhere(
                                  (p) => p.id == post.id,
                                );
                              } catch (_) {
                                // If post not found in updated list, keep using the original post
                                currentPost = post;
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
                              isBookmarked:
                                  bookmarkState[currentPost.id] ?? false,
                              likeCount: currentPost.likesCount,
                              commentCount: commentCount,
                              onLike: () => _handleLike(currentPost.id),
                              onComment: () => _handleComment(
                                currentPost.id,
                                currentPost.posterName ?? 'Anonymous',
                              ),
                              onBookmark: () => _handleBookmark(currentPost.id),
                              onUpdateCaption: (newCaption) =>
                                  _handleUpdateCaption(
                                      currentPost.id, newCaption),
                              onDelete: () => _handleDelete(currentPost.id),
                              onReport: (reason, description) => _handleReport(
                                  currentPost.id, reason, description),
                              isCurrentUser:
                                  widget.userId == currentPost.userId,
                              onVideoPlay: () =>
                                  _handleVideoPlay(currentPost.id),
                              onVideoPause: () =>
                                  _handleVideoPause(currentPost.id),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
