import 'package:flutter/material.dart';

class StatusCircle extends StatelessWidget {
  final String image;
  final String region;
  const StatusCircle({super.key, required this.image, required this.region});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.06,
            width: MediaQuery.of(context).size.height * 0.06,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(image, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 0),
          Text(
            region,
            style: TextStyle(fontSize: 12),
          )
        ],
      ),
    );
  }
}
