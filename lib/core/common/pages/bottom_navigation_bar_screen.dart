import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/features/messages/presentation/bloc/messages_bloc/message_bloc.dart';
import 'dart:async';

import '../../constants/colors.dart';
import '../../../features/home/presentation/pages/home_page.dart';
import '../../../features/explore_page/presentation/pages/explorer_screen.dart';
import '../../../features/profile/presentation/pages/profile_screen.dart';
import '../../../features/upload_media_page/presentation/pages/upload_screen.dart';
import '../../../features/messages/presentation/pages/messages_list_page.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  final UserEntity user;
  final int initialIndex;
  const BottomNavigationBarScreen({
    super.key,
    required this.user,
    this.initialIndex = 0,
  });

  @override
  State<BottomNavigationBarScreen> createState() =>
      _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  late final List<Widget> screens;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    screens = [
      HomePage(user: widget.user),
      ExplorerScreen(user: widget.user),
      const UploadScreen(),
      MessagesListPage(currentUserId: widget.user.id),
      ProfileScreen(user: widget.user),
    ];

    // Check for unread messages when app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageBloc>().add(
            FetchAllMessagesEvent(userId: widget.user.id),
          );
    });

    // Start background polling for new messages
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        context.read<MessageBloc>().add(
              FetchAllMessagesEvent(userId: widget.user.id),
            );
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BlocListener<MessageBloc, MessageState>(
        listener: (context, state) {
          if (state is UnreadMessagesLoaded) {
            setState(() {
              _unreadCount = state.unreadCount;
            });
          }
        },
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) async {
            setState(() => _currentIndex = index);
            // If navigating back to messages tab, refresh unread count
            if (index == 3) {
              context.read<MessageBloc>().add(
                    FetchAllMessagesEvent(userId: widget.user.id),
                  );
            }
          },
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: Colors.grey,
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home), label: 'Home'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.explore), label: 'Explore'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.upload), label: 'Upload'),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.message),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: _unreadCount > 0
                            ? Text(
                                _unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
              label: 'Messages',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
