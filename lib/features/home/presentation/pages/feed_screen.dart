import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_comment_bottomsheet.dart';
import 'package:vandacoo/features/home/presentation/bloc/feeds_bloc/feeds_bloc.dart';

import '../../../../core/common/entities/user_entity.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    super.key,
    required this.user,
  });
  final UserEntity user;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    _loadFeedPosts();
  }

  void _loadFeedPosts() {
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;

    // Load both feed posts and comments
    context.read<GlobalCommentsBloc>().add(
          GetAllGlobalPostsEvent(
            userId: userId,
            isFeedsScreen: true,
            screenType: 'feed',
          ),
        );

    // Load all comments
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleLike(String postId) {
    final userId = widget.user.id;
    context.read<GlobalCommentsBloc>().add(
          GlobalToggleLikeEvent(
            postId: postId,
            userId: userId,
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

  void _handleComment(String postId, String posterUserName) {
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;

    // Fetch comments before showing bottom sheet
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());

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
    ).then((_) {
      // Refresh comments when bottom sheet is closed
      context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
    });
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

  void _handleUpdateCaption(String postId, String newCaption) {
    context.read<GlobalCommentsBloc>().add(
          UpdateGlobalPostCaptionEvent(
            postId: postId,
            caption: newCaption,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          "Advertisements",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Ads',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/payment',
                        arguments: {'user': widget.user},
                      );
                      if (result == true) {
                        final uploadResult =
                            await Navigator.pushNamed(context, '/upload-feeds');
                        // Refresh feed posts after returning from upload, regardless of upload result
                        _loadFeedPosts();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange.shade400
                              : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 20,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.orange.shade400
                                    : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Post Ad',
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.orange.shade400
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: MultiBlocListener(
                listeners: [
                  BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
                    listener: (context, state) {
                      if (state is GlobalPostDeleteSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Post deleted successfully')),
                        );
                        _loadFeedPosts();
                      } else if (state is GlobalPostUpdateSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Caption updated successfully')),
                        );
                        _loadFeedPosts();
                      } else if (state is GlobalPostReportSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Report submitted successfully')),
                        );
                      } else if (state is GlobalPostReportFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Failed to submit report: ${state.error}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else if (state is GlobalPostAlreadyReportedState) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('You have already reported this post')),
                        );
                      }
                    },
                  ),
                  BlocListener<FeedsBloc, FeedsState>(
                    listener: (context, state) {
                      if (state is FeedsPostSuccess) {
                        _loadFeedPosts(); // Refresh the feed
                      }
                    },
                  ),
                ],
                child: BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
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
                      return const Center(child: Text('Failed to load posts'));
                    }

                    if (state is GlobalPostsDisplaySuccess ||
                        state is GlobalPostsLoadingCache) {
                      final posts = (state is GlobalPostsDisplaySuccess)
                          ? state.posts
                          : (state as GlobalPostsLoadingCache).posts;

                      // Filter out expired posts
                      final activePosts = posts.where((post) {
                        if (post.isExpired) return false;
                        if (post.expiresAt == null) return true;
                        return DateTime.now().isBefore(post.expiresAt!);
                      }).toList();

                      if (activePosts.isEmpty) {
                        return const Center(
                          child: Text(
                            'No active advertisements',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: activePosts.length,
                        itemBuilder: (context, index) {
                          final post = activePosts[index];
                          return BlocBuilder<GlobalCommentsBloc,
                              GlobalCommentsState>(
                            buildWhen: (previous, current) {
                              return current is GlobalCommentsDisplaySuccess ||
                                  current is GlobalCommentsLoadingCache ||
                                  current is GlobalCommentsDeleteSuccess;
                            },
                            builder: (context, commentState) {
                              int commentCount = 0;
                              if (commentState
                                      is GlobalCommentsDisplaySuccess ||
                                  commentState is GlobalCommentsLoadingCache) {
                                final comments = (commentState
                                        is GlobalCommentsDisplaySuccess)
                                    ? commentState.comments
                                    : (commentState
                                            as GlobalCommentsLoadingCache)
                                        .comments;
                                commentCount = comments
                                    .where((comment) =>
                                        comment.posterId == post.id)
                                    .length;
                              }

                              return BlocBuilder<BookmarkCubit,
                                  Map<String, bool>>(
                                builder: (context, bookmarkState) {
                                  final isBookmarked =
                                      bookmarkState[post.id] ?? false;

                                  return GlobalCommentsPostTile(
                                    region: post.region,
                                    proPic: post.posterProPic?.trim() ?? '',
                                    name: post.user?.name ??
                                        post.posterName ??
                                        'Anonymous',
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
                                    onComment: () => _handleComment(
                                        post.id, post.posterName ?? ''),
                                    onBookmark: () => _handleBookmark(post.id),
                                    onDelete: () => _handleDelete(post.id),
                                    onReport: (reason, description) =>
                                        _handleReport(
                                            post.id, reason, description),
                                    onUpdateCaption: (newCaption) =>
                                        _handleUpdateCaption(
                                            post.id, newCaption),
                                    isCurrentUser: userId == post.userId,
                                    showBookmark: false,
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    }

                    return const Center(
                        child: Text('No advertisements available'));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
