import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/features/explore_page/presentation/widgets/post_tile.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/post_bloc/post_bloc.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/comments_bloc/comment_bloc.dart';
import 'package:vandacoo/features/likes/presentation/bloc/like_bloc.dart';
import 'package:vandacoo/features/explore_page/presentation/widgets/comment_bottom_sheet.dart';

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

  void _handleComment(
    String postId,
    String posterUserName,
  ) {
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
          value: context.read<CommentBloc>(),
          child: CommentBottomSheet(
            postId: postId,
            userId: userId,
            posterUserName: posterUserName,
          ),
        ),
      ),
    );
  }

  void _handleUpdateCaption(String postId, String newCaption) {
    context.read<PostBloc>().add(
          UpdatePostCaptionEvent(
            postId: postId,
            caption: newCaption,
          ),
        );
  }

  void _handleDelete(String postId) {
    context.read<PostBloc>().add(DeletePostEvent(postId: postId));
  }

  void _handleBookmark(String postId) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.category),
        backgroundColor: Colors.orange,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<PostBloc, PostState>(
            listener: (context, state) {
              if (state is PostDeleteSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is PostDeleteFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete post: ${state.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is PostUpdateCaptionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Caption updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is PostUpdateCaptionFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update caption: ${state.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<PostBloc, PostState>(
          builder: (context, state) {
            if (state is PostLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PostFailure) {
              return Center(child: Text(state.error));
            }

            if (state is PostDisplaySuccess) {
              final filteredPosts = state.posts
                  .where((post) =>
                      post.category.toLowerCase() ==
                      widget.category.toLowerCase())
                  .toList();

              if (filteredPosts.isEmpty) {
                return const Center(
                  child: Text(
                    'No posts yet in this category',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  final post = filteredPosts[index];
                  final userId =
                      (context.read<AppUserCubit>().state as AppUserLoggedIn)
                          .user
                          .id;

                  return BlocBuilder<LikeBloc, Map<String, LikeState>>(
                    builder: (context, likeStates) {
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

                          return PostTile(
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
                            onUpdateCaption: (newCaption) =>
                                _handleUpdateCaption(post.id, newCaption),
                            onDelete: () => _handleDelete(post.id),
                            isCurrentUser: userId == post.userId,
                            isBookmarked: post.isBookmarked,
                            onBookmark: () => _handleBookmark(post.id),
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
      ),
    );
  }
}
