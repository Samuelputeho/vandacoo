import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/features/profile/presentation/pages/profile_comment_bottomsheet.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';

class ProfilePostListView extends StatefulWidget {
  final String userId;
  final List<PostEntity> userPosts;
  final PostEntity selectedPost;

  const ProfilePostListView({
    super.key,
    required this.userId,
    required this.userPosts,
    required this.selectedPost,
  });

  @override
  State<ProfilePostListView> createState() => _ProfilePostListViewState();
}

class _ProfilePostListViewState extends State<ProfilePostListView> {
  late List<PostEntity> _orderedPosts;

  @override
  void initState() {
    super.initState();
    _orderedPosts = _reorderPosts();
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
    context.read<GlobalCommentsBloc>().add(
          GetAllGlobalPostsEvent(userId: widget.userId),
        );
  }

  List<PostEntity> _reorderPosts() {
    final posts = List<PostEntity>.from(widget.userPosts);
    posts.removeWhere((post) => post.id == widget.selectedPost.id);
    return [widget.selectedPost, ...posts];
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
                  GetAllGlobalPostsEvent(userId: widget.userId),
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
                  GetAllGlobalPostsEvent(userId: widget.userId),
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
                  GetAllGlobalPostsEvent(userId: widget.userId),
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
          if (state is GlobalPostsLoading) {
            return const Center(child: Loader());
          }

          final displayPosts = (state is GlobalPostsDisplaySuccess)
              ? state.posts
                  .where((post) => widget.userPosts
                      .any((userPost) => userPost.id == post.id))
                  .toList()
              : _orderedPosts;

          if (displayPosts.isNotEmpty) {
            final selectedPostIndex = displayPosts
                .indexWhere((post) => post.id == widget.selectedPost.id);
            if (selectedPostIndex > 0) {
              final selectedPost = displayPosts.removeAt(selectedPostIndex);
              displayPosts.insert(0, selectedPost);
            }
          }

          return ListView.builder(
            itemCount: displayPosts.length,
            itemBuilder: (context, index) {
              final post = displayPosts[index];
              return BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
                buildWhen: (previous, current) {
                  return current is GlobalCommentsDisplaySuccess ||
                      current is GlobalCommentsLoadingCache;
                },
                builder: (context, commentState) {
                  int commentCount = 0;

                  if (commentState is GlobalCommentsDisplaySuccess ||
                      commentState is GlobalCommentsLoadingCache) {
                    final comments = (commentState
                            is GlobalCommentsDisplaySuccess)
                        ? commentState.comments
                        : (commentState as GlobalCommentsLoadingCache).comments;

                    commentCount = comments
                        .where((comment) => comment.posterId == post.id)
                        .length;
                  }

                  return BlocBuilder<BookmarkCubit, Map<String, bool>>(
                    builder: (context, bookmarkState) {
                      return GlobalCommentsPostTile(
                        proPic: post.posterProPic?.trim() ?? '',
                        name:
                            post.user?.name ?? post.posterName ?? 'Loading...',
                        postPic: post.imageUrl?.trim() ?? '',
                        description: post.caption ?? '',
                        id: post.id,
                        userId: post.userId,
                        videoUrl: post.videoUrl?.trim(),
                        createdAt: post.createdAt,
                        isLiked: post.isLiked,
                        isBookmarked: bookmarkState[post.id] ?? false,
                        likeCount: post.likesCount,
                        commentCount: commentCount,
                        onLike: () => _handleLike(post.id),
                        onComment: () => _handleComment(
                          post.id,
                          post.posterName ?? 'Loading...',
                        ),
                        onBookmark: () => _handleBookmark(post.id),
                        onUpdateCaption: (newCaption) =>
                            _handleUpdateCaption(post.id, newCaption),
                        onDelete: () => _handleDelete(post.id),
                        onReport: (reason, description) =>
                            _handleReport(post.id, reason, description),
                        isCurrentUser: widget.userId == post.userId,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
