import 'package:flutter/material.dart';

class GlobalCommentsEditPostWidget extends StatelessWidget {
  final bool isCurrentUser;

  const GlobalCommentsEditPostWidget({
    super.key,
    required this.isCurrentUser,
  });

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
          if (isCurrentUser) ...[
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
                print('GlobalCommentsEditPostWidget: Delete option tapped');
                Navigator.pop(context, 'delete');
                print(
                    'GlobalCommentsEditPostWidget: Popped navigation with "delete" value');
              },
            ),
          ] else
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.orange),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context, 'report');
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
