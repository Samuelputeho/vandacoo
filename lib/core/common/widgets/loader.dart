import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class Loader extends StatelessWidget {
  final Color? color;
  const Loader({super.key, this.color = AppColors.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: color,
      ),
    );
  }
}
