import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';

import '../../../../core/common/global_comments/presentation/widgets/global_comment_bottomsheet.dart';

class _FollowPagePostTileWrapper extends StatefulWidget {
  final PostEntity post;
  final int commentCount;
  final GlobalKey postKey;
  final String userId;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final Function(String) onUpdateCaption;
  final VoidCallback onDelete;
  final Function(String, String?) onReport;
  final VoidCallback onBookmark;
  final VoidCallback onVideoPlay;
  final VoidCallback onVideoPause;

  const _FollowPagePostTileWrapper({
    super.key,
    required this.post,
    required this.commentCount,
    required this.postKey,
    required this.userId,
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
  State<_FollowPagePostTileWrapper> createState() =>
      _FollowPagePostTileWrapperState();
}

class _FollowPagePostTileWrapperState
    extends State<_FollowPagePostTileWrapper> {
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
                final prevPost =
                    previous.posts.firstWhere((p) => p.id == widget.post.id);
                final currPost =
                    current.posts.firstWhere((p) => p.id == widget.post.id);
                return _localLikeState != null &&
                    (prevPost.isLiked != currPost.isLiked ||
                        prevPost.likesCount != currPost.likesCount);
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
            isCurrentUser: widget.userId == widget.post.userId,
            onVideoPlay: widget.onVideoPlay,
            onVideoPause: widget.onVideoPause,
          );
        },
      ),
    );
  }
}

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
    final bookmarkCubit = context.read<BookmarkCubit>();
    final currentState = bookmarkCubit.isPostBookmarked(postId);
    bookmarkCubit.setBookmarkState(postId, !currentState);

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

  Widget _buildPostTile(PostEntity post) {
    _postKeys[post.id] = GlobalKey();

    return VisibilityDetector(
      key: Key('follow_page_post_${post.id}'),
      onVisibilityChanged: (info) => _onPostVisibilityChanged(post.id, info),
      child: BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
        buildWhen: (previous, current) {
          return current is GlobalCommentsDisplaySuccess ||
              current is GlobalCommentsLoadingCache;
        },
        builder: (context, commentState) {
          int commentCount = 0;

          if (commentState is GlobalCommentsDisplaySuccess ||
              commentState is GlobalCommentsLoadingCache) {
            final comments = (commentState is GlobalCommentsDisplaySuccess)
                ? commentState.comments
                : (commentState as GlobalCommentsLoadingCache).comments;

            commentCount =
                comments.where((comment) => comment.posterId == post.id).length;
          }

          return _FollowPagePostTileWrapper(
            post: post,
            commentCount: commentCount,
            postKey: _postKeys[post.id]!,
            userId: widget.userId,
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
        buildWhen: (previous, current) {
          return current is GlobalPostsLoading ||
              current is GlobalPostsFailure ||
              current is GlobalPostsDisplaySuccess ||
              current is GlobalPostsLoadingCache;
        },
        builder: (context, state) {
          print(
              'FollowPageListView: Building with state: ${state.runtimeType}');

          // Only show loading if no cached data is available
          if (state is GlobalPostsLoading && _orderedPosts.isEmpty) {
            return const Center(child: Loader());
          }

          // Use the ordered posts if no GlobalPostsDisplaySuccess state, or show cached data immediately
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
              return _buildPostTile(post);
            },
          );
        },
      ),
    );
  }
}
