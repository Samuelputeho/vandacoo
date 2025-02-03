import 'package:flutter/material.dart';

class EditPostWidget extends StatelessWidget {
  const EditPostWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Grey horizontal line
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Options list
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context, 'share');
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context, 'edit');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context, 'delete');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
