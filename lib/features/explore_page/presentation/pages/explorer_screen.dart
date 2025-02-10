import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/core/constants/colors.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/post_bloc/post_bloc.dart';
import 'package:vandacoo/features/explore_page/presentation/widgets/post_tile.dart';
import 'package:vandacoo/features/explore_page/presentation/widgets/status_circle.dart';
import 'package:vandacoo/features/explore_page/presentation/pages/story_view_screen.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/comments_bloc/comment_bloc.dart';
import 'package:vandacoo/features/explore_page/presentation/pages/comment_bottom_sheet.dart';

class ExplorerScreen extends StatefulWidget {
  final String userId;
  const ExplorerScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  final Set<String> _viewedStories = {};

  @override
  void initState() {
    super.initState();
    final prefs = context.read<PostBloc>().viewedStories;
    setState(() {
      _viewedStories.addAll(prefs);
    });
    // Initial fetch of all data
    context.read<PostBloc>().add(GetAllPostsEvent(userId: widget.userId));
    context.read<CommentBloc>().add(GetAllCommentsEvent());
    context
        .read<GlobalCommentsBloc>()
        .add(GetAllGlobalPostsEvent(userId: widget.userId));
  }

  void _onStoryViewed(String storyId) {
    setState(() {
      _viewedStories.add(storyId);
    });

    context.read<PostBloc>().add(
          MarkStoryViewedEvent(
            storyId: storyId,
            viewerId: widget.userId,
          ),
        );
  }

