import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vandacoo/screens/profile/edit_profile_screen.dart';
import 'package:vandacoo/core/constants/app_consts.dart';

import '../../core/constants/colors.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthIsUserLoggedIn());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = switch (state) {
          AuthSuccess() => state.user,
          _ => null,
        };

        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: AppColors.primaryColor,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () {
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      ).then((_) {
                        context.read<AuthBloc>().add(AuthIsUserLoggedIn());
                      });
                    }
                  },
                  child: const Icon(Icons.settings),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        if (user != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                currentName: user.name,
                                currentBio: user.bio,
                                currentEmail: user.email,
                                userId: user.id,
                              ),
                            ),
                          ).then((_) {
                            context.read<AuthBloc>().add(AuthIsUserLoggedIn());
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.all(8),
                      ),
                      child: const Text("Edit Profile"),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Divider(),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.05,
                          width: MediaQuery.of(context).size.height * 0.05,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(child: Text("120")),
                        ),
                        const Text("Followers"),
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.05,
                          width: MediaQuery.of(context).size.height * 0.05,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(child: Text("120")),
                        ),
                        const Text("Following"),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.12,
                      width: MediaQuery.of(context).size.height * 0.12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: ClipOval(
                          child: user?.propic.isNotEmpty == true
                              ? Image.network(
                                  user!.propic,
                                  fit: BoxFit.cover,
                                  width: double
                                      .infinity, // Added to ensure full width
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                    "assets/user1.jpeg",
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Image.asset(
                                  "assets/user1.jpeg",
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(user?.name ?? 'Loading...'),
                    const SizedBox(height: 5),
                    Text(user?.bio ?? 'Loading...'),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: AppColors.primaryColor,
                        ),
                        child: const Text("Photos"),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: AppColors.primaryColor,
                        ),
                        child: const Text("Feeds"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
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
                                  initialIndex: index),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child:
                                Image.asset(AppConstants.profileImages[index]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImagePage(
      {super.key, required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        itemCount: images.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          return Center(
            child: Image.asset(images[index]),
          );
        },
      ),
    );
  }
}
