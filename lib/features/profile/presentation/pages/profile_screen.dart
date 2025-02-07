import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vandacoo/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:vandacoo/core/constants/app_consts.dart';

import '../../../../core/common/entities/user_entity.dart';
import '../../../../core/constants/colors.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class ProfileScreen extends StatefulWidget {
  final UserEntity user;
  const ProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
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
                  builder: (context) => const SettingsPage(),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(isDarkMode),
            const SizedBox(height: 24),
            _buildStats(isDarkMode),
            const SizedBox(height: 24),
            _buildTabSection(isDarkMode),
            const SizedBox(height: 16),
            _buildPhotoGrid(isDarkMode),
          ],
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
                  child: widget.user.propic.isNotEmpty
                      ? Image.network(
                          widget.user.propic,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
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
              widget.user.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                widget.user.bio,
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
                      currentName: widget.user.name,
                      currentBio: widget.user.bio,
                      currentEmail: widget.user.email,
                      userId: widget.user.id,
                    ),
                  ),
                ).then((_) {
                  context.read<AuthBloc>().add(AuthIsUserLoggedIn());
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

  Widget _buildStats(bool isDarkMode) {
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
          _buildStatItem("120", "Followers", isDarkMode),
          Container(
            height: 40,
            width: 1,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          ),
          _buildStatItem("120", "Following", isDarkMode),
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
            child: _buildTabButton("Photos", true, isDarkMode),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTabButton("Feeds", false, isDarkMode),
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

  Widget _buildPhotoGrid(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: AppConstants.profileImages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImagePage(
                    images: AppConstants.profileImages,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  AppConstants.profileImages[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
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
