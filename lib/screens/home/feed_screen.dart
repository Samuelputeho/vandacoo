import 'package:flutter/material.dart';

import 'add_card_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text("Advertisements"),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end, // Align to the right
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AddCardScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.all(
                      8), // Add some padding to make it look like a button
                  decoration: BoxDecoration(color: Colors.orange),
                  child: Center(child: Text("Post")),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
