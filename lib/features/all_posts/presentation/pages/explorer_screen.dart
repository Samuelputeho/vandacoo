import 'package:flutter/material.dart';
import 'package:vandacoo/features/all_posts/presentation/widgets/post_tile.dart';
import 'package:vandacoo/features/all_posts/presentation/widgets/status_circle.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/features/all_posts/presentation/bloc/post_bloc.dart';
import 'package:vandacoo/features/all_posts/presentation/pages/story_view_screen.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/common/entities/post_entity.dart';

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
    // Get the initial state of viewed stories from the bloc
    final prefs = context.read<PostBloc>().viewedStories;
    setState(() {
      _viewedStories.addAll(prefs);
    });
    context.read<PostBloc>().add(GetAllPostsEvent(userId: widget.userId));
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

  List<PostEntity> _sortStories(List<PostEntity> stories) {
    final now = DateTime.now();
    // First filter active stories
    final activeStories = stories.where((story) {
      final age = now.difference(story.createdAt).inHours;
      return age <= 24;
    }).toList();

    // Group by user and take the latest story for each user
    final Map<String, PostEntity> latestUserStories = {};
    for (var story in activeStories) {
      final existingStory = latestUserStories[story.userId];
      if (existingStory == null ||
          story.createdAt.isAfter(existingStory.createdAt)) {
        latestUserStories[story.userId] = story;
      }
    }

    // Sort the unique user stories
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
      body: BlocConsumer<PostBloc, PostState>(
        listener: (context, state) {
          if (state is PostDisplaySuccess) {
            // Update viewed stories from the backend
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
            // Refresh the posts
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
            //get all posts
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
          }
        },
        builder: (context, state) {
          if (state is PostLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PostFailure) {
            return Center(child: Text(state.error));
          }

          if (state is PostDisplaySuccess) {
            // Get unique user stories (one circle per user)
            final uniqueUserStories = _sortStories(state.stories);

            return Column(
              children: [
                const SizedBox(height: 8),
                // Stories section
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.12,
                  child: uniqueUserStories.isEmpty
                      ? const Center(child: Text('No active stories'))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: uniqueUserStories.length,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          itemBuilder: (context, index) {
                            final userStory = uniqueUserStories[index];
                            // Get all stories for this user
                            final userStories = state.stories
                                .where((s) =>
                                    s.userId == userStory.userId &&
                                    DateTime.now()
                                            .difference(s.createdAt)
                                            .inHours <=
                                        24)
                                .toList()
                              ..sort(
                                  (a, b) => b.createdAt.compareTo(a.createdAt));

                            // Check if all stories are viewed
                            final allStoriesViewed = userStories.every(
                                (story) => _viewedStories.contains(story.id));

                            return StatusCircle(
                              story: userStory,
                              isViewed: allStoriesViewed,
                              onTap: () => _viewStory(userStories, 0),
                              totalStories: userStories.length,
                            );
                          },
                        ),
                ),
                const Divider(),
                // Posts section
                Expanded(
                  child: ListView.builder(
                    itemCount: state.posts.length,
                    addAutomaticKeepAlives: true,
                    itemBuilder: (context, index) {
                      final post = state.posts[index];
                      return PostTile(
                        proPic: post.posterProPic ?? '',
                        name: post.posterName ?? 'Anonymous',
                        postPic: post.imageUrl ?? '',
                        description: post.caption ?? '',
                        id: post.id,
                        posterId: post.userId,
                        videoUrl: post.videoUrl,
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('No posts available'));
        },
      ),
    );
  }
}
