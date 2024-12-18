import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/core/utils/show_snackbar.dart';
import 'package:vandacoo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vandacoo/features/auth/presentation/widgets/auth_field.dart';
// Import the AuthField widget

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? _accountType; // Variable to hold the selected account type

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
          if (state is AuthFailure) {
            showSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Loader();
          }
            return Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Create an Account',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Name Field
                  AuthField(
                    controller: nameController,
                    hintText: 'Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Name is missing!";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Email Field
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

                  // Password Field
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

                  const SizedBox(height: 20),

                  // Account Type Selection (Personal or Business)
                  // Container(
                  //   padding: const EdgeInsets.all(16.0),
                  //   decoration: BoxDecoration(
                  //     border: Border.all(color: Colors.grey),
                  //     borderRadius: BorderRadius.circular(8.0),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       const Text('Account Type',
                  //           style: TextStyle(fontSize: 16)),
                  //       const SizedBox(height: 10),
                  //       ListTile(
                  //         title: Container(
                  //           padding: const EdgeInsets.all(8.0),
                  //           decoration: BoxDecoration(
                  //             border: Border.all(color: Colors.grey),
                  //             borderRadius: BorderRadius.circular(4.0),
                  //           ),
                  //           child: const Text('Personal'),
                  //         ),
                  //         leading: Radio<String>(
                  //           value: 'personal',
                  //           groupValue: _accountType,
                  //           onChanged: (value) {
                  //             setState(() {
                  //               _accountType =
                  //                   value; // Update the selected account type
                  //             });
                  //           },
                  //         ),
                  //       ),
                  //       ListTile(
                  //         title: Container(
                  //           padding: const EdgeInsets.all(8.0),
                  //           decoration: BoxDecoration(
                  //             border: Border.all(color: Colors.grey),
                  //             borderRadius: BorderRadius.circular(4.0),
                  //           ),
                  //           child: const Text('Business'),
                  //         ),
                  //         leading: Radio<String>(
                  //           value: 'business',
                  //           groupValue: _accountType,
                  //           onChanged: (value) {
                  //             setState(() {
                  //               _accountType =
                  //                   value; // Update the selected account type
                  //             });
                  //           },
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  const SizedBox(height: 20),

                  // Register Button
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        context.read<AuthBloc>().add(
                              AuthSignUp(
                                name: nameController.text.trim(),
                                password: passwordController.text.trim(),
                                email: emailController.text.trim(),
                              ),
                            );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, // Background color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                    ),
                    child: const Text('Register'),
                  ),

                  const SizedBox(height: 20),

                  // Navigate to Login Screen if already have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Go back to login screen
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
