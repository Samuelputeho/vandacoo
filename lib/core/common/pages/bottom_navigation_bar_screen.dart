import 'package:flutter/material.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';

import '../../constants/colors.dart';
import '../../../features/home/presentation/pages/home_page.dart';
import '../../../features/all_posts/presentation/pages/explorer_screen.dart';
import '../../../features/messages/presentation/pages/messages_screen.dart';
import '../../../features/profile/presentation/pages/profile_screen.dart';
import '../../../features/upload/presentation/pages/upload_screen.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  final UserEntity user;
  const BottomNavigationBarScreen({
    super.key,
    required this.user,
  });

  @override
  State<BottomNavigationBarScreen> createState() =>
      _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  int _currentIndex = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      HomePage(user: widget.user),
      const ExplorerScreen(),
      const UploadScreen(),
      MessagesScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
