import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/features/explore_page/presentation/pages/comment_bottom_sheet.dart';
import 'package:vandacoo/features/bookmark_page/presentation/bloc/bloc/settings_bookmark_bloc.dart';

class BookMarkPage extends StatefulWidget {
  final String userId;

  const BookMarkPage({
    super.key,
    required this.userId,
  });

  @override
  State<BookMarkPage> createState() => _BookMarkPageState();
}

class _BookMarkPageState extends State<BookMarkPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<GlobalCommentsBloc>()
        .add(GetAllGlobalPostsEvent(userId: widget.userId));
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
    context
        .read<SettingsBookmarkBloc>()
        .add(SettingsLoadBookmarkedPostsEvent());
  }

  void _handleLike(String postId) {
    context.read<GlobalCommentsBloc>().add(
          GlobalToggleLikeEvent(
            postId: postId,
            userId: widget.userId,
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
          child: CommentBottomSheet(
            postId: postId,
            userId: widget.userId,
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

  void _handleBookmark(String postId) {
    // First, update the UI immediately through BookmarkCubit
    final bookmarkCubit = context.read<BookmarkCubit>();
    final isCurrentlyBookmarked = bookmarkCubit.isPostBookmarked(postId);
    bookmarkCubit.setBookmarkState(postId, !isCurrentlyBookmarked);

    // Then, make the API call through SettingsBookmarkBloc
    context.read<SettingsBookmarkBloc>().add(
          SettingsToggleBookmarkEvent(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
      ),
      body: BlocConsumer<GlobalCommentsBloc, GlobalCommentsState>(
        listener: (context, state) {
          if (state is GlobalPostUpdateSuccess) {
            context
                .read<GlobalCommentsBloc>()
                .add(GetAllGlobalPostsEvent(userId: widget.userId));
          } else if (state is GlobalPostDeleteSuccess) {
            context
                .read<GlobalCommentsBloc>()
                .add(GetAllGlobalPostsEvent(userId: widget.userId));
          } else if (state is GlobalPostReportSuccess) {
            context
                .read<GlobalCommentsBloc>()
                .add(GetAllGlobalPostsEvent(userId: widget.userId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post reported successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is GlobalPostReportFailure) {
            context
                .read<GlobalCommentsBloc>()
                .add(GetAllGlobalPostsEvent(userId: widget.userId));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to report post: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GlobalPostAlreadyReportedState) {
            context
                .read<GlobalCommentsBloc>()
                .add(GetAllGlobalPostsEvent(userId: widget.userId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You have already reported this post'),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (state is GlobalLikeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to like post: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GlobalLikeSuccess) {
            context
                .read<GlobalCommentsBloc>()
                .add(GetAllGlobalPostsEvent(userId: widget.userId));
          }
          // If comment added successfully, refresh comments
          if (state is GlobalCommentsDisplaySuccess) {
            context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
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

          if (state is GlobalPostsFailure) {
            return Center(child: Text(state.error));
          }

          if (state is GlobalPostsDisplaySuccess ||
              state is GlobalPostsLoadingCache) {
            final posts = (state is GlobalPostsDisplaySuccess)
                ? state.posts
                : (state as GlobalPostsLoadingCache).posts;

            return BlocListener<SettingsBookmarkBloc, SettingsBookmarkState>(
              listener: (context, bookmarkState) {
                if (bookmarkState is SettingsBookmarkSuccess) {
                  // Sync BookmarkCubit with the latest bookmark state
                  final bookmarkCubit = context.read<BookmarkCubit>();
                  for (final postId in bookmarkState.bookmarkedPostIds) {
                    bookmarkCubit.setBookmarkState(postId, true);
                  }
                  // Remove bookmarks that are no longer in the list
                  final currentBookmarks =
                      Map<String, bool>.from(bookmarkCubit.state);
                  for (final postId in currentBookmarks.keys) {
                    if (!bookmarkState.bookmarkedPostIds.contains(postId)) {
                      bookmarkCubit.setBookmarkState(postId, false);
                    }
                  }
                }
              },
              child: BlocBuilder<BookmarkCubit, Map<String, bool>>(
                builder: (context, bookmarkState) {
                  final bookmarkedPosts = posts
                      .where((post) => bookmarkState[post.id] ?? false)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (bookmarkedPosts.isEmpty) {
                    return const Center(
                      child: Text('No bookmarked posts yet'),
                    );
                  }

                  return ListView.builder(
                    itemCount: bookmarkedPosts.length,
                    itemBuilder: (context, index) {
                      final post = bookmarkedPosts[index];
                      final globalCommentsBloc =
                          context.read<GlobalCommentsBloc>();

                      return BlocBuilder<GlobalCommentsBloc,
                          GlobalCommentsState>(
                        buildWhen: (previous, current) {
                          return current is GlobalCommentsDisplaySuccess ||
                              current is GlobalCommentsLoadingCache;
                        },
                        builder: (context, commentState) {
                          int commentCount = 0;
                          if (commentState is GlobalCommentsDisplaySuccess ||
                              commentState is GlobalCommentsLoadingCache) {
                            final comments = (commentState
                                        is GlobalCommentsDisplaySuccess
                                    ? commentState.comments
                                    : (commentState
                                            as GlobalCommentsLoadingCache)
                                        .comments)
                                .where((comment) => comment.posterId == post.id)
                                .toList();
                            commentCount = comments.length;
                          }

                          return GlobalCommentsPostTile(
                            proPic: (post.posterProPic ?? '').trim(),
                            name: post.posterName ?? 'Anonymous',
                            postPic: (post.imageUrl ?? '').trim(),
                            description: post.caption ?? '',
                            id: post.id,
                            userId: post.userId,
                            videoUrl: post.videoUrl?.trim(),
                            createdAt: post.createdAt,
                            isLiked: post.isLiked,
                            likeCount: post.likesCount,
                            commentCount: commentCount,
                            onLike: () => _handleLike(post.id),
                            onComment: () =>
                                _handleComment(post.id, post.posterName ?? ''),
                            onUpdateCaption: (newCaption) =>
                                _handleUpdateCaption(post.id, newCaption),
                            onDelete: () => _handleDelete(post.id),
                            isCurrentUser: widget.userId == post.userId,
                            isBookmarked: bookmarkState[post.id] ?? false,
                            onBookmark: () => _handleBookmark(post.id),
                            onReport: (reason, description) =>
                                _handleReport(post.id, reason, description),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            );
          }

          return const Center(child: Text(''));
        },
      ),
    );
  }
}
