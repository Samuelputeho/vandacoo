import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class Loader extends StatelessWidget {
  final Color? color;
  final double? size;
  const Loader(
      {super.key, this.color = AppColors.primaryColor, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: color,
      ),
    );
  }
}
