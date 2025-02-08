import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/core/common/global_comments/presentation/widgets/global_post_tile.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/post_bloc/post_bloc.dart';
import 'package:vandacoo/features/likes/presentation/bloc/like_bloc.dart';
import 'package:vandacoo/features/explore_page/presentation/pages/comment_bottom_sheet.dart';

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
    context.read<PostBloc>().add(GetAllPostsEvent(userId: widget.userId));
    context.read<GlobalCommentsBloc>().add(GetAllGlobalCommentsEvent());
  }

  void _handleLike(String postId) {
    context.read<LikeBloc>().add(
          ToggleLikeEvent(
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

  void _handleBookmark(String postId) {
    final bookmarkCubit = context.read<BookmarkCubit>();
    final isCurrentlyBookmarked = bookmarkCubit.isPostBookmarked(postId);

    // Update UI immediately through BookmarkCubit
    bookmarkCubit.setBookmarkState(postId, !isCurrentlyBookmarked);

    // Make the API call through PostBloc
    context.read<PostBloc>().add(
          ToggleBookmarkEvent(
            postId: postId,
            userId: widget.userId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
      ),
      body: BlocBuilder<PostBloc, PostState>(
        builder: (context, postState) {
          if (postState is PostLoading) {
            return const Center(child: Loader());
          }

          if (postState is PostFailure) {
            return Center(child: Text(postState.error));
          }

          if (postState is PostDisplaySuccess ||
              postState is PostLoadingCache) {
            final posts = (postState is PostDisplaySuccess)
                ? postState.posts
                : (postState as PostLoadingCache).posts;

            final bookmarkCubit = context.watch<BookmarkCubit>();
            final bookmarkedPosts = posts
                .where(
                  (post) => bookmarkCubit.isPostBookmarked(post.id),
                )
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

                return BlocBuilder<LikeBloc, Map<String, LikeState>>(
                  builder: (context, likeStates) {
                    final likeState = likeStates[post.id];
                    bool isLiked = false;
                    int likeCount = 0;

                    if (likeState is LikeSuccess) {
                      isLiked = likeState.likedByUsers.contains(widget.userId);
                      likeCount = likeState.likedByUsers.length;
                    }

                    return BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
                      builder: (context, commentState) {
                        int commentCount = 0;
                        if (commentState is GlobalCommentsDisplaySuccess ||
                            commentState is GlobalCommentsLoadingCache) {
                          final comments = (commentState
                                      is GlobalCommentsDisplaySuccess
                                  ? commentState.comments
                                  : (commentState as GlobalCommentsLoadingCache)
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
                          isLiked: isLiked,
                          likeCount: likeCount,
                          commentCount: commentCount,
                          onLike: () => _handleLike(post.id),
                          onComment: () =>
                              _handleComment(post.id, post.posterName ?? ''),
                          onUpdateCaption: (newCaption) =>
                              _handleUpdateCaption(post.id, newCaption),
                          onDelete: () => _handleDelete(post.id),
                          isCurrentUser: widget.userId == post.userId,
                          isBookmarked: bookmarkCubit.isPostBookmarked(post.id),
                          onBookmark: () => _handleBookmark(post.id),
                        );
                      },
                    );
                  },
                );
              },
            );
          }

          return const Center(child: Text(''));
        },
      ),
    );
  }
}
