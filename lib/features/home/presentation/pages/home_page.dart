import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/common/entities/user_entity.dart';
import '../../../../core/constants/colors.dart';
import 'feed_screen.dart';
import 'post_again.dart';
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

class _HomePageState extends State<HomePage> {
  // Define the list of items
  final List<Item> items = [
    Item('Education', 'assets/education1.jpg'),
    Item('Sports', 'assets/sports1.jpg'),
    Item('Health', 'assets/health1.jpg'),
    Item('Food and Travel', 'assets/travels.jpeg'),
    Item('Technology', 'assets/tech.jpg'),
    Item('Finance', 'assets/finance.jpeg'),
    Item('Entreprenurship', 'assets/entre.jpeg'),
    Item('Kids', 'assets/kids.jpg'),
    Item('Entertainment', 'assets/math1.jpg'),
    Item('Feed', 'assets/Feeds.jpg'),
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted && !widget.user.hasSeenIntroVideo) {
        PopUpVideo.show(
            context, 'https://www.youtube.com/watch?v=mWXjbjloUZY&t=135s');
        // Update user's hasSeenIntroVideo status using the bloc
        context
            .read<AuthBloc>()
            .add(AuthUpdateHasSeenVideo(userId: widget.user.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: SizedBox(
          height: MediaQuery.of(context).size.height * 0.06,
          width: MediaQuery.of(context).size.height * 0.06,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Image.asset("assets/vanlog.png", fit: BoxFit.cover),
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
                      if (items[index].name == 'Feed') {
                        // Navigate to FeedsScreen if the category is "Feed"
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const FeedScreen(), // Ensure you have FeedsScreen defined
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
