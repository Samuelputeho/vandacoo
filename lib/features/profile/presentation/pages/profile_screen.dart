import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vandacoo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vandacoo/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:vandacoo/features/profile/presentation/pages/profile_post_listview.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/core/common/widgets/error_widgets.dart';
import 'package:vandacoo/core/common/widgets/error_utils.dart';
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
    print('👤 ProfileScreen: initState called');
    _currentUser = widget.user;
    _globalCommentsBloc = context.read<GlobalCommentsBloc>();
    _profileBloc = context.read<ProfileBloc>();
    print(
        '👤 ProfileScreen: Initial user - ${_currentUser.name}, hasInitialData: $_hasInitialData');
    _initialLoad();
  }

  void _initialLoad() {
    print('👤 ProfileScreen: _initialLoad called');
    _profileBloc.add(GetUserInfoEvent(userId: _currentUser.id));
    print(
        '👤 ProfileScreen: Sent GetUserInfoEvent for user: ${_currentUser.id}');

    // Load comments first to ensure they're available when posts are displayed
    _globalCommentsBloc.add(GetAllGlobalCommentsEvent());
    print('👤 ProfileScreen: Sent GetAllGlobalCommentsEvent');

    // Load posts after a short delay to ensure comments are loaded first
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        print('👤 ProfileScreen: Sending GetAllGlobalPostsEvent after delay');
        _globalCommentsBloc.add(
          GetAllGlobalPostsEvent(
            userId: _currentUser.id,
            screenType: 'profile',
          ),
        );
      } else {
        print('👤 ProfileScreen: Widget not mounted, skipping post loading');
      }
    });
  }

  void _loadAfterNavigation() {
    print('👤 ProfileScreen: _loadAfterNavigation called');
    _profileBloc.add(GetUserInfoEvent(userId: _currentUser.id));
    print(
        '👤 ProfileScreen: Sent GetUserInfoEvent for user: ${_currentUser.id}');

    _globalCommentsBloc.add(ClearGlobalPostsEvent());
    print('👤 ProfileScreen: Sent ClearGlobalPostsEvent');

    // Load comments first to ensure they're available when posts are displayed
    _globalCommentsBloc.add(GetAllGlobalCommentsEvent());
    print('👤 ProfileScreen: Sent GetAllGlobalCommentsEvent');

    // Load posts after a short delay to ensure comments are loaded first
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        print('👤 ProfileScreen: Sending GetAllGlobalPostsEvent after delay');
        _globalCommentsBloc.add(
          GetAllGlobalPostsEvent(
            userId: _currentUser.id,
            screenType: 'profile',
          ),
        );
      } else {
        print('👤 ProfileScreen: Widget not mounted, skipping post loading');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    print('👤 ProfileScreen: didPopNext called - returning from navigation');
    _loadAfterNavigation();
  }

  @override
  Widget build(BuildContext context) {
    print(
        '👤 ProfileScreen: 🔄 build() called - Posts: ${_currentPosts.length}, hasData: $_hasInitialData');
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
          print('👤 ProfileScreen: RefreshIndicator onRefresh called');
          _loadAfterNavigation();
        },
        child: MultiBlocListener(
          listeners: [
            BlocListener<GlobalCommentsBloc, GlobalCommentsState>(
              listener: (context, state) {
                print(
                    '👤 ProfileScreen: GlobalCommentsBloc listener - State: ${state.runtimeType}');
                if (state is GlobalPostsDisplaySuccess) {
                  print(
                      '👤 ProfileScreen: GlobalPostsDisplaySuccess - Posts: ${state.posts.length}');
                  setState(() {
                    _currentPosts = state.posts;
                    _hasInitialData = true;
                  });
                  print(
                      '👤 ProfileScreen: ✅ Posts updated to: ${_currentPosts.length}');
                } else if (state is GlobalPostsAndCommentsSuccess) {
                  print(
                      '👤 ProfileScreen: GlobalPostsAndCommentsSuccess - Posts: ${state.posts.length}');
                  setState(() {
                    _currentPosts = state.posts;
                    _hasInitialData = true;
                  });
                  print(
                      '👤 ProfileScreen: ✅ Posts updated to: ${_currentPosts.length}');
                }
                if (state is GlobalPostsFailure) {
                  print(
                      '👤 ProfileScreen: GlobalPostsFailure - ${state.message}');
                  final message =
                      ErrorUtils.getNetworkErrorMessage(state.message);
                  showSnackBar(context, message);
                }
              },
            ),
            BlocListener<ProfileBloc, ProfileState>(
              listener: (context, state) {
                print('👤 ProfileScreen: ProfileBloc - ${state.runtimeType}');
                if (state is ProfileUserLoaded) {
                  setState(() {
                    _currentUser = state.user;
                  });
                  print(
                      '👤 ProfileScreen: 👤 User loaded: ${_currentUser.name}');
                }
                if (state is ProfileLoadingCache) {
                  setState(() {
                    _currentUser = state.user;
                  });
                  print(
                      '👤 ProfileScreen: 💾 User from cache: ${_currentUser.name}');
                }
                if (state is ProfileError) {
                  print('👤 ProfileScreen: ❌ ProfileError - ${state.message}');
                  final message =
                      ErrorUtils.getNetworkErrorMessage(state.message);
                  showSnackBar(context, message);
                }
              },
            ),
          ],
          child: BlocBuilder<GlobalCommentsBloc, GlobalCommentsState>(
            buildWhen: (previous, current) {
              // Always rebuild for loading and failure states
              if (current is GlobalPostsLoading ||
                  current is GlobalPostsFailure) {
                print(
                    '👤 ProfileScreen: BlocBuilder buildWhen - Previous: ${previous.runtimeType}, Current: ${current.runtimeType}, Should build: true (loading/failure)');
                return true;
              }

              // For success states, only rebuild if we're transitioning from no data to data OR post count changed
              if (current is GlobalPostsDisplaySuccess ||
                  current is GlobalPostsAndCommentsSuccess) {
                int currentPostCount = 0;
                int previousPostCount = 0;

                if (current is GlobalPostsDisplaySuccess) {
                  currentPostCount = current.posts.length;
                } else if (current is GlobalPostsAndCommentsSuccess) {
                  currentPostCount = current.posts.length;
                }

                if (previous is GlobalPostsDisplaySuccess) {
                  previousPostCount = previous.posts.length;
                } else if (previous is GlobalPostsAndCommentsSuccess) {
                  previousPostCount = previous.posts.length;
                }

                // Only rebuild if:
                // 1. We don't have initial data yet AND we now have data (first load)
                // 2. Post count actually changed (data update)
                final isFirstLoad = !_hasInitialData && currentPostCount > 0;
                final hasDataChanged =
                    _hasInitialData && previousPostCount != currentPostCount;
                final shouldBuild = isFirstLoad || hasDataChanged;

                print(
                    '👤 ProfileScreen: BlocBuilder buildWhen - Previous: $previousPostCount, Current: $currentPostCount, FirstLoad: $isFirstLoad, DataChanged: $hasDataChanged, Should build: $shouldBuild');
                return shouldBuild;
              }

              print(
                  '👤 ProfileScreen: BlocBuilder buildWhen - Previous: ${previous.runtimeType}, Current: ${current.runtimeType}, Should build: false (no match)');
              return false;
            },
            builder: (context, state) {
              print(
                  '👤 ProfileScreen: 🎨 Building UI - State: ${state.runtimeType}, Posts: ${_currentPosts.length}');

              // Show loader if we don't have initial data OR if we're currently loading
              if (!_hasInitialData || state is GlobalPostsLoading) {
                print(
                    '👤 ProfileScreen: ⏳ Showing loader - hasData: $_hasInitialData, isLoading: ${state is GlobalPostsLoading}');
                return const Center(child: Loader());
              }

              if (state is GlobalPostsFailure) {
                print('👤 ProfileScreen: ❌ Showing error - ${state.message}');
                if (ErrorUtils.isNetworkError(state.message)) {
                  return NetworkErrorWidget(onRetry: _loadAfterNavigation);
                } else {
                  return GenericErrorWidget(
                    onRetry: _loadAfterNavigation,
                    message: 'Unable to load profile',
                  );
                }
              }

              print('👤 ProfileScreen: ✅ Building content - Final data ready');
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
                              child: Loader(),
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
                List<PostEntity> allPosts = [];
                List<PostEntity> userPosts = [];

                // Get current posts from the state
                if (currentState is GlobalPostsDisplaySuccess) {
                  allPosts = currentState.posts;
                } else if (currentState is GlobalPostsAndCommentsSuccess) {
                  allPosts = currentState.posts;
                }

                // Filter posts for current user only
                userPosts =
                    allPosts.where((p) => p.userId == _currentUser.id).toList();

                // Sort posts by creation date (newest first)
                userPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                final postExists = userPosts.any((p) => p.id == post.id);

                if (!postExists || userPosts.isEmpty) {
                  // If post doesn't exist or no user posts, reload and try again
                  context.read<GlobalCommentsBloc>().add(GetAllGlobalPostsEvent(
                        userId: _currentUser.id,
                        screenType: 'profile',
                      ));

                  // Show a loading indicator or message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loading posts...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }

                PostEntity selectedPost;
                try {
                  selectedPost = userPosts.firstWhere((p) => p.id == post.id);
                } catch (e) {
                  // If not found in userPosts, use the original post from the grid
                  selectedPost = post;
                }

                print('📱 ProfileScreen: Navigating to profile posts');
                print('📱 User posts count: ${userPosts.length}');
                print('📱 Selected post: ${selectedPost.id}');

                Navigator.pushNamed(
                  context,
                  '/profile-posts',
                  arguments: {
                    'userId': _currentUser.id,
                    'userPosts': userPosts, // Pass only user's posts
                    'selectedPost': selectedPost,
                    'screenType': 'profile',
                  },
                ).then((result) {
                  if (result == true) {
                    print(
                        '📱 ProfileScreen: Returned from profile posts, reloading');
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
                      child: const Center(
                        child: Loader(),
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
