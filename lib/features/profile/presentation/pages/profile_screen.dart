import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vandacoo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vandacoo/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/main.dart';

import '../../../../core/common/entities/user_entity.dart';
import '../../../../core/common/entities/post_entity.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/show_snackbar.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../../core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import '../bloc/get_user_info_bloc/profile_bloc.dart';

class ProfileScreen extends StatefulWidget {
  final UserEntity user;
  const ProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  bool _isPostsTabActive = true;
  late UserEntity _currentUser;
  bool _hasInitialData = false;
  List<PostEntity> _currentPosts = [];
  late final GlobalCommentsBloc _globalCommentsBloc;
  late final ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _globalCommentsBloc = context.read<GlobalCommentsBloc>();
    _profileBloc = context.read<ProfileBloc>();
    _initialLoad();
  }

  void _initialLoad() {
    _profileBloc.add(GetUserInfoEvent(userId: _currentUser.id));

    _globalCommentsBloc.add(GetAllGlobalCommentsEvent());
    _globalCommentsBloc.add(
      GetAllGlobalPostsEvent(
        userId: _currentUser.id,
        screenType: 'profile',
      ),
    );
  }

  void _loadAfterNavigation() {
    _profileBloc.add(GetUserInfoEvent(userId: _currentUser.id));

    _globalCommentsBloc.add(ClearGlobalPostsEvent());
    _globalCommentsBloc.add(GetAllGlobalCommentsEvent());
    _globalCommentsBloc.add(
      GetAllGlobalPostsEvent(
        userId: _currentUser.id,
        screenType: 'profile',
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    _loadAfterNavigation();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: IconThemeData(
          color: Theme.of(context).iconTheme.color,
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    userId: _currentUser.id,
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadAfterNavigation();
        },
        child: MultiBlocListener(
          listeners: [
            BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
              listener: (context, state) {
                if (state is GlobalPostsDisplaySuccess) {
                  setState(() {
                    _currentPosts = state.posts;
                    _hasInitialData = true;
                  });
                }
                if (state is GlobalPostsLoadingCache) {
                  setState(() {
                    _currentPosts = state.posts;
                    _hasInitialData = true;
                  });
                }
                if (state is GlobalPostsFailure) {
                  showSnackBar(context, state.message);
                }
              },
            ),
            BlocListener<ProfileBloc, ProfileState>(
              listener: (context, state) {
                if (state is ProfileUserLoaded) {
                  setState(() {
                    _currentUser = state.user;
                  });
                }
                if (state is ProfileLoadingCache) {
                  setState(() {
                    _currentUser = state.user;
                  });
                }
                if (state is ProfileError) {
                  showSnackBar(context, state.message);
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
              if (!_hasInitialData && state is GlobalPostsLoading) {
                return const Center(child: Loader());
              }

              if (state is GlobalPostsFailure) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      ElevatedButton(
                        onPressed: _loadAfterNavigation,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(isDarkMode),
                    const SizedBox(height: 24),
                    _buildStats(isDarkMode, _currentPosts),
                    const SizedBox(height: 24),
                    _buildTabSection(isDarkMode),
                    const SizedBox(height: 16),
                    _buildPostsGrid(context, _currentPosts, isDarkMode),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDarkMode) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _currentUser.propic.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _currentUser.propic,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            "assets/user1.jpeg",
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          "assets/user1.jpeg",
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentUser.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _currentUser.bio,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      currentName: _currentUser.name,
                      currentBio: _currentUser.bio,
                      currentEmail: _currentUser.email,
                      userId: _currentUser.id,
                      user: _currentUser,
                    ),
                  ),
                ).then((_) {
                  context.read<AuthBloc>().add(AuthIsUserLoggedIn());
                  _loadAfterNavigation();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                "Edit Profile",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostsGrid(
      BuildContext context, List<PostEntity> posts, bool isDarkMode) {
    return BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
      builder: (context, state) {
        return GridView.builder(
          padding: const EdgeInsets.all(1),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final imageUrl = post.imageUrl;
            final videoUrl = post.videoUrl;

            return GestureDetector(
              onTap: () {
                final currentState = context.read<GlobalCommentsBloc>().state;
                final currentPosts =
                    context.read<GlobalCommentsBloc>().currentPosts;
                final postExists = currentPosts.any((p) => p.id == post.id);

                if (!postExists) {
                  context.read<GlobalCommentsBloc>().add(GetAllGlobalPostsEvent(
                        userId: _currentUser.id,
                        screenType: 'profile',
                      ));
                  return;
                }

                final selectedPost =
                    currentPosts.firstWhere((p) => p.id == post.id);

                Navigator.pushNamed(
                  context,
                  '/profile-posts',
                  arguments: {
                    'userId': _currentUser.id,
                    'userPosts': currentPosts,
                    'selectedPost': selectedPost,
                    'screenType': 'profile',
                  },
                ).then((result) {
                  if (result == true) {
                    context
                        .read<GlobalCommentsBloc>()
                        .add(GetAllGlobalPostsEvent(
                          userId: _currentUser.id,
                          screenType: 'profile',
                        ));
                  }
                });
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
        );
      },
    );
  }

  Widget _buildStats(bool isDarkMode, List<PostEntity> posts) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Theme.of(context).cardColor
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(posts.length.toString(), "Posts", isDarkMode),
          Container(
            height: 40,
            width: 1,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          ),
          _buildStatItem(_currentUser.followers.length.toString(), "Followers",
              isDarkMode),
          Container(
            height: 40,
            width: 1,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          ),
          _buildStatItem(_currentUser.following.length.toString(), "Following",
              isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label, bool isDarkMode) {
    return Column(
      children: [
        Text(
          count,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildTabSection(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton("Posts", _isPostsTabActive, isDarkMode),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isPostsTabActive) {
                  setState(() {
                    _isPostsTabActive = false;
                  });
                  Navigator.pushNamed(
                    context,
                    '/feed',
                    arguments: {'user': _currentUser},
                  ).then((_) {
                    setState(() {
                      _isPostsTabActive = true;
                    });
                  });
                }
              },
              child:
                  _buildTabButton("Advertise", !_isPostsTabActive, isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isActive, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryColor
            : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isActive
                  ? Colors.white
                  : (isDarkMode ? Colors.grey[300] : Colors.grey[800]),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }
}

class FullScreenImagePage extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImagePage({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        itemCount: images.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.asset(
                images[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
