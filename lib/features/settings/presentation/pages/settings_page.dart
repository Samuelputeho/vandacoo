import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vandacoo/features/auth/presentation/pages/login_page.dart';
import 'package:vandacoo/core/theme/bloc/theme_bloc.dart';
import 'package:vandacoo/core/theme/bloc/theme_state.dart';
import 'package:vandacoo/features/settings/presentation/pages/policies_page.dart';
import 'package:vandacoo/features/settings/presentation/pages/support_page.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/utils/show_snackbar.dart';
import '../../../../core/utils/shared_preferences_with_cache.dart';
import '../bloc/notification_settings/notification_settings_bloc.dart';
import '../bloc/notification_settings/notification_settings_event.dart';
import '../bloc/notification_settings/notification_settings_state.dart';

class SettingsPage extends StatefulWidget {
  final String userId;

  const SettingsPage({
    super.key,
    required this.userId,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  NotificationSettingsBloc? _notificationBloc;

  @override
  void initState() {
    super.initState();
    _setupBloc();
  }

  Future<void> _setupBloc() async {
    final prefs = await SharedPreferencesWithCache.create();
    _notificationBloc = NotificationSettingsBloc(prefs)
      ..add(const NotificationSettingsLoadRequested());
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _notificationBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_notificationBloc == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider.value(
        value: _notificationBloc!,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Settings',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primaryColor,
          ),
          body: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthInitial) {
                // Navigate to login screen when logout is successful
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false, // Remove all previous routes
                );
              }
              if (state is AuthFailure) {
                //show toast message with error
                showSnackBar(context, state.message);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 10,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Card(
                    child: Column(
                      children: [
                        BlocConsumer<NotificationSettingsBloc,
                            NotificationSettingsState>(
                          listener: (context, notifState) {
                            if (notifState.message != null &&
                                notifState.message!.isNotEmpty) {
                              showSnackBar(context, notifState.message!);
                            }
                          },
                          builder: (context, notifState) {
                            return SwitchListTile(
                              title: const Text('Push Notifications'),
                              subtitle: const Text('Enable push notifications'),
                              value: notifState.pushEnabled,
                              onChanged: (bool value) => context
                                  .read<NotificationSettingsBloc>()
                                  .add(NotificationSettingsToggleRequested(
                                      enable: value)),
                              secondary: const Icon(Icons.notifications),
                            );
                          },
                        ),
                        const Divider(),
                        BlocBuilder<ThemeBloc, ThemeState>(
                          builder: (context, state) {
                            final isDarkMode =
                                state.themeData.brightness == Brightness.dark;
                            return SwitchListTile(
                              title: const Text('Dark Mode'),
                              subtitle: const Text('Enable dark theme'),
                              value: isDarkMode,
                              onChanged: (bool value) {
                                context.read<ThemeBloc>().add(
                                      value
                                          ? ThemeEvent.toggleDark
                                          : ThemeEvent.toggleLight,
                                    );
                              },
                              secondary: const Icon(Icons.dark_mode),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: const Text('Language'),
                          subtitle: const Text('English'),
                          onTap: () {},
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.bookmark),
                          title: const Text('Bookmarks'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/bookmarks',
                              arguments: {'userId': widget.userId},
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.security),
                          title: const Text('Policies'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Policies(),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Help & Support'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Support(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Spacer(), // Push the logout button to the bottom
                  ElevatedButton(
                    onPressed: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          content:
                              const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<AuthBloc>().add(AuthLogout());
                                Navigator.pop(context); // Close dialog
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
