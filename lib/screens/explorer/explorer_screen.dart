import 'package:flutter/material.dart';
import 'package:vandacoo/screens/explorer/widgets/post_tile.dart';
import 'package:vandacoo/screens/explorer/widgets/status_circle.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/features/all_posts/presentation/bloc/post_bloc.dart';

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

  // Define the list of StatusCircle items
  final List<StatusCircleItem> statusCircleItems = [
    StatusCircleItem('assets/Feeds.jpg', 'Namibia'),
    StatusCircleItem('assets/math1.jpg', 'Khomas'),
    StatusCircleItem('assets/math1.jpg', 'Oshana'),
    StatusCircleItem('assets/math1.jpg', 'Kunene'),
    StatusCircleItem('assets/math1.jpg', 'Zambezi'),
    StatusCircleItem('assets/math1.jpg', 'Karas'),
    StatusCircleItem('assets/math1.jpg', 'Ohangwena'),
    StatusCircleItem('assets/math1.jpg', 'Omusati'),
    StatusCircleItem('assets/math1.jpg', 'Erongo'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Explore'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Create a horizontally scrolling ListView
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: statusCircleItems.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Navigate to the status display screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StatusDisplayScreen(
                          images: statusCircleItems
                              .map((item) => item.image)
                              .toList(),
                        ),
                      ),
                    );
                  },
                  child: StatusCircle(
                    image: statusCircleItems[index].image,
                    region: statusCircleItems[index].region,
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
                        postPic: post.image,
                        description: post.caption,
                        id: post.id,
                        posterId: post.posterId,
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

// Define a class for the StatusCircle items
class StatusCircleItem {
  final String image;
  final String region;

  StatusCircleItem(this.image, this.region);
}
