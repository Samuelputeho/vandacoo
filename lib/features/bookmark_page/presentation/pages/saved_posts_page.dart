import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/core/constants/colors.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/features/bookmark_page/presentation/bloc/saved_posts_bloc/saved_posts_bloc.dart';
import 'package:vandacoo/features/bookmark_page/presentation/widgets/saved_post_tile.dart';
import 'package:vandacoo/features/likes/presentation/bloc/like_bloc.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/comments_bloc/comment_bloc.dart';
import 'package:vandacoo/features/bookmark_page/presentation/widgets/saved_post_comment_bottom_sheet.dart';

import '../bloc/saved_posts_bloc/saved_posts_event.dart';
import '../bloc/saved_posts_bloc/saved_posts_state.dart';

class SavedPostsPage extends StatefulWidget {
  final String userId;
  const SavedPostsPage({
    super.key,
    required this.userId,
  });

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SavedPostsBloc>().add(LoadSavedPostsEvent());
    context.read<CommentBloc>().add(GetAllCommentsEvent());
  }

  void _handleLike(String postId) {
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
    context.read<LikeBloc>().add(
          ToggleLikeEvent(
            postId: postId,
            userId: userId,
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
          value: context.read<CommentBloc>(),
          child: SavedPostCommentBottomSheet(
            postId: postId,
            userId: widget.userId,
            posterUserName: posterUserName,
          ),
        ),
      ),
    );
  }

  void _handleBookmark(String postId) {
    context.read<SavedPostsBloc>().add(
          ToggleSavedPostEvent(
            postId: postId,
            userId: widget.userId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Posts'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: BlocBuilder<SavedPostsBloc, SavedPostsState>(
        builder: (context, state) {
          if (state is SavedPostsLoading) {
            return const Center(child: Loader());
          }

          if (state is SavedPostsFailure) {
            return Center(child: Text(state.error));
          }

          if (state is SavedPostsSuccess) {
            if (state.posts.isEmpty) {
              return const Center(
                child: Text('No saved posts yet'),
              );
            }

            return ListView.builder(
              itemCount: state.posts.length,
              itemBuilder: (context, index) {
                final post = state.posts[index];
                return BlocBuilder<LikeBloc, Map<String, LikeState>>(
                  builder: (context, likeStates) {
                    final userId =
                        (context.read<AppUserCubit>().state as AppUserLoggedIn)
                            .user
                            .id;
                    final likeState = likeStates[post.id];
                    bool isLiked = false;
                    int likeCount = 0;

                    if (likeState is LikeSuccess) {
                      isLiked = likeState.likedByUsers.contains(userId);
                      likeCount = likeState.likedByUsers.length;
                    }

                    return BlocBuilder<CommentBloc, CommentState>(
                      builder: (context, commentState) {
                        int commentCount = 0;
                        if (commentState is CommentDisplaySuccess) {
                          final comments = commentState.comments
                              .where((comment) => comment.posterId == post.id)
                              .toList();
                          commentCount = comments.length;
                        }

                        return SavedPostTile(
                          proPic: (post.posterProPic ?? '').trim(),
                          name: post.posterName ?? 'Anonymous',
                          postPic: (post.imageUrl ?? '').trim(),
                          description: post.caption ?? '',
                          id: post.id,
                          userId: post.userId,
                          videoUrl: post.videoUrl?.trim(),
                          createdAt: post.createdAt,
                          isLiked: isLiked,
                          likeCount: likeCount,
                          commentCount: commentCount,
                          onLike: () => _handleLike(post.id),
                          onComment: () =>
                              _handleComment(post.id, post.posterName ?? ''),
                          isCurrentUser: userId == post.userId,
                          isBookmarked: context
                              .read<SavedPostsBloc>()
                              .isPostSaved(post.id),
                          onBookmark: () => _handleBookmark(post.id),
                        );
                      },
                    );
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
