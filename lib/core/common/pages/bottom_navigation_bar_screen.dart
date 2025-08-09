import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/features/messages/presentation/bloc/messages_bloc/message_bloc.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:permission_handler/permission_handler.dart';

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

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _unreadCount = 0;
  late final List<Widget> screens;
  MessageBloc? _messageBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;

    // Initialize screens with callback for ExplorerScreen
    screens = [
      HomePage(user: widget.user),
      ExplorerScreen(
        user: widget.user,
        onNavigateToProfile: () => _navigateToProfileTab(),
      ),
      const UploadScreen(),
      MessagesListPage(currentUserId: widget.user.id),
      ProfileScreen(user: widget.user),
    ];

    // Initialize with current messages and start realtime subscriptions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureNotificationPermission();
      _refreshUnreadCount();

      // Cache MessageBloc reference for safe disposal
      _messageBloc = context.read<MessageBloc>();

      // Start realtime subscriptions for instant updates
      _messageBloc!.add(
        StartRealtimeSubscriptionEvent(userId: widget.user.id),
      );
    });
  }

  Future<void> _ensureNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _updateAppIconBadge() async {
    final isSupported = await FlutterAppBadger.isAppBadgeSupported();
    if (!mounted || !isSupported) return;
    if (_unreadCount > 0) {
      FlutterAppBadger.updateBadgeCount(_unreadCount);
    } else {
      FlutterAppBadger.removeBadge();
    }
  }

  void _navigateToProfileTab() {
    setState(() {
      _currentIndex = 4; // Profile tab index
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh unread count when app comes back into focus
      _refreshUnreadCount();
    }
  }

  void _refreshUnreadCount() {
    _messageBloc?.add(
      FetchAllMessagesEvent(userId: widget.user.id),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop realtime subscriptions when screen is disposed
    _messageBloc?.add(StopRealtimeSubscriptionEvent());
    // Clear app icon badge when leaving the app (optional)
    FlutterAppBadger.removeBadge();
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
            _updateAppIconBadge();
          }
        },
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) async {
            setState(() => _currentIndex = index);
            // If navigating to messages tab, refresh unread count
            if (index == 3) {
              _refreshUnreadCount();
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
