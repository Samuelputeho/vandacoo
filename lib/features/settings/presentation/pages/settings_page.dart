import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vandacoo/features/auth/presentation/pages/login_page.dart';
import 'package:vandacoo/core/theme/bloc/theme_bloc.dart';
import 'package:vandacoo/core/theme/bloc/theme_state.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/utils/show_snackbar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            print('running');
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
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Enable push notifications'),
                      value: true,
                      onChanged: (bool value) {},
                      secondary: const Icon(Icons.notifications),
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
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {},
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Privacy Settings'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {},
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {},
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
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
