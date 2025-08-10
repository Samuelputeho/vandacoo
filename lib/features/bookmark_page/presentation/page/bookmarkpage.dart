import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/features/bookmark_page/presentation/page/bookmark_comment_bottomsheet.dart';
import 'package:vandacoo/features/bookmark_page/presentation/bloc/bloc/settings_bookmark_bloc.dart';
import 'package:vandacoo/core/common/widgets/error_widgets.dart';

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
  late final GlobalCommentsBloc _globalCommentsBloc;

  @override
  void initState() {
    super.initState();
    _loadBookmarkedPosts();
  }

  void _loadBookmarkedPosts() {
    final userId = widget.userId;

    // Load comments first to ensure they're available when posts are displayed
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());

    // Load posts after a short delay to ensure comments are loaded first
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.read<GlobalCommentsBloc>().add(
              GetAllGlobalPostsEvent(
                userId: userId,
                screenType: 'bookmarks',
              ),
            );
      }
    });
  }

  @override
  void dispose() {
    // Clear the explore posts when leaving bookmark page
    _globalCommentsBloc.add(ClearGlobalPostsEvent());
    super.dispose();
  }

  void _handleLike(String postId) {
    _globalCommentsBloc.add(
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
          value: _globalCommentsBloc,
          child: BookmarkCommentBottomSheet(
            postId: postId,
            userId: widget.userId,
            posterUserName: posterUserName,
          ),
        ),
      ),
    );
  }

  void _handleUpdateCaption(String postId, String newCaption) {
    _globalCommentsBloc.add(
      UpdateGlobalPostCaptionEvent(
        postId: postId,
        caption: newCaption,
      ),
    );
  }

  void _handleDelete(String postId) {
    _globalCommentsBloc.add(DeleteGlobalPostEvent(postId: postId));
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
    _globalCommentsBloc.add(
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
        title: Text('Bookmarks',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: BlocConsumer<GlobalCommentsBloc, GlobalCommentsState>(
        listener: (context, state) {
          if (state is GlobalPostUpdateSuccess) {
            _globalCommentsBloc.add(GetAllGlobalPostsEvent(
              userId: widget.userId,
              screenType: 'explore',
            ));
          } else if (state is GlobalPostDeleteSuccess) {
            _globalCommentsBloc.add(GetAllGlobalPostsEvent(
              userId: widget.userId,
              screenType: 'explore',
            ));
          } else if (state is GlobalPostReportSuccess) {
            _globalCommentsBloc.add(GetAllGlobalPostsEvent(
              userId: widget.userId,
              screenType: 'explore',
            ));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post reported successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is GlobalPostReportFailure) {
            _globalCommentsBloc.add(
              GetAllGlobalPostsEvent(
                userId: widget.userId,
                screenType: 'explore',
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to report post: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is GlobalPostAlreadyReportedState) {
            _globalCommentsBloc.add(GetAllGlobalPostsEvent(
              userId: widget.userId,
              screenType: 'explore',
            ));
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
            _globalCommentsBloc.add(
              GetAllGlobalPostsEvent(
                userId: widget.userId,
                screenType: 'explore',
              ),
            );
          }
        },
        buildWhen: (previous, current) {
          // Only rebuild for meaningful state changes
          if (previous.runtimeType == current.runtimeType) {
            // Same state type - check if content actually changed
            if (current is GlobalPostsDisplaySuccess &&
                previous is GlobalPostsDisplaySuccess) {
              final shouldBuild = previous.posts.length != current.posts.length;
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
              final shouldBuild =
                  previous.posts.length != current.posts.length ||
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
          if (state is GlobalPostsLoading) {
            return const Center(child: Loader());
          }

          if (state is GlobalPostsFailure) {
            if (ErrorUtils.isNetworkError(state.message)) {
              return NetworkErrorWidget(
                onRetry: _retryLoadData,
                title: 'No Internet Connection',
                message: 'Please check your internet connection\nand try again',
              );
            } else {
              return GenericErrorWidget(
                onRetry: _retryLoadData,
                message: 'Unable to load bookmarked posts',
              );
            }
          }

          return _buildBookmarkContent(state);
        },
      ),
    );
  }

  Widget _buildBookmarkContent(GlobalCommentsState state) {
    List<PostEntity> posts = [];

    if (state is GlobalPostsDisplaySuccess) {
      posts = state.posts;
    } else if (state is GlobalPostsAndCommentsSuccess) {
      posts = state.posts;
    } else {
      return const Center(child: Text(''));
    }

    return BlocListener<SettingsBookmarkBloc, SettingsBookmarkState>(
      listener: (context, bookmarkState) {
        if (bookmarkState is SettingsBookmarkSuccess) {
          // Sync BookmarkCubit with the latest bookmark state
          final bookmarkCubit = context.read<BookmarkCubit>();
          for (final postId in bookmarkState.bookmarkedPostIds) {
            bookmarkCubit.setBookmarkState(postId, true);
          }
          // Remove bookmarks that are no longer in the list
          final currentBookmarks = Map<String, bool>.from(bookmarkCubit.state);
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
              _globalCommentsBloc;

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
                    if (commentCount > 0) {}
                  } else if (commentState is GlobalPostsAndCommentsSuccess) {
                    final comments = commentState.comments
                        .where((comment) => comment.posterId == post.id)
                        .toList();
                    commentCount = comments.length;
                    if (commentCount > 0) {}
                  } else {}

                  return GlobalCommentsPostTile(
                    region: post.region,
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

  void _retryLoadData() {
    // Implement the logic to retry loading data
  }
}
