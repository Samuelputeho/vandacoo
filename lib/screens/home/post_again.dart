import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/screens/explorer/widgets/post_tile.dart';
import 'package:vandacoo/features/all_posts/presentation/bloc/post_bloc.dart';

class PostAgainScreen extends StatelessWidget {
  final String category;

  const PostAgainScreen({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(category),
        backgroundColor: Colors.orange,
      ),
      body: BlocBuilder<PostBloc, PostState>(
        builder: (context, state) {
          if (state is PostLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PostFailure) {
            return Center(child: Text(state.error));
          }

          if (state is PostDisplaySuccess) {
            final filteredPosts = state.posts
                .where((post) => 
                    post.category.toLowerCase() == category.toLowerCase())
                .toList();

            if (filteredPosts.isEmpty) {
              return const Center(
                child: Text(
                  'No posts yet in this category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            }

            return ListView.builder(
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final post = filteredPosts[index];
                return PostTile(
                  proPic: 'assets/math1.jpg',
                  name: post.posterName ?? 'Anonymous',
                  postPic: post.image,
                  description: post.caption,
                  id: post.id, posterId: '',
                );
              },
            );
          }

          return const Center(child: Text('No posts available'));
        },
      ),
    );
  }
}
