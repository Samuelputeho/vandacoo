import 'package:flutter/material.dart';
import 'package:vandacoo/features/all_posts/presentation/widgets/post_tile.dart';
import 'package:vandacoo/features/all_posts/presentation/widgets/status_circle.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/features/all_posts/presentation/bloc/post_bloc.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/app_consts.dart';
import 'display_screen.dart';

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger post fetching when screen initializes
    context.read<PostBloc>().add(GetAllPostsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Explore'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Create a horizontally scrolling ListView
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.statusCircleItems.length,
              itemBuilder: (context, index) {
                final item = AppConstants.statusCircleItems[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to the status display screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StatusDisplayScreen(
                          images: AppConstants.statusCircleItems
                              .map((item) => item['image']!)
                              .toList(),
                        ),
                      ),
                    );
                  },
                  child: StatusCircle(
                    image: item['image']!,
                    region: item['region']!,
                  ),
                );
              },
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          // Replace the existing Expanded ListView with BlocBuilder
          Expanded(
            child: BlocBuilder<PostBloc, PostState>(
              builder: (context, state) {
                if (state is PostLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PostFailure) {
                  return Center(child: Text(state.error));
                }

                if (state is PostDisplaySuccess) {
                  return ListView.builder(
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
                      );
                    },
                  );
                }

                return const Center(child: Text('No posts available'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