  void _viewStory(List<PostEntity> stories, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewScreen(
          stories: stories,
          initialIndex: initialIndex,
          onStoryViewed: _onStoryViewed,
          userId: widget.userId,
        ),
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

  void _handleReport(String postId, String reason, String? description) {
    context.read<PostBloc>().add(
          ReportPostEvent(
            postId: postId,
            reporterId: widget.userId,
            reason: reason,
            description: description,
          ),
        );
  }

  void _handleBookmark(String postId) {
    // First, update the UI immediately through BookmarkCubit
    final bookmarkCubit = context.read<BookmarkCubit>();
    final isCurrentlyBookmarked = bookmarkCubit.isPostBookmarked(postId);
    bookmarkCubit.setBookmarkState(postId, !isCurrentlyBookmarked);

    // Make the API call through PostBloc
    context.read<PostBloc>().add(
          ToggleBookmarkEvent(
            postId: postId,
            userId: widget.userId,
          ),
        );
  }

  void _handleLike(String postId) {
    context.read<GlobalCommentsBloc>().add(
          GlobalToggleLikeEvent(
            postId: postId,
            userId: widget.userId,
          ),
        );
  }

  List<PostEntity> _sortStories(List<PostEntity> stories) {
    final now = DateTime.now();
    final activeStories = stories.where((story) {
      final age = now.difference(story.createdAt).inHours;
      return age <= 24;
    }).toList();

    final Map<String, PostEntity> latestUserStories = {};
    for (var story in activeStories) {
      final existingStory = latestUserStories[story.userId];
      if (existingStory == null ||
          story.createdAt.isAfter(existingStory.createdAt)) {
        latestUserStories[story.userId] = story;
      }
    }

    return latestUserStories.values.toList()
      ..sort((a, b) {
        if (_viewedStories.contains(a.id) && !_viewedStories.contains(b.id)) {
          return 1;
        }
        if (!_viewedStories.contains(a.id) && _viewedStories.contains(b.id)) {
          return -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Explore'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<PostBloc, PostState>(
            listener: (context, state) {
              if (state is PostDisplaySuccess) {
                final prefs = context.read<PostBloc>().viewedStories;
                setState(() {
                  _viewedStories.addAll(prefs);
                });
              } else if (state is PostDeleteSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                context
                    .read<PostBloc>()
                    .add(GetAllPostsEvent(userId: widget.userId));
              } else if (state is PostDeleteFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete post: ${state.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is PostUpdateCaptionSuccess) {
                context
                    .read<PostBloc>()
                    .add(GetAllPostsEvent(userId: widget.userId));
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
              } else if (state is PostBookmarkSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bookmark updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                context
                    .read<PostBloc>()
                    .add(GetAllPostsEvent(userId: widget.userId));
              } else if (state is PostBookmarkError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to bookmark post: ${state.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
                context
                    .read<PostBloc>()
                    .add(GetAllPostsEvent(userId: widget.userId));
              } else if (state is PostReportSuccess) {
                context
                    .read<PostBloc>()
                    .add(GetAllPostsEvent(userId: widget.userId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post reported successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is PostReportFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to report post: ${state.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
                context
                    .read<PostBloc>()
                    .add(GetAllPostsEvent(userId: widget.userId));
              }
              if (state is PostAlreadyReportedState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You have already reported this post'),
                    backgroundColor: Colors.orange,
                  ),
                );
                context
                    .read<PostBloc>()
                    .add(GetAllPostsEvent(userId: widget.userId));
              }
            },
          ),
          BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
            listener: (context, state) {
              if (state is GlobalLikeError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to like post: ${state.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is GlobalLikeSuccess ||
                  state is GlobalPostsDisplaySuccess) {
                // Refresh PostBloc data to keep it in sync
                context
                    .read<PostBloc>()
                    .add(GetAllPostsEvent(userId: widget.userId));
              }
            },
          ),
        ],
        child: BlocBuilder<PostBloc, PostState>(
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
              final stories = (postState is PostDisplaySuccess)
                  ? postState.stories
                  : (postState as PostLoadingCache).stories;

              final sortedPosts = List<PostEntity>.from(posts)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              return BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
                buildWhen: (previous, current) {
                  return current is GlobalPostsDisplaySuccess ||
                      current is GlobalLikeSuccess ||
                      current is GlobalLikeError;
                },
                builder: (context, globalState) {
                  // If we have updated posts from GlobalCommentsBloc, use those
                  final displayPosts =
                      (globalState is GlobalPostsDisplaySuccess)
                          ? globalState.posts
                          : sortedPosts;

                  // Get stories from GlobalCommentsBloc if available
                  final displayStories =
                      (globalState is GlobalPostsDisplaySuccess)
                          ? globalState.stories
                          : stories;

                  final uniqueUserStories = _sortStories(displayStories);

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.12,
                              child: uniqueUserStories.isEmpty
                                  ? const Center(
                                      child: Text('No active stories'))
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: uniqueUserStories.length,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      itemBuilder: (context, index) {
                                        final userStory =
                                            uniqueUserStories[index];
                                        final userStories = stories
                                            .where((s) =>
                                                s.userId == userStory.userId &&
                                                DateTime.now()
                                                        .difference(s.createdAt)
                                                        .inHours <=
                                                    24)
                                            .toList()
                                          ..sort((a, b) => b.createdAt
                                              .compareTo(a.createdAt));

                                        final allStoriesViewed = userStories
                                            .every((story) => _viewedStories
                                                .contains(story.id));

                                        return StatusCircle(
                                          story: userStory,
                                          isViewed: allStoriesViewed,
                                          onTap: () =>
                                              _viewStory(userStories, 0),
                                          totalStories: userStories.length,
                                        );
                                      },
                                    ),
                            ),
                            const Divider(),
                          ],
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = displayPosts[index];

                            return BlocBuilder<CommentBloc, CommentState>(
                              builder: (context, commentState) {
                                int commentCount = 0;
                                if (commentState is CommentDisplaySuccess ||
                                    commentState is CommentLoadingCache) {
                                  final comments =
                                      (commentState is CommentDisplaySuccess
                                              ? commentState.comments
                                              : (commentState
                                                      as CommentLoadingCache)
                                                  .comments)
                                          .where((comment) =>
                                              comment.posterId == post.id)
                                          .toList();
                                  commentCount = comments.length;
                                }

                                return BlocBuilder<BookmarkCubit,
                                    Map<String, bool>>(
                                  builder: (context, bookmarkState) {
                                    return PostTile(
                                      userPost: post,
                                      proPic: (post.posterProPic ?? '').trim(),
                                      name: post.user?.name ??
                                          post.posterName ??
                                          'Anonymous',
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
                                      onComment: () => _handleComment(
                                          post.id, post.posterName ?? ''),
                                      onUpdateCaption: (newCaption) =>
                                          _handleUpdateCaption(
                                              post.id, newCaption),
                                      onDelete: () => _handleDelete(post.id),
                                      onReport: (reason, description) =>
                                          _handleReport(
                                              post.id, reason, description),
                                      isCurrentUser:
                                          widget.userId == post.userId,
                                      isBookmarked:
                                          bookmarkState[post.id] ?? false,
                                      onBookmark: () =>
                                          _handleBookmark(post.id),
                                      onNameTap: () {
                                        // Filter posts to get all posts by this user
                                        final userPosts = displayPosts
                                            .where(
                                                (p) => p.userId == post.userId)
                                            .toList();

                                        Navigator.pushNamed(
                                          context,
                                          '/follow',
                                          arguments: {
                                            'userId': post.userId,
                                            'userName': post.user?.name ??
                                                post.posterName ??
                                                'Anonymous',
                                            'userPost': post,
                                            'userEntirePosts': userPosts,
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                          childCount: displayPosts.length,
                        ),
                      ),
                    ],
                  );
                },
              );
            }
            return const Center(child: Text(''));
          },
        ),
      ),
    );
  }
}
