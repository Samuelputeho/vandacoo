import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_comment_bottomsheet.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/post_bloc/post_bloc.dart';

import '../../../../core/constants/colors.dart';

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
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
    context.read<GlobalCommentsBloc>().add(
          GetAllGlobalPostsEvent(userId: userId, screenType: 'explore'),
        );
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

  @override
  Widget build(BuildContext context) {
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
    final currentUser =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.category, style: TextStyle(color: AppColors.backgroundColor, fontWeight: FontWeight.bold),),
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
            context.read<GlobalCommentsBloc>().add(
                  GetAllGlobalPostsEvent(userId: userId),
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
            context.read<GlobalCommentsBloc>().add(
                  GetAllGlobalPostsEvent(userId: userId),
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
                  GetAllGlobalPostsEvent(userId: userId),
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

            final filteredPosts = posts
                .where((post) =>
                    post.category.toLowerCase() ==
                    widget.category.toLowerCase())
                .toList();

            if (filteredPosts.isEmpty) {
              return const Center(
                child: Text(
                  'No posts yet in this category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
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
                    return BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
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
                            return GlobalCommentsPostTile(
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
                              region: post.region ?? '',
                              isLiked: post.isLiked,
                              isBookmarked: bookmarkState[post.id] ?? false,
                              likeCount: post.likesCount,
                              commentCount: commentCount,
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
                              isCurrentUser: userId == post.userId,
                              onNameTap: () {
                                if (userId == post.userId) {
                                  Navigator.pushNamed(
                                    context,
                                    '/profile',
                                    arguments: {
                                      'user': updatedUser,
                                    },
                                  );
                                } else {
                                  final userPosts = posts
                                      .where((p) => p.userId == post.userId)
                                      .toList();

                                  Navigator.pushNamed(
                                    context,
                                    '/follow',
                                    arguments: {
                                      'userId': userId,
                                      'userName': post.user?.name ??
                                          post.posterName ??
                                          'Anonymous',
                                      'userPost': post,
                                      'userEntirePosts': userPosts,
                                      'currentUser': updatedUser,
                                    },
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    );
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
