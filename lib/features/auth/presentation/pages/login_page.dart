import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/core/utils/show_snackbar.dart';
import 'package:vandacoo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vandacoo/features/auth/presentation/pages/register_page.dart';
import 'package:vandacoo/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:vandacoo/features/auth/presentation/widgets/auth_field.dart';
import 'package:vandacoo/core/common/pages/bottom_navigation_bar_screen.dart';
import 'package:vandacoo/features/settings/presentation/pages/policies_page.dart';

import '../../../../core/constants/colors.dart';
// Import the AuthField widget

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  late final TapGestureRecognizer termsRecognizer;
  late final TapGestureRecognizer privacyRecognizer;

  @override
  void initState() {
    super.initState();
    termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Policies()),
        );
      };
    privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Policies()),
        );
      };
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    termsRecognizer.dispose();
    privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthFailure) {
              showSnackBar(context, state.message);
            } else if (state is AuthSuccess) {
              // Handle successful login (e.g., navigate to another screen)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BottomNavigationBarScreen(
                    user: state.user,
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Loader();
            }

            return SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Welcome Back!',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    AuthField(
                      controller: emailController,
                      hintText: 'Email',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Email is missing!";
                        } else if (!RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$")
                            .hasMatch(value)) {
                          return "Please enter a valid email address!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthField(
                      controller: passwordController,
                      hintText: 'Password',
                      isObscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Password is missing!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Navigate to reset password screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          context.read<AuthBloc>().add(
                                AuthLogin(
                                  email: emailController.text.trim(),
                                  password: passwordController.text.trim(),
                                ),
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primaryColor, // Background color
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                      child: const Text('Login',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        children: [
                          const TextSpan(
                            text: "By continuing, you agree to Vandacoo's ",
                          ),
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: termsRecognizer,
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: privacyRecognizer,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Don\'t have an account?'),
                        TextButton(
                          onPressed: () {
                            // Navigate to the registration screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const RegistrationScreen()),
                            );
                          },
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
