import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/common/entities/user_entity.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/app_consts.dart';
import 'feed_screen.dart';
import 'home_post_tile.dart';
import '../../../../core/utils/pop_up_video.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';

class HomePage extends StatefulWidget {
  final UserEntity user;
  const HomePage({
    super.key,
    required this.user,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  // Convert the constant items to our Item class
  late final List<Item> items;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize items from AppConstants
    items = AppConstants.homePageItems
        .map((item) => Item(item['name']!, item['image']!))
        .toList();

    Future.delayed(Duration.zero, () {
      if (mounted && !widget.user.hasSeenIntroVideo) {
        PopUpVideo.show(context,
            'https://rzueqfqjstcbyzkhxxbh.supabase.co/storage/v1/object/public/welcome//WhatsApp%20Video%202025-05-08%20at%2007.36.16_e64c2532.mp4');
        // Update user's hasSeenIntroVideo status using the bloc
        context
            .read<AuthBloc>()
            .add(AuthUpdateHasSeenVideo(userId: widget.user.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: SizedBox(
          height: MediaQuery.of(context).size.height * 0.1,
          width: MediaQuery.of(context).size.height * 0.1,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Image.asset("assets/VandaLoo.png", fit: BoxFit.cover),
          ),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          const Center(
            child: Text(
              "VANDACOO",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: Divider(
              color: AppColors.primaryColor,
            ),
          ),
          const Text("Categories",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: Divider(
              color: AppColors.primaryColor,
            ),
          ),
          // Add the GridView
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 9 / 13.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      if (items[index].name == 'Advertisements') {
                        // Navigate to FeedsScreen if the category is "Feed"
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedScreen(
                              user: widget.user,
                            ),
                            settings: const RouteSettings(name: '/feed'),
                          ),
                        );
                      } else {
                        // Navigate to PostAgainScreen for other categories
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostAgainScreen(
                              category:
                                  items[index].name, // Pass the category name
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Image container with rounded top corners
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            height: MediaQuery.of(context).size.width * 0.6,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: Image.asset(
                                items[index].image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Title container with rounded bottom corners
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              items[index].name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Define a class for the items
class Item {
  final String name;
  final String image;

  Item(this.name, this.image);
}
