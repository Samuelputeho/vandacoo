import 'package:flutter/material.dart';

class AuthField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool isObscureText;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.hintText,
    required this.controller,
    this.isObscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
        // Add optional prefix icon
        prefixIcon: hintText == "Email" ? const Icon(Icons.email) : const Icon(Icons.lock),
      ),
      obscureText: isObscureText,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return "$hintText is missing!";
            }
            return null;
          },
    );
  }
}
