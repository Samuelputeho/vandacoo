import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/entities/user_entity.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/common/entities/post_entity.dart';
import '../../../../core/utils/show_snackbar.dart';
import '../bloc/follow_bloc/follow_page_bloc.dart';
import '../bloc/follow_count_bloc/follow_count_bloc.dart';

class FollowPage extends StatefulWidget {
  final String userId;
  final String userName;
  final PostEntity userPost;
  final List<PostEntity> userEntirePosts;
  final UserEntity currentUser;

  const FollowPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userPost,
    required this.userEntirePosts,
    required this.currentUser,
  });

  @override
  State<FollowPage> createState() => _FollowPageState();
}

class _FollowPageState extends State<FollowPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  // ignore: unused_field
  bool _isLoading = true;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkFollowStatus();
    _loadUserCounts();
  }

  void _loadUserCounts() {
    context.read<FollowCountBloc>().add(
          GetUserCountsEvent(userId: widget.userPost.userId),
        );
  }

  Future<void> _checkFollowStatus() async {
    setState(() {
      _isLoading = true;
    });

    context.read<FollowPageBloc>().add(
          CheckIsFollowingEvent(
            followerId: widget.currentUser.id,
            followingId: widget.userPost.userId,
          ),
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleFollowTap() {
    if (_isFollowing) {
      context.read<FollowPageBloc>().add(
            UnfollowUserEvent(
              followerId: widget.currentUser.id,
              followingId: widget.userPost.userId,
            ),
          );
    } else {
      context.read<FollowPageBloc>().add(
            FollowUserEvent(
              followerId: widget.currentUser.id,
              followingId: widget.userPost.userId,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FollowPageBloc, FollowPageState>(
          listener: (context, state) {
            if (state is FollowPageError) {
              showSnackBar(context, state.message);
            } else if (state is FollowPageSuccess) {
              setState(() {
                _isFollowing = !_isFollowing;
                _isLoading = false;
              });
              _loadUserCounts();
            } else if (state is IsFollowingState) {
              setState(() {
                _isFollowing = state.isFollowing;
                _isLoading = false;
              });
            } else if (state is FollowPageLoadingCache) {
              setState(() {
                _isFollowing = state.isFollowing;
                _isLoading = false;
              });
            }
          },
        ),
        BlocListener<FollowCountBloc, FollowCountState>(
          listener: (context, state) {
            if (state is FollowCountError) {
              showSnackBar(context, state.message);
            } else if (state is FollowCountLoaded) {
              setState(() {
                _followersCount = state.followEntity.numberOfFollowers;
                _followingCount = state.followEntity.numberOfFollowing;
              });
            } else if (state is FollowCountLoadingCache) {
              setState(() {
                _followersCount = state.followEntity.numberOfFollowers;
                _followingCount = state.followEntity.numberOfFollowing;
              });
            }
          },
        ),
      ],
      child: Theme(
        data: Theme.of(context).copyWith(
          appBarTheme: Theme.of(context).appBarTheme.copyWith(
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
        ),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).iconTheme.color),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.userName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.more_vert,
                    color: Theme.of(context).iconTheme.color),
                onPressed: () {},
              ),
            ],
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                            ),
                            child: ClipOval(
                              child: (widget.userPost.user?.propic ?? '')
                                      .trim()
                                      .isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: widget.userPost.user!.propic,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => Container(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                        Icons.person,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                        size: 40,
                                      ),
                                    )
                                  : Container(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      child: Icon(
                                        Icons.person,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                        size: 40,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          widget.userName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Bio will be displayed here',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.7),
                                  ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: BlocBuilder<FollowCountBloc, FollowCountState>(
                          builder: (context, state) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatColumn(widget.userEntirePosts.length,
                                    'Posts', Theme.of(context)),
                                _buildStatColumn(_followersCount, 'Followers',
                                    Theme.of(context)),
                                _buildStatColumn(_followingCount, 'Following',
                                    Theme.of(context)),
                              ],
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            // Action Buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: BlocBuilder<FollowPageBloc,
                                        FollowPageState>(
                                      builder: (context, state) {
                                        final bool isLoading = state
                                                is FollowPageLoading &&
                                            state is! FollowPageLoadingCache;
                                        return ElevatedButton(
                                          onPressed: isLoading
                                              ? null
                                              : _handleFollowTap,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _isFollowing
                                                ? Colors.grey
                                                : AppColors.primaryColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                )
                                              : Text(_isFollowing
                                                  ? 'Following'
                                                  : 'Follow'),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/chat',
                                          arguments: {
                                            'currentUserId':
                                                widget.currentUser.id,
                                            'otherUserId':
                                                widget.userPost.userId,
                                            'otherUserName': widget.userName,
                                            'otherUserProPic':
                                                widget.userPost.user?.propic ??
                                                    '',
                                          },
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color:
                                                Theme.of(context).dividerColor),
                                        foregroundColor: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Chat'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primaryColor,
                      tabs: [
                        Tab(
                            icon: Icon(Icons.grid_on,
                                color: Theme.of(context).iconTheme.color)),
                        Tab(
                            icon: Icon(Icons.play_circle_outline,
                                color: Theme.of(context).iconTheme.color)),
                        Tab(
                            icon: Icon(Icons.person_pin_outlined,
                                color: Theme.of(context).iconTheme.color)),
                      ],
                    ),
                    Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Posts Grid
                GridView.builder(
                  padding: const EdgeInsets.all(1),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                  ),
                  itemCount: widget.userEntirePosts.length,
                  itemBuilder: (context, index) {
                    final post = widget.userEntirePosts[index];
                    final imageUrl = post.imageUrl;
                    final videoUrl = post.videoUrl;

                    // Show video thumbnail or image
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/follow-posts',
                          arguments: {
                            'userId': widget.userId,
                            'userPosts': widget.userEntirePosts,
                            'selectedPost': post,
                          },
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: (imageUrl ?? '').trim().isNotEmpty
                                ? imageUrl!
                                : 'https://example.com/dummy.jpg',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: Icon(
                                Icons.image,
                                color: Theme.of(context).iconTheme.color,
                                size: 40,
                              ),
                            ),
                          ),
                          if (videoUrl != null && videoUrl.isNotEmpty)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 24,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                // Videos Tab
                Builder(
                  builder: (context) {
                    final videoPosts = widget.userEntirePosts
                        .where((post) =>
                            post.videoUrl != null && post.videoUrl!.isNotEmpty)
                        .toList();

                    if (videoPosts.isEmpty) {
                      return Center(
                        child: Text(
                          'No videos available',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(1),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 1,
                      ),
                      itemCount: videoPosts.length,
                      itemBuilder: (context, index) {
                        final post = videoPosts[index];
                        final thumbnailUrl = post.imageUrl;

                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/follow-posts',
                              arguments: {
                                'userId': widget.userId,
                                'userPosts': widget.userEntirePosts,
                                'selectedPost': post,
                              },
                            );
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: (thumbnailUrl ?? '').trim().isNotEmpty
                                    ? thumbnailUrl!
                                    : 'https://via.placeholder.com/300',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  child: Icon(
                                    Icons.video_library,
                                    color: Theme.of(context).iconTheme.color,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.white,
                                  size: 24,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                // Tagged Tab (placeholder)
                Center(
                  child: Text(
                    'Tagged posts will appear here',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(int count, String label, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatNumber(count),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      double result = number / 1000000;
      // Format to 1 decimal place if it's not a whole number
      return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}m';
    } else if (number >= 1000) {
      double result = number / 1000;
      // Format to 1 decimal place if it's not a whole number
      return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}k';
    }
    return number.toString();
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
