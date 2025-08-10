import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_comment_bottomsheet.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/post_bloc/post_bloc.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';

import '../../../../core/constants/colors.dart';

class _HomePostTileWrapper extends StatefulWidget {
  final PostEntity post;
  final int commentCount;
  final String userId;
  final UserEntity currentUser;
  final List<PostEntity> allPosts;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final Function(String) onUpdateCaption;
  final VoidCallback onDelete;
  final Function(String, String?) onReport;
  final VoidCallback onBookmark;

  const _HomePostTileWrapper({
    required this.post,
    required this.commentCount,
    required this.userId,
    required this.currentUser,
    required this.allPosts,
    required this.onLike,
    required this.onComment,
    required this.onUpdateCaption,
    required this.onDelete,
    required this.onReport,
    required this.onBookmark,
  });

  @override
  State<_HomePostTileWrapper> createState() => _HomePostTileWrapperState();
}

class _HomePostTileWrapperState extends State<_HomePostTileWrapper> {
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
            proPic: widget.post.posterProPic?.trim() ?? '',
            name:
                widget.post.user?.name ?? widget.post.posterName ?? 'Anonymous',
            postPic: widget.post.imageUrl?.trim() ?? '',
            description: widget.post.caption ?? '',
            id: widget.post.id,
            userId: widget.post.userId,
            videoUrl: widget.post.videoUrl?.trim(),
            createdAt: widget.post.createdAt,
            region: widget.post.region ?? '',
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
            onNameTap: () {
              if (widget.userId == widget.post.userId) {
                Navigator.pushNamed(
                  context,
                  '/profile',
                  arguments: {
                    'user': widget.currentUser,
                  },
                );
              } else {
                final userPosts = widget.allPosts
                    .where((p) => p.userId == widget.post.userId)
                    .toList();

                Navigator.pushNamed(
                  context,
                  '/follow',
                  arguments: {
                    'userId': widget.userId,
                    'userName': widget.post.user?.name ??
                        widget.post.posterName ??
                        'Anonymous',
                    'userPost': widget.post,
                    'userEntirePosts': userPosts,
                    'currentUser': widget.currentUser,
                  },
                );
              }
            },
          );
        },
      ),
    );
  }
}

class PostAgainScreen extends StatefulWidget {
  final String category;

  const PostAgainScreen({required this.category, super.key});

  @override
  State<PostAgainScreen> createState() => _PostAgainScreenState();
}

class _PostAgainScreenState extends State<PostAgainScreen> {
  @override
  void initState() {
    super.initState();

    // Load comments first to ensure they're available when posts are displayed
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());

    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;

    // Load posts after a short delay to ensure comments are loaded first
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.read<GlobalCommentsBloc>().add(
              GetAllGlobalPostsEvent(userId: userId, screenType: 'explore'),
            );
      }
    });
    // Get current user information for profile navigation
  }

  void _handleLike(String postId) {
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
    context.read<GlobalCommentsBloc>().add(
          GlobalToggleLikeEvent(
            postId: postId,
            userId: userId,
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
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
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

  Widget _buildPostTile(
      PostEntity post, List<PostEntity> allPosts, UserEntity currentUser) {
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;

    return BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
      buildWhen: (previous, current) {
        return current is GlobalCommentsDisplaySuccess ||
            current is GlobalPostsAndCommentsSuccess;
      },
      builder: (context, commentState) {
        int commentCount = 0;

        if (commentState is GlobalCommentsDisplaySuccess) {
          final comments = commentState.comments
              .where((comment) => comment.posterId == post.id)
              .toList();
          commentCount = comments.length;
        } else if (commentState is GlobalPostsAndCommentsSuccess) {
          final comments = commentState.comments
              .where((comment) => comment.posterId == post.id)
              .toList();
          commentCount = comments.length;
        }

        return _HomePostTileWrapper(
          post: post,
          commentCount: commentCount,
          userId: userId,
          currentUser: currentUser,
          allPosts: allPosts,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
    final currentUser =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.category,
          style: TextStyle(
              color: AppColors.backgroundColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
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
                backgroundColor: AppColors.primaryColor,
              ),
            );
          }
        },
        buildWhen: (previous, current) {
          return current is GlobalPostsLoading ||
              current is GlobalPostsFailure ||
              current is GlobalPostsDisplaySuccess ||
              current is GlobalPostsAndCommentsSuccess;
        },
        builder: (context, state) {
          // Only show loading if we don't have data
          if (state is GlobalPostsLoading) {
            return const Center(child: Loader());
          }

          if (state is GlobalPostsFailure) {
            return const Center(child: Text('Failed to load posts'));
          }

          List<PostEntity> posts = [];
          if (state is GlobalPostsDisplaySuccess) {
            posts = state.posts;
          } else if (state is GlobalPostsAndCommentsSuccess) {
            posts = state.posts;
          }

          if (posts.isNotEmpty) {
            final filteredPosts = posts
                .where((post) =>
                    post.category.toLowerCase() ==
                    widget.category.toLowerCase())
                .toList();

            if (filteredPosts.isEmpty) {
              return const Center(
                child: Text(
                  'No posts yet in this category',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
              );
            }

            return BlocBuilder<PostBloc, PostState>(
              builder: (context, postState) {
                final updatedUser =
                    postState is GetCurrentUserInformationSuccess
                        ? postState.user
                        : currentUser;

                return ListView.builder(
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    final post = filteredPosts[index];
                    return _buildPostTile(post, posts, updatedUser);
                  },
                );
              },
            );
          }

          return const Center(child: Text('No posts available'));
        },
      ),
    );
  }
}
